<?php
require __DIR__.'/../vendor/autoload.php';$app=require __DIR__.'/../bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;use Illuminate\Http\Request;use App\Models\Users;use App\Models\Subscription;use App\Services\Commerce;use App\Services\PremiumAccess;use App\Http\Controllers\MatchController;use App\Http\Controllers\CommerceController;
if(config('database.connections.mysql.database')!=='ketua_test')throw new RuntimeException('Isolated database required');$n=0;function ck($v,$label){global $n;if(!$v)throw new RuntimeException('FAIL: '.$label);$n++;echo 'PASS: '.$label.PHP_EOL;}
function person(){ $u=new Users();$u->fullname='Premium QA';$u->name='Premium QA';$u->username='qa_'.bin2hex(random_bytes(5));$u->email=$u->username.'@example.test';$u->password=bcrypt('isolated');$u->identity=$u->username;$u->dob='1995-01-01';$u->is_block=0;$u->save();return $u;}
function req($a){return Request::create('/','POST',$a);}
DB::beginTransaction();try{
 $me=person();$target=person();auth('app_users')->setUser(App\Models\User::findOrFail($me->id));$match=new MatchController();PremiumAccess::usage($me->id);DB::table('premium_usage')->where('user_id',$me->id)->update(['session_likes'=>50,'session_started_at'=>now(),'last_action_at'=>now()]);
 $r=$match->likeProfile(req(['user_id'=>$target->id]));ck($r->getStatusCode()===429,'Free 51st like blocked');
 $r=$match->rewind(req(['user_id'=>$target->id]));ck($r->getStatusCode()===403,'Free cannot rewind');
 DB::table('premium_usage')->where('user_id',$me->id)->update(['last_action_at'=>now()->subMinutes(31)]);$r=$match->likeProfile(req(['user_id'=>$target->id]));ck($r->getData(true)['status'] && DB::table('premium_usage')->where('user_id',$me->id)->value('session_likes')===1,'Session resets only after server timeout');
 $r=$match->likeProfile(req(['user_id'=>$target->id]));ck(!$r->getData(true)['status'] && DB::table('premium_usage')->where('user_id',$me->id)->value('session_likes')===1,'Duplicate like does not consume allowance');
 Subscription::create(['user_id'=>$me->id,'plan'=>'gold','provider'=>'test','status'=>'active','started_at'=>now(),'expires_at'=>now()->addDay()]);$r=$match->rewind(req(['user_id'=>$target->id]));ck($r->getData(true)['status'],'Gold can rewind latest like');ck(!App\Models\LikedProfile::where('my_user_id',$me->id)->where('user_id',$target->id)->exists(),'Rewind removes own like');
 $r=$match->rewind(req(['user_id'=>$target->id]));ck($r->getStatusCode()===409,'Rewind cannot replay same action');
 DB::table('premium_usage')->where('user_id',$me->id)->update(['rewinds'=>5]);ck($match->rewind(req(['user_id'=>$target->id]))->getStatusCode()===403,'Gold daily rewind limit enforced');
 for($i=0;$i<4;$i++){$t=person();ck($match->starProfile(req(['user_id'=>$t->id]))->getData(true)['status'],'Included Gold Super Like '.($i+1));}
 $t=person();ck($match->starProfile(req(['user_id'=>$t->id]))->getStatusCode()===402,'Fifth Gold Super Like needs pack');
 DB::table('premium_usage')->where('user_id',$me->id)->update(['purchased_stars'=>1]);ck($match->starProfile(req(['user_id'=>$t->id]))->getData(true)['status'] && DB::table('premium_usage')->where('user_id',$me->id)->value('purchased_stars')===0,'Purchased Super Like consumed once');
 Subscription::create(['user_id'=>$me->id,'plan'=>'pro','provider'=>'test','status'=>'active','started_at'=>now(),'expires_at'=>now()->addDay()]);ck(PremiumAccess::rules($me->id)->daily_rewinds===null,'Pro unlimited rewind policy');
 $uuid=(string)Illuminate\Support\Str::uuid();DB::table('commerce_orders')->insert(['id'=>$uuid,'user_id'=>$me->id,'idempotency_key'=>(string)Illuminate\Support\Str::uuid(),'kind'=>'topup','currency_code'=>'UGX','amount_minor'=>20000,'snapshot'=>'{}','tracking_id'=>'qa-tracking','created_at'=>now(),'updated_at'=>now()]);
 $provider=['merchant_reference'=>$uuid,'currency'=>'UGX','amount'=>20000,'status_code'=>1];$bad=$provider;$bad['amount']=1;try{Commerce::reconcile($uuid,$bad);ck(false,'Mismatch blocked');}catch(DomainException $e){ck(DB::table('cash_wallets')->where('user_id',$me->id)->count()===0,'Wrong provider amount cannot credit wallet');}
 $pending=$provider;$pending['status_code']=0;ck(!Commerce::reconcile($uuid,$pending),'Pending payment grants nothing');
 ck(Commerce::reconcile($uuid,$provider),'Verified provider payment settles');ck(Commerce::reconcile($uuid,$provider)&&DB::table('cash_wallets')->where('user_id',$me->id)->value('balance_minor')===20000,'Duplicate callback cannot double credit');
 $pack=DB::table('super_like_packs')->where('quantity',5)->first();$key=(string)Illuminate\Support\Str::uuid();$body=['kind'=>'pack','item_id'=>(string)$pack->id,'currency_code'=>'UGX','expected_amount_minor'=>10000,'idempotency_key'=>$key];$c=new CommerceController();$r=$c->purchase(req($body));ck($r->getData(true)['status']&&DB::table('premium_usage')->where('user_id',$me->id)->value('purchased_stars')===5,'Pack purchase debits actual price and credits five');
 $r=$c->purchase(req($body));ck($r->getData(true)['status']&&DB::table('cash_wallets')->where('user_id',$me->id)->value('balance_minor')===10000,'Purchase retry cannot double debit');$body['item_id']='999';ck($c->purchase(req($body))->getStatusCode()===409,'Conflicting checkout key rejected');
 $body['idempotency_key']=(string)Illuminate\Support\Str::uuid();$body['item_id']=(string)$pack->id;$body['expected_amount_minor']=1;ck($c->purchase(req($body))->getStatusCode()===409,'Changed displayed price rejected');
 $event=DB::table('experiences')->insertGetId(['title'=>'QA paid live event','description'=>'Isolated fixture','venue'=>'QA venue','category'=>'live','starts_at'=>now()->addHour(),'ends_at'=>now()->addDay(),'capacity'=>1,'published'=>true,'is_demo'=>false,'currency_code'=>'UGX','amount_minor'=>3000,'created_at'=>now(),'updated_at'=>now()]);
 $ticketBody=['kind'=>'ticket','item_id'=>(string)$event,'currency_code'=>'UGX','expected_amount_minor'=>3000,'idempotency_key'=>(string)Illuminate\Support\Str::uuid()];
 ck($c->purchase(req($ticketBody))->getData(true)['status'],'Paid live ticket issued after atomic balance debit');
 ck(DB::table('experience_tickets')->where('user_id',$me->id)->where('experience_id',$event)->count()===1,'Paid ticket ownership persisted');
 ck($c->purchase(req($ticketBody))->getData(true)['status'] && DB::table('experience_tickets')->where('experience_id',$event)->count()===1,'Ticket purchase retry cannot issue duplicate');
 $buyer=person();DB::table('cash_wallets')->insert(['user_id'=>$buyer->id,'currency_code'=>'UGX','balance_minor'=>10000,'created_at'=>now(),'updated_at'=>now()]);auth('app_users')->setUser(App\Models\User::findOrFail($buyer->id));$ticketBody['idempotency_key']=(string)Illuminate\Support\Str::uuid();ck($c->purchase(req($ticketBody))->getStatusCode()===409 && DB::table('cash_wallets')->where('user_id',$buyer->id)->value('balance_minor')===10000,'Sold-out event cannot charge another buyer');
 auth('app_users')->setUser(App\Models\User::findOrFail($me->id));
 $privatePath='premium-content/qa-'.bin2hex(random_bytes(8)).'.png';Illuminate\Support\Facades\Storage::disk('local')->put($privatePath,base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6l1sAAAAASUVORK5CYII='));
 try{
  $content=DB::table('premium_content')->insertGetId(['creator_id'=>$target->id,'title'=>'QA paid image','description'=>'Isolated fixture','media_path'=>$privatePath,'mime'=>'image/png','currency_code'=>'UGX','amount_minor'=>2000,'published'=>true,'created_at'=>now(),'updated_at'=>now()]);$admin=new App\Http\Controllers\CommerceAdminController();
  $list=$admin->content()->getData(true);ck(!isset($list['data'][0]['media_path'])&&!$list['data'][0]['unlocked'],'Locked catalog never reveals private media path');
  try{$admin->media($content);ck(false,'Locked media denied');}catch(Symfony\Component\HttpKernel\Exception\HttpException $e){ck($e->getStatusCode()===403,'Unpaid viewer cannot load private media');}
  $contentBody=['kind'=>'content','item_id'=>(string)$content,'currency_code'=>'UGX','expected_amount_minor'=>2000,'idempotency_key'=>(string)Illuminate\Support\Str::uuid()];ck($c->purchase(req($contentBody))->getData(true)['status'],'Paid content unlocks after debit');
  ck(str_contains($admin->media($content)->headers->get('Cache-Control'),'private'),'Purchased media uses private response headers');
  ck(DB::table('creator_sales')->where('creator_id',$target->id)->value('gross_minor')===2000,'Creator sale recorded without fabricated payout');
  auth('app_users')->setUser(App\Models\User::findOrFail($buyer->id));try{$admin->media($content);ck(false,'Foreign unlock denied');}catch(Symfony\Component\HttpKernel\Exception\HttpException $e){ck($e->getStatusCode()===403,'Another account cannot reuse buyer unlock');}
 }finally{Illuminate\Support\Facades\Storage::disk('local')->delete($privatePath);}
 auth('app_users')->setUser(App\Models\User::findOrFail($me->id));
 DB::table('membership_prices')->updateOrInsert(['plan_code'=>'gold','currency_code'=>'UGX','period_days'=>7],['amount_minor'=>1000]);
 ck($c->purchase(req(['kind'=>'plan','item_id'=>'gold','currency_code'=>'UGX','period_days'=>7,'expected_amount_minor'=>1000,'idempotency_key'=>(string)Illuminate\Support\Str::uuid()]))->getData(true)['status'],'Weekly plan uses actual total and selected access period');
 ck(Subscription::where('user_id',$me->id)->where('provider','wallet')->where('plan','gold')->first()->expires_at->diffInDays(now(),true)>=6,'Wallet plan expiry is server-authoritative');
 $provider['status_code']=3;ck(!Commerce::reconcile($uuid,$provider) && DB::table('cash_wallets')->where('user_id',$me->id)->value('balance_minor')===-16000 && DB::table('cash_wallets')->where('user_id',$me->id)->value('frozen')===1,'Reversed spent top-up records debt and freezes purchases');
 Commerce::reconcile($uuid,$provider);ck(DB::table('cash_wallets')->where('user_id',$me->id)->value('balance_minor')===-16000,'Duplicate reversal is idempotent');
 ck(!App\Services\KetuaPesapal::trustedUrl('https://pay.pesapal.com.attacker.test/checkout') && App\Services\KetuaPesapal::trustedUrl('https://pay.pesapal.com/checkout'),'Checkout URL allowlist');
 echo "RESULT: $n/$n premium commerce checks passed\n";
}finally{DB::rollBack();auth('app_users')->forgetUser();}
