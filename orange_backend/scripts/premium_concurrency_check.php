<?php
require __DIR__.'/../vendor/autoload.php';$app=require __DIR__.'/../bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;use App\Models\Users;
if(config('database.connections.mysql.database')!=='ketua_test'||!function_exists('pcntl_fork'))throw new RuntimeException('Isolated database and process control required');
$u=new Users();$u->identity='qa-race-'.bin2hex(random_bytes(6));$u->name=$u->fullname='QA commerce race';$u->username=$u->identity;$u->email=$u->identity.'@example.test';$u->password=bcrypt('isolated');$u->dob='1997-01-01';$u->save();$id=$u->id;$files=[];$pack=DB::table('super_like_packs')->where('quantity',5)->first();
try{
 DB::table('cash_wallets')->insert(['user_id'=>$id,'currency_code'=>'UGX','balance_minor'=>10000,'created_at'=>now(),'updated_at'=>now()]);App\Services\PremiumAccess::usage($id);
 foreach([true,false] as $same){$pids=[];$key=(string)Illuminate\Support\Str::uuid();$files=[];
  for($i=0;$i<4;$i++){$path=sys_get_temp_dir().'/ketua-commerce-race-'.bin2hex(random_bytes(8));$files[]=$path;DB::disconnect('mysql');$pid=pcntl_fork();if($pid===-1)throw new RuntimeException('Cannot fork');if($pid===0){try{auth('app_users')->setUser(App\Models\User::findOrFail($id));$body=['kind'=>'pack','item_id'=>(string)$pack->id,'currency_code'=>'UGX','expected_amount_minor'=>10000,'idempotency_key'=>$same?$key:(string)Illuminate\Support\Str::uuid()];$r=(new App\Http\Controllers\CommerceController)->purchase(Illuminate\Http\Request::create('/','POST',$body));file_put_contents($path,json_encode(['ok'=>$r->getData(true)['status'],'code'=>$r->getStatusCode()]));exit(0);}catch(Throwable $e){file_put_contents($path,json_encode(['error'=>get_class($e)]));exit(1);}}$pids[]=$pid;}
  foreach($pids as $pid){pcntl_waitpid($pid,$status);if(pcntl_wexitstatus($status)!==0)throw new RuntimeException('Worker failed');}
  DB::purge('mysql');$responses=array_map(fn($p)=>json_decode(file_get_contents($p),true),$files);$success=count(array_filter($responses,fn($r)=>$r['ok']??false));
  if($success!==($same?4:1)||DB::table('cash_wallets')->where('user_id',$id)->value('balance_minor')!==0||DB::table('premium_usage')->where('user_id',$id)->value('purchased_stars')!==5||DB::table('commerce_orders')->where('user_id',$id)->count()!==1)throw new RuntimeException('Concurrent purchase invariant failed');
  echo $same?"PASS: four concurrent same-key retries debit once\n":"PASS: four concurrent different purchases cannot overspend\n";
  foreach($files as $p)unlink($p);$files=[];DB::table('cash_ledger')->where('user_id',$id)->delete();DB::table('commerce_orders')->where('user_id',$id)->delete();DB::table('cash_wallets')->where('user_id',$id)->update(['balance_minor'=>10000]);DB::table('premium_usage')->where('user_id',$id)->update(['purchased_stars'=>0]);
 }
 echo "RESULT: 2/2 four-worker concurrency checks passed\n";
}finally{DB::purge('mysql');foreach($files as $p)if(is_file($p))unlink($p);foreach(['cash_ledger','commerce_orders','cash_wallets','premium_usage'] as $t)DB::table($t)->where('user_id',$id)->delete();Users::where('id',$id)->delete();}
