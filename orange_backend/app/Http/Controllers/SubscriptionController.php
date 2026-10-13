<?php
namespace App\Http\Controllers;
use App\Models\Subscription;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SubscriptionController extends Controller
{
    public function status(Request $request)
    {
        $me=auth('app_users')->user();
        $sub=Subscription::where('user_id',$me->id)->active()->latest('expires_at')->first();
        return response()->json(['status'=>true,'active'=>$sub !== null,'plan'=>$sub->plan ?? null,
            'expires_at'=>$sub && $sub->expires_at ? $sub->expires_at->toIso8601String() : null]);
    }

    public function revenuecatWebhook(Request $request)
    {
        $secret=config('ketua.revenuecat_webhook_secret');
        if (!$secret) return response()->json(['status'=>false,'message'=>'Webhook not configured.'],503);
        if (!hash_equals('Bearer '.$secret,(string)$request->header('Authorization'))) {
            return response()->json(['status'=>false,'message'=>'Unauthorized.'],401);
        }
        $v=\Illuminate\Support\Facades\Validator::make($request->all(),[
            'event'=>'required|array','event.id'=>'required|string|max:128',
            'event.app_user_id'=>'required|string|max:255','event.type'=>'required|string|max:80',
            'event.product_id'=>'required|string|max:150','event.event_timestamp_ms'=>'required|integer|min:1',
            'event.environment'=>'required|in:PRODUCTION,SANDBOX',
            'event.expiration_at_ms'=>'required|integer|min:1']);
        if ($v->fails()) return response()->json(['status'=>false,'message'=>'Invalid event.'],422);
        $event=$request->input('event');
        if ($event['environment']==='SANDBOX' && !(app()->environment('testing') && config('database.connections.mysql.database')==='ketua_test')) {
            return response()->json(['status'=>false,'message'=>'Sandbox event rejected outside testing.'],422);
        }
        $type=$event['type'];
        if (!in_array($type,['INITIAL_PURCHASE','RENEWAL','UNCANCELLATION','CANCELLATION','EXPIRATION'],true)) {
            return response()->json(['status'=>true,'message'=>'Event does not change access.']);
        }
        $plan=DB::table('membership_plans')->where('store_product_id',$event['product_id'])
            ->where('enabled',true)->whereIn('code',['gold','pro'])->first();
        if (!$plan) return response()->json(['status'=>false,'message'=>'Unrecognized product.'],422);
        $id=$event['app_user_id'];
        $user=ctype_digit($id) ? Users::find((int)$id) : Users::where('identity',$id)->first();
        if (!$user) return response()->json(['status'=>false,'message'=>'Unknown account.'],422);
        $eventMs=(int)$event['event_timestamp_ms'];
        if ($eventMs > (int)(microtime(true)*1000)+300000) return response()->json(['status'=>false,'message'=>'Invalid event time.'],422);
        $expires=\Illuminate\Support\Carbon::createFromTimestampMs((int)$event['expiration_at_ms']);
        // Hash exact provider payload: conflicting reuse of an event ID is rejected.
        $hash=hash('sha256',json_encode($event));
        $result=DB::transaction(function () use ($user,$plan,$event,$type,$eventMs,$expires,$hash) {
            Users::where('id',$user->id)->lockForUpdate()->first();
            $seen=DB::table('subscription_events')->where('event_id',$event['id'])->first();
            if ($seen) return ['code'=>hash_equals($seen->payload_hash,$hash) ? 200 : 409,
                'message'=>hash_equals($seen->payload_hash,$hash) ? 'Already processed.' : 'Conflicting event.'];
            // insertOrIgnore also protects event ID reuse across different user locks.
            $inserted=DB::table('subscription_events')->insertOrIgnore(['event_id'=>$event['id'],
                'payload_hash'=>$hash,'event_timestamp_ms'=>$eventMs,'created_at'=>now()]);
            if (!$inserted) return ['code'=>409,'message'=>'Event ID conflict.'];
            $sub=Subscription::where('user_id',$user->id)->where('provider','revenuecat')
                ->where('product_id',$event['product_id'])->orderByDesc('last_event_ms')->first();
            if ($sub && $eventMs <= (int)$sub->last_event_ms) return ['code'=>200,'message'=>'Older event ignored.'];
            if (!$sub) $sub=new Subscription(['user_id'=>$user->id,'provider'=>'revenuecat','product_id'=>$event['product_id'],'started_at'=>now()]);
            $sub->plan=$plan->code;
            $sub->status=$type === 'EXPIRATION' ? 'expired' : ($type === 'CANCELLATION' ? 'cancelled' : 'active');
            $sub->expires_at=$expires;
            $sub->provider_txn_id=$event['id'];
            $sub->last_event_ms=$eventMs;
            $sub->save();
            Subscription::where('user_id',$user->id)->where('provider','revenuecat')
                ->where('product_id',$event['product_id'])->where('id','!=',$sub->id)->update(['status'=>'expired']);
            return ['code'=>200,'message'=>'Processed.'];
        });
        return response()->json(['status'=>$result['code']===200,'message'=>$result['message']],$result['code']);
    }
}
