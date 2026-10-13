<?php
// Owner-authorized dummy profiles; run only after the review is deployed.
require '/var/www/ketua.sanaa.co/orange_backend/vendor/autoload.php';
$app = require '/var/www/ketua.sanaa.co/orange_backend/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use App\Models\Users;
use App\Models\Images;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
if (config('database.connections.mysql.database') !== 'ketua') throw new RuntimeException('Unexpected database');
$owners = Users::where('fullname','Sanaa Group Inc')->get();
if ($owners->count() !== 1) throw new RuntimeException('Expected exactly one owner account');
$owner = $owners->first();
if (str_starts_with($owner->identity,'phone:')) throw new RuntimeException('Expected Google owner account');
$backup = '/var/backups/ketua/codex-20261010/device-qa-owner-before.json';
if (!file_exists($backup)) { file_put_contents($backup, json_encode($owner->getAttributes(), JSON_PRETTY_PRINT)); chmod($backup,0600); }
$interestIds = DB::table('interests')->limit(3)->pluck('id')->implode(',');
$goal = DB::table('relationship_goals')->value('id');
$manifest = ['owner_id'=>$owner->id,'qa_user_ids'=>[],'created_at'=>date(DATE_ATOM),'note'=>'Synthetic profiles and owner details authorized for device QA; remove before release.'];
DB::transaction(function () use ($owner,$interestIds,$goal,&$manifest) {
 $owner->fullname='Sanaa QA'; $owner->bio='TEST ACCOUNT • Exploring meaningful connections, music and creative ideas.';
 $owner->about='Synthetic profile details for KETUA feature testing.'; $owner->dob='1997-06-15'; $owner->gender=1;
 $owner->country='Uganda'; $owner->state='Central'; $owner->city='Kampala';
 $owner->gender_preferred=3; $owner->age_preferred_min=18; $owner->age_preferred_max=50; $owner->distance_preference=100;
 $owner->lattitude='0.3136'; $owner->longitude='32.5811'; $owner->interests=$interestIds; $owner->relationship_goal_id=$goal;
 $owner->app_language='en'; $owner->save();
 if (!Images::where('user_id',$owner->id)->where('image','ketua-qa/sanaa.jpg')->exists()) { $image=new Images; $image->user_id=$owner->id; $image->image='ketua-qa/sanaa.jpg'; $image->save(); }
 foreach ([['Amani',2,'1999-04-12'],['Zuri',2,'1996-11-02'],['Alex',1,'1998-08-20']] as $i=>$row) {
  [$name,$gender,$dob]=$row;
  $identity='ketua-device-qa-20261010-'.strtolower($name);
  $u=Users::where('identity',$identity)->first();
  if (!$u) { $u=new Users; $u->identity=$identity; $u->name=$identity; $u->email=$identity.'@ketua.local'; $u->password=Hash::make(bin2hex(random_bytes(32))); }
  $u->fullname=$name.' • QA'; $u->username='ketua_qa_'.strtolower($name);
  $u->bio='TEST PROFILE • '.(['Music, coffee and thoughtful conversations.','Creative projects, reading and weekend walks.','Food, travel and new friendships.'][$i]);
  $u->about='Synthetic QA profile. No real person or payment entitlement.'; $u->dob=$dob; $u->gender=$gender;
  $u->country='Uganda'; $u->state='Central'; $u->city='Kampala'; $u->gender_preferred=3; $u->age_preferred_min=18; $u->age_preferred_max=50;
  $u->interests=$interestIds; $u->relationship_goal_id=$goal; $u->lattitude=(string)(0.33+$i*.015); $u->longitude='32.60';
  $u->is_block=$u->is_fake=$u->is_verified=$u->anonymous=0; $u->app_language='en'; $u->wallet=$u->coins=$u->total_collected=0; $u->save();
  $path='ketua-qa/'.strtolower($name).'.jpg';
  if (!Images::where('user_id',$u->id)->where('image',$path)->exists()) { $image=new Images; $image->user_id=$u->id; $image->image=$path; $image->save(); }
  $manifest['qa_user_ids'][]=$u->id;
 }
});
file_put_contents('/var/backups/ketua/codex-20261010/device-qa-manifest.json',json_encode($manifest,JSON_PRETTY_PRINT));
chmod('/var/backups/ketua/codex-20261010/device-qa-manifest.json',0600);
echo 'Owner dummy profile and three clearly labeled QA profiles seeded; no wallets or paid entitlements granted.'.PHP_EOL;
