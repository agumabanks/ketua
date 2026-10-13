<?php
namespace App\Services;
use Illuminate\Support\Facades\DB;
class FundedCoins {
 public static function issue($order,int $coins):void {
  DB::table('coin_funding_lots')->insertOrIgnore(['user_id'=>$order->user_id,'source_order'=>$order->id,'currency_code'=>$order->currency_code,'coins_remaining'=>$coins,'value_remaining'=>$order->amount_minor,'created_at'=>now(),'updated_at'=>now()]);
 }
 // Called inside the same transaction and account locks as the wallet debit.
 // Sharing moves funding; gifting consumes it once. Recipient gift coins have no new funding.
 public static function move(int $sender,int $receiver,int $coins,?int $giftId=null):void {
  $lots=DB::table('coin_funding_lots')->where('user_id',$sender)->where('coins_remaining','>',0)->orderBy('id')->lockForUpdate()->get();
  foreach($lots as $lot){if($coins<=0)break;$take=min($coins,$lot->coins_remaining);$value=$take===$lot->coins_remaining?$lot->value_remaining:intdiv($lot->value_remaining*$take,$lot->coins_remaining);$coins-=$take;
   DB::table('coin_funding_lots')->where('id',$lot->id)->update(['coins_remaining'=>$lot->coins_remaining-$take,'value_remaining'=>$lot->value_remaining-$value,'updated_at'=>now()]);
   if($giftId!==null){if($value>0)DB::table('gift_cash_earnings')->insert(['gift_transaction_id'=>$giftId,'creator_id'=>$receiver,'source_order'=>$lot->source_order,'currency_code'=>$lot->currency_code,'gross_minor'=>$value,'created_at'=>now(),'updated_at'=>now()]);}
   elseif($receiver>0) {DB::table('coin_funding_lots')->insertOrIgnore(['user_id'=>$receiver,'source_order'=>$lot->source_order,'currency_code'=>$lot->currency_code,'coins_remaining'=>0,'value_remaining'=>0,'created_at'=>now(),'updated_at'=>now()]);DB::table('coin_funding_lots')->where('user_id',$receiver)->where('source_order',$lot->source_order)->increment('coins_remaining',$take);DB::table('coin_funding_lots')->where('user_id',$receiver)->where('source_order',$lot->source_order)->increment('value_remaining',$value);}
  }
 }
 public static function consume(int $user,int $coins):void {self::move($user,0,$coins);}
 public static function sourceSafe(string $order):bool {
  $o=DB::table('commerce_orders')->where('id',$order)->first();if(!$o||!DB::table('users')->where('id',$o->user_id)->exists()||$o->status!=='settled'||!in_array($o->kind,['pack','content'],true))return false;
  return !DB::table('cash_wallets')->where('user_id',$o->user_id)->where('frozen',true)->exists() && !DB::table('users')->where('id',$o->user_id)->where(function($q){$q->where('qa_coin_mode',true)->orWhere('is_block',1);})->exists();
 }
}
