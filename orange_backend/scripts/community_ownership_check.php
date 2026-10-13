<?php
require __DIR__.'/../vendor/autoload.php';$app=require __DIR__.'/../bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;use Illuminate\Http\Request;use App\Models\Users;use App\Http\Controllers\PostController;
if(config('database.connections.mysql.database')!=='ketua_test')throw new RuntimeException('Isolated database required');$n=0;function ck($v,$m){global $n;if(!$v)throw new RuntimeException('FAIL '.$m);$n++;echo "PASS $m\n";}
DB::beginTransaction();try{
function usr($name){$u=new Users;$u->fullname=$u->name=$name;$u->identity=$u->username=$name.bin2hex(random_bytes(5));$u->email=$u->identity.'@example.test';$u->password=bcrypt('isolated');$u->dob='1995-01-01';$u->is_block=0;$u->wallet=100;$u->save();return $u;}$a=usr('Actor');$b=usr('Owner');auth('app_users')->setUser(App\Models\Users::find($a->id));$c=new PostController;
$p=new App\Models\Post;$p->user_id=$b->id;$p->description='QA ownership';$p->comments_count=0;$p->likes_count=0;$p->save();
$r=$c->addComment(new Request(['user_id'=>$b->id,'post_id'=>$p->id,'description'=>'Authenticated actor']));ck($r->getData(true)['status'],'Comment can be created');$comment=DB::table('comments')->where('post_id',$p->id)->first();ck($comment->user_id===$a->id,'Forged comment actor replaced with authenticated user');
$notification=DB::table('user_notification')->where('user_id',$b->id)->first();ck($notification && $notification->item_id===$p->id,'Comment notification points to post');
$foreign=new App\Models\Comment;$foreign->user_id=$b->id;$foreign->post_id=$p->id;$foreign->description='Owner comment';$foreign->save();ck(!$c->deleteComment(new Request(['user_id'=>$b->id,'comment_id'=>$foreign->id]))->getData(true)['status']&&App\Models\Comment::find($foreign->id),'Forged user cannot delete another comment');
ck(!$c->deleteMyPost(new Request(['user_id'=>$b->id,'post_id'=>$p->id]))->getData(true)['status']&&App\Models\Post::find($p->id),'Forged user cannot delete another post');
ck($c->fetchPostByPostId(new Request(['user_id'=>$b->id,'post_id'=>999999999]))->getStatusCode()===404,'Missing post returns controlled unavailable response');
$route=collect(app('router')->getRoutes())->first(fn($r)=>$r->uri()==='api/deleteStoryFromWeb');ck(str_contains($route->getActionName(),'Closure'),'Public expired-story delete removed');
$uc=new \App\Http\Controllers\UsersController;$uc->updateSavedProfile(new Request(['user_id'=>$b->id,'profiles'=>(string)$b->id]));ck(Users::find($a->id)->savedprofile===(string)$b->id && !Users::find($b->id)->savedprofile,'Saved-profile change cannot overwrite another account');$uc->followUser(new Request(['my_user_id'=>$b->id,'user_id'=>$a->id]));ck(!\App\Models\FollowingList::where('my_user_id',$b->id)->exists(),'Follow cannot impersonate another account');
$own=$uc->getUserDetails(new Request(['email'=>$b->identity]))->getData(true)['data'];ck($own['id']===$a->id,'Email lookup cannot expose another private account');
$blocked=$uc->fetchBlockedProfiles(new Request(['user_id'=>$b->id]));
$follow=$uc->followUser(new Request(['my_user_id'=>$b->id,'user_id'=>$b->id]))->getData(true);ck($follow['status']&&!array_key_exists('wallet',$follow['data']['user'])&&!array_key_exists('identity',$follow['data']['user']),'Successful follow returns public fields only');
echo "RESULT $n/$n community ownership checks passed\n";
}finally{DB::rollBack();auth('app_users')->forgetUser();}
