<?php
require '/var/www/ketua.sanaa.co/orange_backend/vendor/autoload.php';
$app=require '/var/www/ketua.sanaa.co/orange_backend/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;
if (config('database.connections.mysql.database') !== 'ketua') throw new RuntimeException('Unexpected database');
DB::transaction(function () {
 foreach (['interests'=>['Music','Reading','Food','Travel','Sport','Creative projects'], 'languages'=>['English','French','Swahili'], 'religions'=>['Prefer not to say','Christianity','Islam','Other']] as $table=>$titles) {
  if (DB::table($table)->count()===0) foreach($titles as $title) DB::table($table)->insert(['title'=>$title,'created_at'=>now(),'updated_at'=>now()]);
 }
 if (DB::table('relationship_goals')->count()===0) foreach (['Long-term partner','Serious commitment','New friends','Still exploring'] as $title) DB::table('relationship_goals')->insert(['title'=>$title,'description'=>'Connect with people who share this goal.','created_at'=>now(),'updated_at'=>now()]);
 $manifest=json_decode(file_get_contents('/var/backups/ketua/codex-20261010/device-qa-manifest.json'),true);
 $ids=array_merge([$manifest['owner_id']],$manifest['qa_user_ids']);
 DB::table('users')->whereIn('id',$ids)->update(['interests'=>DB::table('interests')->limit(3)->pluck('id')->implode(','), 'relationship_goal_id'=>DB::table('relationship_goals')->value('id'), 'religion_key'=>'Prefer not to say', 'language_keys'=>'English']);
});
echo 'Empty onboarding catalogs populated; existing catalog content preserved.'.PHP_EOL;
