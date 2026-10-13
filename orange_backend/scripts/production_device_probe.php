<?php
require '/var/www/ketua.sanaa.co/orange_backend/vendor/autoload.php';
$app=require '/var/www/ketua.sanaa.co/orange_backend/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use App\Models\Users;
$manifest=json_decode(file_get_contents('/var/backups/ketua/codex-20261010/device-qa-manifest.json'),true);
$key=config('ketua.api_key');
$tokens=[]; $checks=0;
function callApi($path,$body=[],$token=null,$method='POST') {
 global $key;
 $curl=curl_init('https://ketua.sanaa.co/api/'.$path);
 curl_setopt_array($curl,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>25,CURLOPT_USERAGENT=>'KetuaReadiness/1.0',CURLOPT_HTTPHEADER=>array_filter(['Accept: application/json','Content-Type: application/json','apikey: '.$key,$token?'Authorization: Bearer '.$token:null])]);
 if ($method==='POST') { curl_setopt($curl,CURLOPT_POST,true); curl_setopt($curl,CURLOPT_POSTFIELDS,json_encode($body)); }
 $raw=curl_exec($curl);$code=curl_getinfo($curl,CURLINFO_HTTP_CODE);curl_close($curl);
 $json=json_decode($raw,true);return [$code,$json];
}
function check($condition,$label) { global $checks; if (!$condition) throw new RuntimeException('FAIL: '.$label); $checks++; echo 'PASS: '.$label.PHP_EOL; }
try {
 foreach (array_merge([$manifest['owner_id']],$manifest['qa_user_ids']) as $id) {
  $u=Users::findOrFail($id); $created=$u->createToken('codex-device-probe');$tokens[$id]=$created;
 }
 $owner=$manifest['owner_id']; $qa=$manifest['qa_user_ids'][0]; $ot=$tokens[$owner]->plainTextToken; $qt=$tokens[$qa]->plainTextToken;
 [$code,$r]=callApi('auth/me',[],$ot);check($code===200 && $r['data']['id']===$owner,'production bearer identity');
 [$code,$r]=callApi('catalog',[],null,'GET');check($code===200 && $r['default_currency']==='UGX','production plan catalog');
 [$code,$r]=callApi('getProfile',['user_id'=>$owner,'my_user_id'=>$owner],$ot);check($code===200 && $r['status'] && count($r['data']['images'])>0,'owner profile photos and preferences');
 [$code,$r]=callApi('getProfile',['user_id'=>$qa,'my_user_id'=>$qa],$ot);check($code===200 && $r['status'] && !isset($r['data']['identity']) && !isset($r['data']['wallet']),'production public profile privacy');
 [$code,$r]=callApi('getExplorePageProfileList',['user_id'=>$qa],$ot);check($code===200 && $r['status'] && count($r['data'])>=3,'production discovery fixtures');
 [$code,$r]=callApi('heartbeat',[],$ot);check($code===200 && $r['status'],'production heartbeat');
 [$code,$r]=callApi('profile/completeness',[],$ot);check($code===200 && $r['score']===100,'production profile completeness');
 [$code,$r]=callApi('match/like',['user_id'=>$owner],$qt);check($code===200 && ($r['status'] || $r['message']==='Already liked.'),'QA incoming like fixture');
 [$code,$r]=callApi('likes/incoming',[],$ot,'GET');check($code===200 && $r['count']>=1 && $r['data']===[] && !$r['unlocked'],'production Free likes privacy');
 $welcome='QA message: welcome to KETUA! Please reply to test delivery.';
 if (!App\Models\Message::where('sender_id',$qa)->where('receiver_id',$owner)->where('body',$welcome)->exists()) {
  [$code,$r]=callApi('chat/send',['receiver_id'=>$owner,'body'=>$welcome,'message_type'=>'text'],$qt);check($code===200 && $r['status'],'QA incoming chat message');
 } else {check(true,'QA welcome fixture already exists');}
 [$code,$r]=callApi('chat/conversations',[],$ot);check($code===200 && $r['status'] && count($r['data'])>=1,'production conversations');
 [$code,$r]=callApi('boost/status',[],$ot);check($code===200 && isset($r['duration_minutes']) && $r['duration_minutes']===30,'production Boost status');
 [$code,$r]=callApi('subscription/status',[],$ot);check($code===200 && !$r['active'],'owner has no fabricated paid entitlement');
 echo 'RESULT: '.$checks.'/'.$checks.' production checks passed'.PHP_EOL;
} finally { foreach($tokens as $created) $created->accessToken->delete(); }
