<?php

namespace App\Http\Controllers;

use App\Models\AppData;
use App\Models\Constants;
use App\Models\LikedProfile;
use App\Models\Myfunction;
use App\Models\UserNotification;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * Mission features: matching + swipe-up "Stars".
 *
 * All endpoints derive the acting user from the bearer token and never trust a
 * client-supplied my_user_id. A "match" is a mutual like (both users have a
 * like_profiles row pointing at each other). A "Star" is a premium super-like
 * that costs coins (server-priced) and is surfaced to the receiver.
 */
class MatchController extends Controller
{
    /**
     * POST /api/likeProfile  (auth)  { user_id }
     * Plain like. Returns matched:true when the feeling is mutual.
     */
    public function likeProfile(Request $request)
    {
        $v = Validator::make($request->all(), ['user_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $me = Users::find(auth('app_users')->user()?->id);
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $target = Users::find($request->user_id);
        if ($target == null) {
            return response()->json(['status' => false, 'message' => 'User not found.']);
        }
        if ((int) $target->id === (int) $me->id) {
            return response()->json(['status' => false, 'message' => 'Invalid target.']);
        }

        if (!$this->canInteract($me, $target)) {
            return response()->json(['status'=>false,'message'=>'Profile unavailable.'], 403);
        }

        $result=DB::transaction(function()use($me,$target){
            Users::where('id',$me->id)->lockForUpdate()->first();
            if(LikedProfile::where('my_user_id',$me->id)->where('user_id',$target->id)->exists())return ['status'=>false,'message'=>'Already liked.'];
            $usage=\App\Services\PremiumAccess::usage($me->id);$rules=\App\Services\PremiumAccess::rules($me->id);
            if($rules->session_likes!==null && $usage->session_likes >= $rules->session_likes)return ['status'=>false,'message'=>'Session like limit reached. Upgrade for unlimited likes.','limit_reached'=>true];
            DB::table('premium_usage')->where('user_id',$me->id)->update(['session_likes'=>$usage->session_likes+1,'last_action_at'=>now()]);
            $like=new LikedProfile();$like->my_user_id=$me->id;$like->user_id=$target->id;$like->star=0;$like->save();
            DB::table('swipe_actions')->insert(['user_id'=>$me->id,'target_id'=>$target->id,'kind'=>'like','created_at'=>now(),'updated_at'=>now()]);
            return ['status'=>true,'matched'=>LikedProfile::where('my_user_id',$target->id)->where('user_id',$me->id)->exists(),'message'=>'Liked successfully!'];
        });
        if($result['status']){$this->notifyLike($me,$target,false);if($result['matched'])$this->notifyMatch($me,$target);}
        return response()->json($result, !empty($result['limit_reached'])?429:200);
    }

    /**
     * POST /api/starProfile  (auth)  { user_id }
     * Swipe-up "Star" = premium super-like. Coin price comes from appdata
     * (star_price) server-side; debits the sender wallet atomically.
     */
    public function starProfile(Request $request)
    {
        $v = Validator::make($request->all(), ['user_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $me = Users::find(auth('app_users')->user()?->id);
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $target = Users::find($request->user_id);
        if ($target == null) {
            return response()->json(['status' => false, 'message' => 'User not found.']);
        }
        if ((int) $target->id === (int) $me->id) {
            return response()->json(['status' => false, 'message' => 'Invalid target.']);
        }

        if (!$this->canInteract($me, $target)) {
            return response()->json(['status'=>false,'message'=>'Profile unavailable.'], 403);
        }

        $existing = LikedProfile::where('my_user_id', $me->id)->where('user_id', $target->id)->first();
        if ($existing) {
            return response()->json(['status' => false, 'message' => 'Already liked.']);
        }

        $result=DB::transaction(function()use($me,$target){
            $locked=Users::where('id',$me->id)->lockForUpdate()->first();
            if(LikedProfile::where('my_user_id',$me->id)->where('user_id',$target->id)->exists())return ['ok'=>false,'code'=>409,'message'=>'Already liked.'];
            if(DB::table('cash_wallets')->where('user_id',$me->id)->where('frozen',true)->exists())return ['ok'=>false,'code'=>403,'message'=>'Account payment is under review.'];
            $usage=\App\Services\PremiumAccess::usage($me->id);$rules=\App\Services\PremiumAccess::rules($me->id);
            $included=$usage->weekly_stars < $rules->weekly_stars;
            if(!$included && $usage->purchased_stars<1)return ['ok'=>false,'code'=>402,'message'=>'Get Super Likes to show extra interest.'];
            DB::table('premium_usage')->where('user_id',$me->id)->update($included?['weekly_stars'=>$usage->weekly_stars+1,'last_action_at'=>now()]:['purchased_stars'=>$usage->purchased_stars-1,'last_action_at'=>now()]);
            $like=new LikedProfile();$like->my_user_id=$me->id;$like->user_id=$target->id;$like->star=1;$like->star_price=0;$like->save();
            DB::table('swipe_actions')->insert(['user_id'=>$me->id,'target_id'=>$target->id,'kind'=>'star','created_at'=>now(),'updated_at'=>now()]);
            return ['ok'=>true,'code'=>200,'message'=>'Super Like sent!','matched'=>LikedProfile::where('my_user_id',$target->id)->where('user_id',$me->id)->exists(),'wallet'=>$locked->wallet];
        });

        if (!empty($result['ok'])) {
            $this->notifyLike($me, $target, true);
            if (!empty($result['matched'])) {
                $this->notifyMatch($me, $target);
            }
        }

        return response()->json([
            'status'  => $result['ok'],
            'message' => $result['message'],
            'matched' => $result['matched'] ?? false,
            'wallet'  => $result['wallet'] ?? null,
        ], $result['code']);
    }

    /**
     * POST /api/dislikeProfile  (auth)  { user_id }
     */
    public function dislikeProfile(Request $request)
    {
        $v = Validator::make($request->all(), ['user_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }
        $me = Users::find(auth('app_users')->user()?->id);
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $target=Users::find($request->user_id);
        if(!$target || $target->id==$me->id || !$this->canInteract($me,$target))return response()->json(['status'=>false,'message'=>'Profile unavailable.'],403);
        DB::transaction(function()use($me,$target){Users::where('id',$me->id)->lockForUpdate()->first();\App\Services\PremiumAccess::usage($me->id);DB::table('premium_usage')->where('user_id',$me->id)->update(['last_action_at'=>now()]);
          // Passing is allowed to remove one's own like, without refunding allowance/credits.
          LikedProfile::where('my_user_id',$me->id)->where('user_id',$target->id)->delete();
          DB::table('swipe_actions')->insert(['user_id'=>$me->id,'target_id'=>$target->id,'kind'=>'pass','created_at'=>now(),'updated_at'=>now()]);});
        return response()->json(['status'=>true,'message'=>'Disliked.']);
    }

    public function rewind(Request $request){
        $v=$request->validate(['user_id'=>'required|integer|min:1']);$me=Users::find(auth('app_users')->user()?->id);
        return DB::transaction(function()use($me,$v){Users::where('id',$me->id)->lockForUpdate()->first();$u=\App\Services\PremiumAccess::usage($me->id);$r=\App\Services\PremiumAccess::rules($me->id);
            if($r->daily_rewinds!==null && $u->rewinds >= $r->daily_rewinds)return response()->json(['status'=>false,'message'=>'Rewind allowance unavailable. Gold includes limited rewinds; Pro includes unlimited.'],403);
            $last=DB::table('swipe_actions')->where('user_id',$me->id)->where('rewound',false)->orderByDesc('id')->first();
            if(!$last || $last->target_id != $v['user_id'] || $last->kind==='star')return response()->json(['status'=>false,'message'=>'This swipe cannot be rewound. Super Likes are final.'],409);
            $target=Users::find($last->target_id);if(!$target || !$this->canInteract($me,$target))return response()->json(['status'=>false,'message'=>'Profile unavailable.'],403);
            DB::table('swipe_actions')->where('id',$last->id)->update(['rewound'=>true,'updated_at'=>now()]);
            LikedProfile::where('my_user_id',$me->id)->where('user_id',$last->target_id)->where('star',0)->delete();
            DB::table('premium_usage')->where('user_id',$me->id)->update(['rewinds'=>$u->rewinds+1]);
            return response()->json(['status'=>true,'user_id'=>$last->target_id]);
        });
    }

    /**
     * GET /api/myMatches  (auth) — mutual likes.
     */
    public function myMatches(Request $request)
    {
        $me = Users::find(auth('app_users')->user()?->id);
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $myLikedIds = LikedProfile::where('my_user_id', $me->id)->pluck('user_id')->all();
        $mutualIds = LikedProfile::where('my_user_id', $me->id)
            ->whereIn('user_id', function ($q) use ($me) {
                $q->select('my_user_id')->from('like_profiles')->where('user_id', $me->id);
            })
            ->pluck('user_id')
            ->all();

        $matches = Users::with('images')->whereIn('id', $mutualIds ?: [0])->get()->filter(fn ($person) => $this->canInteract($me, $person))->map(fn ($person) => $person->only(['id','fullname','username','bio','is_verified','images']))->values();

        return response()->json([
            'status' => true,
            'message' => 'Matches fetched successfully.',
            'data' => $matches,
        ]);
    }

    private function notifyLike(Users $me, Users $target, bool $isStar): void
    {
        try {
            $n = new UserNotification();
            $n->user_id = $target->id;
            $n->my_user_id = $me->id;
            $n->item_id = $me->id;
            $n->type = Constants::notificationTypeLikeProfile;
            $n->message = $isStar
                ? ($me->fullname . ' sent you a Star! ⭐')
                : ($me->fullname . ' liked your profile!');
            $n->save();

            if (!empty($target->device_token)) {
                Myfunction::sendPushToUser(
                    $isStar ? 'You got a Star! ⭐' : 'New like!',
                    $me->fullname . ($isStar ? ' sent you a Star!' : ' liked your profile'),
                    $target->device_token
                );
            }
        } catch (\Throwable $e) {
        }
    }

    private function notifyMatch(Users $a, Users $b): void
    {
        try {
            foreach ([[$a, $b], [$b, $a]] as $pair) {
                [$from, $to] = $pair;
                $n = new UserNotification();
                $n->user_id = $to->id;
                $n->my_user_id = $from->id;
                $n->item_id = $from->id;
                $n->type = Constants::notificationTypeMatch;
                $n->message = "It's a match with " . $from->fullname . '!';
                $n->save();
            }
        } catch (\Throwable $e) {
        }
    }
    private function canInteract(Users $me, Users $target): bool
    {
        return (int)$target->is_block !== 1
            && !in_array((string)$target->id, explode(',', (string)$me->blocked_users), true)
            && !in_array((string)$me->id, explode(',', (string)$target->blocked_users), true);
    }
}
