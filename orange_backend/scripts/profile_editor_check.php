<?php
require __DIR__.'/../vendor/autoload.php';$app=require __DIR__.'/../bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
if(config('database.connections.mysql.database')!=='ketua_test')throw new RuntimeException('Isolated database required');
use App\Models\Users;use App\Models\Images;use App\Models\GlobalFunction;use App\Http\Controllers\UsersController;use Illuminate\Http\Request;use Illuminate\Http\UploadedFile;use Illuminate\Support\Facades\DB;use Illuminate\Support\Facades\Storage;
$count=0;$paths=[];$temps=[];
function ck($ok,$label){global $count;if(!$ok)throw new RuntimeException('FAIL: '.$label);$count++;echo 'PASS: '.$label.PHP_EOL;}
function upload($name='fixture.png') {global $temps;$p=tempnam(sys_get_temp_dir(),'ketua-profile-');file_put_contents($p,base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6l1sAAAAASUVORK5CYII='));$temps[]=$p;return new UploadedFile($p,$name,null,null,true);}
function update($body=[],$files=[]){$r=Request::create('/api/updateProfile','POST',$body);if($files)$r->files->set('image',$files);return(new UsersController)->updateProfile($r);}
function fixture($name){$u=new Users();$u->identity='qa-photo-'.bin2hex(random_bytes(8));$u->fullname='QA Profile Editor';$u->name='QA Profile Editor';$u->username=$name;$u->email=$name.'@example.test';$u->password=bcrypt('QA-only-test');$u->dob='1997-01-01';$u->save();return $u;}
DB::beginTransaction();
try{
 $me=fixture('qa_editor_'.bin2hex(random_bytes(4)));$other=fixture('qa_other_'.bin2hex(random_bytes(4)));auth('app_users')->setUser(App\Models\User::findOrFail($me->id));
 $photos=[];for($i=0;$i<6;$i++){$path=GlobalFunction::saveFileAndGivePath(upload());$paths[]=$path;$p=new Images();$p->user_id=$me->id;$p->image=$path;$p->sort_order=$i;$p->save();$photos[]=$p;}
 $foreign=new Images();$foreign->user_id=$other->id;$foreign->image='qa-foreign.png';$foreign->save();
 $response=update([], [upload()]);ck($response->getStatusCode()===422 && Images::where('user_id',$me->id)->count()===6,'seventh photo rejected without changing existing photos');
 $response=update(['deleteimageids'=>[$foreign->id]],[upload()]);ck($response->getStatusCode()===422 && Images::find($foreign->id)!==null,'foreign photo deletion cannot bypass six-photo limit');
 $response=update(['deleteimageids'=>[$photos[0]->id],'username'=>$other->username]);ck($response->getStatusCode()===422 && Images::find($photos[0]->id)!==null && Storage::disk('public')->exists($photos[0]->image),'duplicate username does not delete a photo');
 $ids=array_map(fn($p)=>(string)$p->id,$photos);$bad=$ids;$bad[0]=(string)$foreign->id;$response=update(['image_order'=>$bad]);ck($response->getStatusCode()===422 && Images::find($photos[0]->id)->sort_order===0,'photo order rejects foreign IDs before mutation');
 $response=update(['deleteimageids'=>[$photos[0]->id]],[upload('valid.png'),upload('wrong.jpg')]);ck($response->getStatusCode()===422 && Images::find($photos[0]->id)!==null,'replacement over the limit keeps original photo');
 $response=update(['deleteimageids'=>[$photos[0]->id,$photos[1]->id]],[upload('valid.png'),upload('wrong.jpg')]);ck($response->getStatusCode()===422 && Images::where('user_id',$me->id)->count()===6 && Storage::disk('public')->exists($photos[0]->image),'content mismatch rolls back staged rows and keeps original files');
 $response=update(['deleteimageids'=>[$photos[0]->id],'image_order'=>array_merge(['new:0'],array_slice($ids,1))],[upload()]);$body=$response->getData(true);ck(($body['status']??false)===true && count($body['data']['images'])===6,'replacement at six photos succeeds');
 $new=$body['data']['images'][0];$paths[]=$new['image'];ck($new['id']!==$photos[0]->id && $new['sort_order']===0,'new edited photo persists as cover');ck(!Storage::disk('public')->exists($photos[0]->image) && Images::find($photos[0]->id)===null,'replaced original is removed after successful save');
 $newIds=array_column($body['data']['images'],'id');$reverse=array_map('strval',array_reverse($newIds));$response=update(['image_order'=>$reverse]);ck(array_map('strval',array_column($response->getData(true)['data']['images'],'id'))===$reverse,'cover/photo order survives a reload');
 $response=update(['bio'=>'A saved profile biography.']);ck(($response->getData(true)['status']??false) && $me->fresh()->bio==='A saved profile biography.','normal text edit works at the six-photo cap');
 $response=update(['lattitude'=>'.31','longitude'=>'32.58','location_accuracy_m'=>'20']);ck(($response->getData(true)['status']??false) && $me->fresh()->location_updated_at && $me->fresh()->location_accuracy_m==20,'fresh location stores accuracy and server timestamp');
 $response=update(['location_accuracy_m'=>10]);ck($response->getStatusCode()===422,'accuracy without a complete location fix is rejected');
 $me=$me->fresh();auth('app_users')->setUser(App\Models\User::findOrFail($me->id));$other->lattitude=.31;$other->longitude=32.581;$other->location_accuracy_m=20;$other->location_updated_at=now();$other->save();
 $other=$other->fresh();$method=new ReflectionMethod(UsersController::class,'publicProfile');$method->setAccessible(true);$public=$method->invoke(new UsersController,$other);
 ck($public['distance_meters']===100,'fresh close locations produce a rounded 100 m distance');ck(!isset($public['longitude'])&&!isset($public['lattitude'])&&!isset($public['location_accuracy_m'])&&!isset($public['location_updated_at']),'public distance never reveals coordinates or GPS metadata');
 $other->longitude=32.59;$other->save();$public=$method->invoke(new UsersController,$other);ck($public['distance_meters']===1000,'distance switches to rounded kilometres above one kilometre');
 $other->location_updated_at=now()->subDays(2);$other->save();$public=$method->invoke(new UsersController,$other);ck($public['distance_meters']===null && $public['distance_km']!==null,'stale locations do not imply metre-level precision');
 $other->location_updated_at=now();$other->location_accuracy_m=800;$other->save();$public=$method->invoke(new UsersController,$other);ck($public['distance_meters']===null,'poor GPS accuracy suppresses metre-level precision');
 $other->lattitude=null;$other->save();$public=$method->invoke(new UsersController,$other);ck($public['distance_km']===null && $public['distance_meters']===null,'missing location stays unavailable instead of showing zero');
 echo "RESULT: $count/$count profile editor checks passed".PHP_EOL;
}finally{DB::rollBack();foreach($paths as $path)Storage::disk('public')->delete($path);foreach($temps as $temp)if(is_file($temp))unlink($temp);auth('app_users')->forgetUser();}
