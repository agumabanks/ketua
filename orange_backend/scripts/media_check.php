<?php
require __DIR__.'/../vendor/autoload.php';
$app=require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
if (config('database.connections.mysql.database') !== 'ketua_test') throw new RuntimeException('Isolated test database required');
use App\Models\GlobalFunction;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Session;
$paths=[];$files=[];$count=0;
function checkMedia($ok,$label) { global $count; if (!$ok) throw new RuntimeException('FAIL: '.$label); $count++;echo 'PASS: '.$label.PHP_EOL; }
function fixtureUpload(string $data,string $name): UploadedFile { global $files;$p=tempnam(sys_get_temp_dir(),'ketua-media-');file_put_contents($p,$data);$files[]=$p;return new UploadedFile($p,$name,null,null,true); }
try {
 $png=base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6l1sAAAAASUVORK5CYII=');
 $public=GlobalFunction::saveFileAndGivePath(fixtureUpload($png,'qa.png'));$paths[]=['public',$public];
 checkMedia(str_starts_with($public,'uploads/') && Storage::disk('public')->exists($public),'valid public media uses public disk');
 checkMedia(!Storage::disk('local')->exists($public),'public media does not use inaccessible legacy disk');
 $private=GlobalFunction::saveFileAndGivePath(fixtureUpload($png,'qa.png'),['png'],1024*1024,'local','verification');$paths[]=['local',$private];
 checkMedia(Storage::disk('local')->exists($private) && !Storage::disk('public')->exists($private),'verification media stays outside public storage');
 foreach ([['<?php echo 1;', 'fake.jpg'],[$png,'wrong.jpg']] as [$data,$name]) {
  try {GlobalFunction::saveFileAndGivePath(fixtureUpload($data,$name));throw new RuntimeException('Invalid media accepted');}
  catch (InvalidArgumentException $e) { checkMedia(true,'reject content/type mismatch: '.$name); }
 }
 try {GlobalFunction::saveFileAndGivePath(fixtureUpload($png,'qa.png'),['png'],1024*1024,'public','verification');throw new RuntimeException('Private media exposed');}
 catch (InvalidArgumentException $e) {checkMedia(true,'verification cannot be stored publicly');}
 GlobalFunction::deleteFile('../'.$public);
 checkMedia(Storage::disk('public')->exists($public),'traversal deletion is rejected');
 GlobalFunction::deleteFile($public);checkMedia(!Storage::disk('public')->exists($public),'nested public media deletion works');
 GlobalFunction::deleteFile($private,'local');checkMedia(!Storage::disk('local')->exists($private),'private verification deletion works');
 $middleware=new App\Http\Middleware\EnsureAdmin();$ran=false;
 $next=function () use (&$ran) {$ran=true;return response('ok');};
 Session::forget(['user_name','user_type']);$r=$middleware->handle(Illuminate\Http\Request::create('/verification-media/1/document'),$next);
 checkMedia($r->getStatusCode()===302 && !$ran,'anonymous verification-media request denied before controller');
 Session::put('user_name','qa-limited');Session::put('user_type',2);$r=$middleware->handle(Illuminate\Http\Request::create('/verification-media/1/document'),$next);
 checkMedia($r->getStatusCode()===403 && !$ran,'non-admin verification-media request denied before controller');
 Session::put('user_type',1);$r=$middleware->handle(Illuminate\Http\Request::create('/verification-media/1/document'),$next);
 checkMedia($r->getStatusCode()===200 && $ran,'admin verification-media guard permits review');
 echo 'RESULT: '.$count.'/'.$count.' media checks passed'.PHP_EOL;
} finally {
 foreach ($paths as [$disk,$path]) Storage::disk($disk)->delete($path);
 foreach ($files as $file) if(is_file($file))unlink($file);
 Session::forget(['user_name','user_type']);
}
