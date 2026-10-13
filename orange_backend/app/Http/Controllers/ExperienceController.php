<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
class ExperienceController extends Controller {
 public function index(Request $request) {
  $v=$request->validate(['category'=>'nullable|in:event,party,live']);
  $q=DB::table('experiences')->where('published',true)->where('ends_at','>',now());
  if(isset($v['category']))$q->where('category',$v['category']);
  $rows=$q->orderBy('starts_at')->limit(100)->get();
  $currencies=DB::table('currencies')->where('enabled',true)->pluck('decimals','code');
  $rows=$rows->filter(fn($e)=>$currencies->has($e->currency_code))->values();
  $counts=DB::table('experience_tickets')->whereIn('experience_id',$rows->pluck('id'))->where('status','confirmed')->selectRaw('experience_id, count(*) as total')->groupBy('experience_id')->pluck('total','experience_id');
  foreach($rows as $e){$e->starts_at=\Carbon\Carbon::parse($e->starts_at,'UTC')->toIso8601String();$e->ends_at=\Carbon\Carbon::parse($e->ends_at,'UTC')->toIso8601String();$e->decimals=$currencies[$e->currency_code];$e->remaining=max(0,$e->capacity-($counts[$e->id]??0));$e->checkout_available=!$e->is_demo && $e->amount_minor>0;}
  return response()->json(['status'=>true,'data'=>$rows]);
 }
 public function reserve(Request $request) {
  $me=auth('app_users')->user();if(!$me)return response()->json(['status'=>false],401);
  $v=$request->validate(['experience_id'=>'required|integer|min:1']);
  return DB::transaction(function()use($v,$me){
   $e=DB::table('experiences')->where('id',$v['experience_id'])->lockForUpdate()->first();
   if(!$e || !$e->published || $e->ends_at<=now() || !DB::table('currencies')->where('code',$e->currency_code)->where('enabled',true)->exists())return response()->json(['status'=>false,'message'=>'This experience is unavailable.'],404);
   if($e->is_demo)return response()->json(['status'=>false,'message'=>'This is a preview. Tickets are not issued for demo events.'],409);
   $existing=DB::table('experience_tickets')->where('experience_id',$e->id)->where('user_id',$me->id)->first();
   if($existing)return response()->json(['status'=>true,'data'=>$existing]);
   if($e->amount_minor>0)return response()->json(['status'=>false,'message'=>'Paid tickets are unavailable until checkout is configured.'],409);
   if(DB::table('experience_tickets')->where('experience_id',$e->id)->where('status','confirmed')->count()>=$e->capacity)return response()->json(['status'=>false,'message'=>'This experience is sold out.'],409);
   $id=DB::table('experience_tickets')->insertGetId(['experience_id'=>$e->id,'user_id'=>$me->id,'ticket_code'=>(string)Str::uuid(),'status'=>'confirmed','created_at'=>now(),'updated_at'=>now()]);
   return response()->json(['status'=>true,'data'=>DB::table('experience_tickets')->find($id)]);
  });
 }
 public function tickets(){ $me=auth('app_users')->user();if(!$me)return response()->json(['status'=>false],401);return response()->json(['status'=>true,'data'=>DB::table('experience_tickets')->join('experiences','experiences.id','=','experience_tickets.experience_id')->where('user_id',$me->id)->select('experience_tickets.*','experiences.title','experiences.venue','experiences.starts_at')->orderByDesc('experience_tickets.id')->limit(100)->get()]); }
 public function admin(){return view('experiences',['experiences'=>DB::table('experiences')->orderByDesc('id')->get(),'currencies'=>DB::table('currencies')->where('enabled',true)->get()]);}
 public function save(Request $request){
  $v=$request->validate(['id'=>'nullable|integer|exists:experiences,id','title'=>'required|string|max:120','category'=>'required|in:event,party,live','description'=>'required|string|max:5000','venue'=>'required|string|max:160','starts_at'=>'required|date','ends_at'=>'required|date|after:starts_at','currency_code'=>'required|exists:currencies,code','amount_minor'=>'required|integer|min:0|max:1000000000','capacity'=>'required|integer|min:1|max:100000','published'=>'required|boolean','is_demo'=>'required|boolean']);
  DB::transaction(function()use($v){$id=$v['id']??null;unset($v['id']);$v['updated_at']=now();$v['starts_at']=\Carbon\Carbon::parse($v['starts_at'])->utc();$v['ends_at']=\Carbon\Carbon::parse($v['ends_at'])->utc();
   if(!DB::table('currencies')->where('code',$v['currency_code'])->where('enabled',true)->exists())throw \Illuminate\Validation\ValidationException::withMessages(['currency_code'=>'Choose an enabled currency.']);
   if($id){DB::table('experiences')->where('id',$id)->lockForUpdate()->first();$count=DB::table('experience_tickets')->where('experience_id',$id)->count();if($count && ($v['capacity']<$count || $v['is_demo']))throw \Illuminate\Validation\ValidationException::withMessages(['capacity'=>'Preserve issued tickets and their capacity.']);DB::table('experiences')->where('id',$id)->update($v);}else{$v['created_at']=now();DB::table('experiences')->insert($v);}
  });return redirect()->route('experiences.admin')->with('success','Experience saved.');
 }
 public function earn(){
  $me=auth('app_users')->user();if(!$me)return response()->json(['status'=>false],401);
  return response()->json(['status'=>true,'data'=>['received_gifts'=>DB::table('gift_transactions')->where('receiver_id',$me->id)->count(),'received_coins'=>(int)DB::table('gift_transactions')->where('receiver_id',$me->id)->sum('coin_price'),'wallet_coins'=>(int)$me->wallet,'payout_available'=>(bool)DB::table('earning_policy')->where('id',1)->value('withdrawals_enabled') && !$me->qa_coin_mode,'verified'=>(int)$me->is_verified===2,'message'=>'Only funded gifts and settled content sales can earn cash at the admin-set rate. Open Earnings & withdrawals to apply and view released earnings.']]);
 }
}
