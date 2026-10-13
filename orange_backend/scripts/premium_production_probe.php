<?php
require '/var/www/ketua.sanaa.co/orange_backend/vendor/autoload.php';$app=require '/var/www/ketua.sanaa.co/orange_backend/bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use App\Models\Users;use Illuminate\Support\Facades\DB;
$m=json_decode(file_get_contents('/var/backups/ketua/codex-20261010/device-qa-manifest.json'),true);$u=Users::findOrFail($m['owner_id']);$token=$u->createToken('codex-premium-probe');$key=config('ketua.api_key');$n=0;
function ck($ok,$label){global $n;if(!$ok)throw new RuntimeException('FAIL: '.$label);$n++;echo 'PASS: '.$label.PHP_EOL;}
function call($path,$body=null,$auth=true){global $token,$key;$c=curl_init('https://ketua.sanaa.co/'.$path);$headers=['Accept: application/json','apikey: '.$key,'Content-Type: application/json'];if($auth)$headers[]='Authorization: Bearer '.$token->plainTextToken;curl_setopt_array($c,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>30,CURLOPT_HTTPHEADER=>$headers]);if($body!==null)curl_setopt_array($c,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>json_encode($body)]);$raw=curl_exec($c);$code=curl_getinfo($c,CURLINFO_HTTP_CODE);curl_close($c);return [$code,json_decode($raw,true)];}
try{
 [$code,$r]=call('api/premium/status');ck($code===200&&$r['data']['plan']==='free'&&$r['data']['daily_rewinds_remaining']===0,'Free allowances reflect verified account');ck($r['packs'][0]['amount_minor']===10000&&$r['packs'][1]['amount_minor']===15000,'Super Like pack prices live');
 [$code,$r]=call('api/catalog');$gold=array_values(array_filter($r['plans'],fn($p)=>$p['code']==='gold'))[0];$prices=array_column(array_filter($gold['prices'],fn($p)=>$p['currency_code']==='UGX'),'amount_minor','period_days');ck($prices[30]===37000&&$prices[7]===10000&&$prices[90]===36000,'Weekly, monthly and three-month prices live');ck(in_array('Unlimited likes',$gold['features'])&&in_array('4 Super Likes per week',$gold['features']),'Gold feature catalog reflects real allowances');
 [$code,$r]=call('api/account/wallet?user_id='.$m['qa_user_ids'][0]);ck($code===200&&$r['wallets']===[],'No seeded money or foreign wallet leakage');
 [$code,$r]=call('api/premium/settings',['hide_ads'=>true]);ck($code===403,'Free account cannot unlock premium controls');
 [$code,$r]=call('api/match/rewind',['user_id'=>$m['qa_user_ids'][0]]);ck($code===403,'Free rewind denied in production');
 [$code,$r]=call('api/commerce/purchase',['kind'=>'pack','item_id'=>(string)DB::table('super_like_packs')->where('quantity',5)->value('id'),'currency_code'=>'UGX','expected_amount_minor'=>10000,'idempotency_key'=>(string)Illuminate\Support\Str::uuid()]);ck($code===409&&!$r['status'],'Insufficient balance cannot create paid access');
 [$code,$r]=call('api/premium/content');ck($code===200&&is_array($r['data'])&&!str_contains(json_encode($r),'media_path'),'Paid-content catalog exposes no private file paths');
 [$code,$r]=call('api/premium/content/999999/media',null,false);ck($code===401,'Private paid media requires bearer identity');
 [$code,$r]=call('api/payments/status',['order_id'=>(string)Illuminate\Support\Str::uuid()]);ck($code===404,'Unknown or foreign order status denied');
 [$code,$r]=call('api/payments/pesapal/ipn?OrderTrackingId=unknown&OrderMerchantReference=unknown',null,false);ck($code===404,'Unknown notification cannot settle funds');
 [$code,$r]=call('premium-commerce',null,false);ck($code===302,'Commerce admin guarded by administrator login');
 [$code,$r]=call('api/ads?placement=swipe');ck($code===200&&is_array($r['data']),'Authenticated sponsored swipe catalog');
 echo "RESULT: $n/$n production premium checks passed\n";
}finally{$token->accessToken->delete();}
