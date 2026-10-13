<?php
require dirname(__DIR__).'/vendor/autoload.php';$app=require dirname(__DIR__).'/bootstrap/app.php';$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;
// Name existing artwork first. Seed catalog rows only, never user balances.
$names=['Rose','Spark','Heartbeat','Vibe','Crown','Galaxy'];$prices=[10,25,50,100,250,500];
$existing=DB::table('gifts')->orderBy('id')->get();
foreach($existing as $i=>$g)if(!$g->name)DB::table('gifts')->where('id',$g->id)->update(['name'=>$names[$i]??'Gift '.($i+1)]);
foreach($names as $i=>$name){
 if(!DB::table('gifts')->where('name',$name)->exists())DB::table('gifts')->insert(['name'=>$name,'title'=>$name,'price'=>$prices[$i],'image'=>'catalog/'.strtolower($name).'.png','created_at'=>now(),'updated_at'=>now()]);
}
foreach(DB::table('gifts')->whereIn('name',$names)->get() as $gift){
 if(!$gift->image || !is_file(storage_path('app/public/'.$gift->image)))DB::table('gifts')->where('id',$gift->id)->update(['image'=>'catalog/'.strtolower($gift->name).'.png']);
}
foreach([['Kampala Vibe Night','party',25000],['Meet & Connect Social','event',0],['Creator Spotlight Live','live',10000]] as [$title,$category,$price]){
 if(!DB::table('experiences')->where('title',$title)->where('is_demo',true)->exists())DB::table('experiences')->insert(['title'=>$title,'category'=>$category,'description'=>'Preview experience — a sample of what is coming to KETUA. This is not a scheduled public event.','venue'=>'Kampala · preview','starts_at'=>now()->addDays(14),'ends_at'=>now()->addDays(14)->addHours(3),'currency_code'=>'UGX','amount_minor'=>$price,'capacity'=>100,'published'=>true,'is_demo'=>true,'created_at'=>now(),'updated_at'=>now()]);
}
echo 'Gift catalog and clearly labelled experience previews seeded; no tickets or balances created.'.PHP_EOL;
