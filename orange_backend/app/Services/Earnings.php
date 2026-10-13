<?php
namespace App\Services;
use Illuminate\Support\Facades\DB;
class Earnings {
 // Cash sales must be settled, seven days old, and explicitly released by admin.
 // Only settled content and once-consumed funded gifts qualify; reservation quotes never do.
 public static function eligible(int $id,string $currency) {
  return DB::table('creator_sales')->where('creator_id',$id)->where('currency_code',$currency)->where('status','available')->whereNull('withdrawal_id')->where('created_at','<=',now()->subDays(7))->whereIn('order_id',function($q){$q->select('id')->from('commerce_orders')->where('status','settled')->whereIn('user_id',function($q){$q->select('id')->from('users')->where('is_block',0)->where('qa_coin_mode',false);})->where('kind','content')->whereNotIn('user_id',function($q){$q->select('user_id')->from('cash_wallets')->where('frozen',true);})->whereNotIn('user_id',function($q){$q->select('id')->from('users')->where('qa_coin_mode',true)->orWhere('is_block',1);});});
 }
 public static function gifts(int $id,string $currency){return DB::table('gift_cash_earnings')->where('creator_id',$id)->where('currency_code',$currency)->where('status','available')->whereNull('withdrawal_id')->where('created_at','<=',now()->subDays(7))->whereIn('source_order',function($q){$q->select('id')->from('commerce_orders')->where('status','settled')->whereIn('user_id',function($q){$q->select('id')->from('users')->where('is_block',0)->where('qa_coin_mode',false);})->where('kind','pack')->whereNotIn('user_id',function($q){$q->select('user_id')->from('cash_wallets')->where('frozen',true);})->whereNotIn('user_id',function($q){$q->select('id')->from('users')->where('qa_coin_mode',true)->orWhere('is_block',1);});});}
 public static function notify(int $userId,string $message):void {UserAlerts::send($userId,'KETUA earnings',$message);}
 public static function event(string $id,string $action,string $actor,?string $note=null):void {DB::table('withdrawal_events')->insert(['withdrawal_id'=>$id,'action'=>$action,'actor'=>$actor,'note'=>$note,'created_at'=>now()]);}
}
