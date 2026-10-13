<?php
require '/var/www/ketua-framework-20261010/vendor/autoload.php';
$a=require '/var/www/ketua-framework-20261010/bootstrap/app.php';$a->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
if(config('database.connections.mysql.database')!=='ketua_test')throw new RuntimeException('Isolated DB required');
$u=new App\Models\Users();$tag='delete-qa-'.bin2hex(random_bytes(6));$u->identity=$u->name=$u->username=$tag;$u->email=$tag.'@example.invalid';$u->password=Illuminate\Support\Facades\Hash::make(bin2hex(random_bytes(16)));$u->fullname='Delete QA';$u->device_token=null;$u->save();$id=$u->id;
try {
 $u->createToken('delete-test-one');$u->createToken('delete-test-two');
 auth('app_users')->setUser(App\Models\User::findOrFail($id));
 $r=(new App\Http\Controllers\UsersController())->deleteMyAccount(Illuminate\Http\Request::create('/api/deleteMyAccount','POST'));
 if(!$r->getData(true)['status'] || App\Models\Users::find($id))throw new RuntimeException('Delete failed');
 if(Illuminate\Support\Facades\DB::table('personal_access_tokens')->where('tokenable_id',$id)->where('tokenable_type',App\Models\Users::class)->exists())throw new RuntimeException('Tokens retained');
 echo "PASS: account deletion succeeds and revokes every session token\n";
}finally {Illuminate\Support\Facades\DB::table('personal_access_tokens')->where('tokenable_id',$id)->where('tokenable_type',App\Models\Users::class)->delete();App\Models\Users::where('id',$id)->delete();}
