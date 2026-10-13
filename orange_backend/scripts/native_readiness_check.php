<?php
require __DIR__.'/../vendor/autoload.php';$app=require __DIR__.'/../bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;use Illuminate\Http\Request;use App\Models\Users;use App\Models\Pages;
if(config('database.connections.mysql.database')!=='ketua_test')throw new RuntimeException('Isolated database required');
$n=0;function ck($v,$label){global $n;if(!$v)throw new RuntimeException('FAIL: '.$label);$n++;echo 'PASS: '.$label.PHP_EOL;}
DB::beginTransaction();$applicationPath=null;try{
 $me=new Users();$me->fullname='Native QA';$me->name='Native QA';$me->username='qa_'.bin2hex(random_bytes(5));$me->email=$me->username.'@example.test';$me->password=bcrypt('isolated');$me->identity=$me->username;$me->dob='1995-01-01';$me->is_block=0;$me->can_go_live=0;$me->save();
 auth('app_users')->setUser(App\Models\User::findOrFail($me->id));
 $controller=new App\Http\Controllers\LiveApplicationController();config(['ketua.live_enabled'=>false]);$r=$controller->eligibility(Request::create('/','GET',['user_id'=>999999]))->getData(true);
 ck($r['data']['can_apply'] && !$r['data']['can_broadcast'],'Adult may apply while unconfigured broadcasting stays disabled');
 ck($r['data']['application_state']==='Not applied','Eligibility reads authenticated account');
 ck(!isset($r['data']['agora_app_id']) && !isset($r['data']['agora_app_certificate']),'Eligibility does not expose provider credentials');
 $me->can_go_live=2;$me->save();auth('app_users')->setUser(App\Models\User::findOrFail($me->id));$r=$controller->eligibility(Request::create('/','GET'))->getData(true);
 ck($r['data']['application_state']==='Approved' && !$r['data']['can_broadcast'],'Approval never invents provider availability');
 $me->dob=now()->subYears(15)->format('Y-m-d');$me->can_go_live=0;$me->save();auth('app_users')->setUser(App\Models\User::findOrFail($me->id));$r=$controller->eligibility(Request::create('/','GET'))->getData(true);
 ck(!$r['data']['can_apply'] && !$r['data']['can_broadcast'],'Minor cannot apply or host');
 $pages=new App\Http\Controllers\PagesController();DB::table('pages')->delete();
 ck($pages->privacypolicy(Request::create('/'))->getStatusCode()===200,'Unpublished privacy page renders without exception');
 ck(str_contains($pages->termsOfUse(Request::create('/'))->getContent(),'not been published'),'Missing terms are disclosed instead of fabricated');
 $p=new Pages();$p->slug='privacy-policy';$p->title='Privacy';$p->is_active=true;$p->content='<h2>Orange privacy</h2><script>alert(1)</script><p onclick="alert(1)">Read</p><a href="javascript:alert(1)">bad</a><a href="https://ketua.sanaa.co/">good</a>';$p->save();
 $r=$pages->privacypolicy(Request::create('/'));$html=$r->getContent();
 ck(str_contains($html,'KETUA privacy')&&!str_contains($html,'Orange'),'Published reader uses KETUA branding');
 ck(!str_contains($html,'<script')&&!str_contains($html,'onclick')&&!str_contains($html,'javascript:'),'Policy reader strips active injected content');
 ck(str_contains($html,'https://ketua.sanaa.co/'),'Safe policy links remain readable');
 ck(str_contains($r->headers->get('Content-Security-Policy'),"default-src 'none'"),'Policy reader has restrictive browser policy');
 $pages->updateTerms(Request::create('/','POST',['content'=>'<h2>KETUA test terms</h2>']));
 ck(DB::table('pages')->where('slug','terms-of-use')->where('is_active',1)->exists(),'Admin can create missing canonical terms page');
 ck(str_contains($pages->termsOfUse(Request::create('/'))->getContent(),'KETUA test terms'),'Published canonical terms render correctly');
 $pages->updatePrivacy(Request::create('/','POST',['content'=>'<p>Updated privacy fixture</p>']));
 ck(DB::table('pages')->where('slug','privacy-policy')->count()===1,'Admin edits update the same canonical page');
 config(['ketua.live_enabled'=>true,'ketua.agora_app_id'=>str_repeat('0',32),'ketua.agora_app_certificate'=>str_repeat('1',32)]);
 $setting=new App\Http\Controllers\SettingController();
 ck($setting->generateAgoraToken(Request::create('/','POST',['channelName'=>$me->identity]))->getStatusCode()===403,'Unapproved minor cannot mint publisher token');
 $me->dob='1995-01-01';$me->can_go_live=2;$me->save();auth('app_users')->setUser(App\Models\User::findOrFail($me->id));
 ck($setting->generateAgoraToken(Request::create('/','POST',['channelName'=>'someone_else']))->getStatusCode()===403,'Approved host cannot mint another channel publisher token');
 $me->can_go_live=0;$me->save();auth('app_users')->setUser(App\Models\User::findOrFail($me->id));
 $fixture='/tmp/ketua-live-application-check.mp4';
 if(!is_file($fixture))throw new RuntimeException('Media fixture is required');
 $applicationRequest=Request::create('/','POST',['user_id'=>999999,'about_you'=>'Isolated test application','languages'=>'English','social_links'=>'https://example.test/qa']);
 $applicationRequest->files->set('intro_video',new Illuminate\Http\UploadedFile($fixture,'intro.mp4','video/mp4',null,true));
 $r=$controller->applyForLive($applicationRequest);
 ck($r->getData(true)['status']===true,'Valid intro application submitted');
 $application=DB::table('live_application')->where('user_id',$me->id)->first();$applicationPath=$application?->intro_video;
 ck($application && !DB::table('live_application')->where('user_id',999999)->exists(),'Application ignores supplied owner ID');
 ck((int)DB::table('users')->where('id',$me->id)->value('can_go_live')===1,'Pending eligibility changes only after saved application');
 ck($controller->applyForLive($applicationRequest)->getStatusCode()===409,'Duplicate application cannot create duplicate media or rows');
 echo "RESULT: $n/$n native readiness checks passed\n";
}finally{if($applicationPath) App\Models\GlobalFunction::deleteFile($applicationPath);DB::rollBack();auth('app_users')->forgetUser();}
