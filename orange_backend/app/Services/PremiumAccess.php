<?php
namespace App\Services;
use App\Models\Subscription;use Illuminate\Support\Facades\DB;
class PremiumAccess {
 public static function plan(int $id):string {if(DB::table('cash_wallets')->where('user_id',$id)->where('frozen',true)->exists())return 'free';return Subscription::where('user_id',$id)->active()->orderByRaw("CASE WHEN plan='pro' THEN 0 ELSE 1 END")->value('plan')??'free';}
 public static function rules(int $id){return DB::table('premium_rules')->where('plan_code',self::plan($id))->first()??DB::table('premium_rules')->where('plan_code','free')->first();}
 // Caller holds the user row lock, the common serialization point for all allowances.
 public static function usage(int $id){DB::table('premium_usage')->insertOrIgnore(['user_id'=>$id]);$u=DB::table('premium_usage')->where('user_id',$id)->lockForUpdate()->first();$set=[];
  if(!$u->last_action_at || \Carbon\Carbon::parse($u->last_action_at)->lte(now()->subMinutes(30)) || !$u->session_started_at || \Carbon\Carbon::parse($u->session_started_at)->lte(now()->subDay()))$set+=['session_likes'=>0,'session_started_at'=>now()];
  if($u->rewind_day!==now()->toDateString())$set+=['rewind_day'=>now()->toDateString(),'rewinds'=>0];
  $week=now()->startOfWeek()->toDateString();if($u->star_week!==$week)$set+=['star_week'=>$week,'weekly_stars'=>0];
  if($set)DB::table('premium_usage')->where('user_id',$id)->update($set);return DB::table('premium_usage')->where('user_id',$id)->first();
 }
 public static function status(int $id):array {return DB::transaction(function()use($id){DB::table('users')->where('id',$id)->lockForUpdate()->first();$u=self::usage($id);$r=self::rules($id);return ['plan'=>self::plan($id),'hide_ads'=>self::hidesAds($id),'session_likes_remaining'=>$r->session_likes===null?null:max(0,$r->session_likes-$u->session_likes),'daily_rewinds_remaining'=>$r->daily_rewinds===null?null:max(0,$r->daily_rewinds-$u->rewinds),'super_likes_remaining'=>max(0,$r->weekly_stars-$u->weekly_stars)+$u->purchased_stars,'settings'=>['hide_ads'=>(bool)$u->hide_ads,'hide_age'=>(bool)$u->hide_age,'hide_distance'=>(bool)$u->hide_distance,'incognito'=>(bool)$u->incognito,'passport_country'=>$u->passport_country],'session_reset'=>'30 minutes without a swipe, or after 24 hours'];});}
 public static function deleteProfile(int $id):void {
  foreach(DB::table('premium_content')->where('creator_id',$id)->get() as $p){\Illuminate\Support\Facades\Storage::disk('local')->delete($p->media_path);DB::table('content_unlocks')->where('content_id',$p->id)->delete();}
  DB::table('premium_content')->where('creator_id',$id)->delete();
  DB::table('premium_usage')->where('user_id',$id)->delete();DB::table('swipe_actions')->where('user_id',$id)->orWhere('target_id',$id)->delete();DB::table('content_unlocks')->where('user_id',$id)->delete();
  // Keep payment receipts/ledger and financial liabilities for reconciliation; disable any pending fulfilment after deletion.
 }
 public static function hidesAds(int $id):bool{return (bool)self::rules($id)->hide_ads && (DB::table('premium_usage')->where('user_id',$id)->value('hide_ads')??true);}
}
