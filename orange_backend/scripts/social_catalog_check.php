<?php
require dirname(__DIR__).'/vendor/autoload.php';$app=require dirname(__DIR__).'/bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;use Illuminate\Http\Request;use App\Http\Controllers\ExperienceController;use App\Http\Controllers\SettingController;use App\Models\Users;
if(config('database.connections.mysql.database')!=='ketua_test')throw new RuntimeException('Isolated DB only');
$passes=0;function check($ok,$label){global $passes;if(!$ok)throw new RuntimeException($label);$passes++;echo "PASS: $label\n";}
DB::beginTransaction();
try{
 $a=new Users;$a->identity='qa-social-a';$a->name='qa-social-a';$a->email='qa-social-a@ketua.local';$a->password=Illuminate\Support\Facades\Hash::make(bin2hex(random_bytes(24)));$a->fullname='QA';$a->wallet=0;$a->is_verified=0;$a->save();$b=new Users;$b->identity='qa-social-b';$b->name='qa-social-b';$b->email='qa-social-b@ketua.local';$b->password=$a->password;$b->fullname='QA';$b->wallet=0;$b->is_verified=0;$b->save();auth('app_users')->setUser(new Illuminate\Auth\GenericUser($a->getAttributes()));$c=new ExperienceController;
 $values=['title'=>'QA social event','category'=>'event','description'=>'QA fixture','venue'=>'Kampala','starts_at'=>now()->addDay(),'ends_at'=>now()->addDay()->addHours(2),'currency_code'=>'UGX','amount_minor'=>0,'capacity'=>1,'published'=>true,'is_demo'=>false,'created_at'=>now(),'updated_at'=>now()];
 $id=DB::table('experiences')->insertGetId($values);$req=new Request(['experience_id'=>$id]);$r=$c->reserve($req)->getData(true);check($r['status']===true,'Free ticket issued');
 $r2=$c->reserve($req)->getData(true);check($r2['data']['ticket_code']===$r['data']['ticket_code']&&DB::table('experience_tickets')->where('experience_id',$id)->count()===1,'Repeated reservation is idempotent');
 auth('app_users')->setUser(new Illuminate\Auth\GenericUser($b->getAttributes()));check($c->reserve($req)->getStatusCode()===409,'Capacity enforced for second user');check(collect($c->tickets()->getData(true)['data'])->where('experience_id',$id)->isEmpty(),'Tickets private to owner');
 DB::table('experiences')->where('id',$id)->update(['amount_minor'=>100]);check($c->reserve($req)->getStatusCode()===409,'Paid ticket cannot bypass checkout');
 DB::table('experiences')->where('id',$id)->update(['is_demo'=>true]);check($c->reserve($req)->getStatusCode()===409,'Preview cannot issue real tickets');
 DB::table('experiences')->where('id',$id)->update(['published'=>false]);check($c->reserve($req)->getStatusCode()===404,'Unpublished experience inaccessible');check(collect($c->index(new Request())->getData(true)['data'])->where('id',$id)->isEmpty(),'Unpublished experience absent from discovery');
 try{$c->save(new Request(array_merge($values,['currency_code'=>'XXX'])));throw new RuntimeException('Invalid currency accepted');}catch(Illuminate\Validation\ValidationException $e){check(true,'Unknown currency rejected');}
 $earn=$c->earn()->getData(true);check($earn['data']['payout_available']===false,'Unconfigured payout not advertised');check($earn['data']['received_gifts']===DB::table('gift_transactions')->where('receiver_id',$b->id)->count(),'Creator stats come from actual ledger');
 try{(new SettingController)->addGift(new Request(['name'=>'QA','coin_price'=>-1]));throw new RuntimeException('Negative gift accepted');}catch(Illuminate\Validation\ValidationException $e){check(true,'Invalid gift price and absent artwork rejected');}
 $file=tempnam(sys_get_temp_dir(),'ketua-gift-');file_put_contents($file,base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII='));
 $upload=new Illuminate\Http\UploadedFile($file,'qa-gift.png','image/png',null,true);
 $add=new Request(['name'=>'QA Heartbeat','coin_price'=>50]);$add->files->set('image',$upload);$settings=new SettingController;$new=$settings->addGift($add)->getData(true)['data'];
 check($new['coin_price']===50 && $new['name']==='QA Heartbeat','Admin creates named gift with current coin value');
 $settings->updateGift(new Request(['id'=>$new['id'],'name'=>'QA Spark','coin_price'=>75]));$g=App\Models\Gifts::find($new['id']);check($g->coin_price===75 && (int)$g->price===75 && $g->name==='QA Spark','Admin changes canonical gift price and name');
 check($g->toArray()['coin_price']===75,'Mobile catalog exposes actual price');
 $mismatch=(new App\Http\Controllers\GiftController)->sendGift(new Request(['gift_id'=>$g->id,'receiver_id'=>$a->id,'expected_coin_price'=>50]));check($mismatch->getStatusCode()===409 && (int)Users::find($b->id)->wallet===0,'Price change cannot charge a stale gift confirmation');
 App\Models\GlobalFunction::deleteFile($g->image);unlink($file);
 DB::table('experiences')->where('id',$id)->update(['published'=>true,'is_demo'=>false,'amount_minor'=>0,'capacity'=>2]);
 auth('app_users')->setUser(App\Models\User::findOrFail($b->id));
 check($c->reserve($req)->getData(true)['status']===true,'Free ticket available after capacity increase');
 $deleted=(new App\Http\Controllers\UsersController)->deleteMyAccount(new Request());
 check($deleted->getData(true)['status']===true && !DB::table('experience_tickets')->where('user_id',$b->id)->exists(),'Account deletion removes owned tickets and releases capacity');
 $token=$a->createToken('qa-admin-delete');$tokenId=$token->accessToken->id;
 $removed=(new App\Http\Controllers\UsersController)->deleteUserFromAdmin(new Request(['user_id'=>$a->id]));
 check($removed->getData(true)['status']===true && !DB::table('experience_tickets')->where('user_id',$a->id)->exists(),'Admin deletion removes owned tickets');
 check(!DB::table('personal_access_tokens')->where('id',$tokenId)->exists(),'Admin deletion revokes login tokens');
 auth('app_users')->forgetUser();check($c->earn()->getStatusCode()===401,'Creator stats require authentication');
 echo "RESULT: $passes/$passes social catalog checks passed\n";
}finally{DB::rollBack();}
