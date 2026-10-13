<?php
use Illuminate\Database\Migrations\Migration;use Illuminate\Support\Facades\DB;
return new class extends Migration {
 public function up(){foreach(['interests'=>['Music','Reading','Food','Travel','Movies','Football','Basketball','Fitness','Running','Cycling','Hiking','Swimming','Dancing','Photography','Art','Fashion','Cooking','Coffee','Gaming','Technology','Entrepreneurship','Volunteering','Gardening','Pets','Poetry','Live music','Comedy','Camping','Yoga','Wellness','Board games','Theatre','Afrobeats','Jazz','Gospel music','Beach days','Road trips','Language learning','Museums','Community events'], 'religions'=>['Prefer not to say','Christianity','Catholic','Anglican','Orthodox Christian','Pentecostal','Seventh-day Adventist','Baptist','Methodist','Islam','Sunni Muslim','Shia Muslim','Hinduism','Buddhism','Judaism','Sikhism','Baháʼí Faith','Traditional beliefs','Spiritual','Agnostic','Atheist','No religion','Other faith']] as $table=>$titles)foreach($titles as $title)if(!DB::table($table)->where('title',$title)->exists())DB::table($table)->insert(['title'=>$title,'created_at'=>now(),'updated_at'=>now()]);}
 // Retain catalog IDs that may already have been selected by members.
 public function down(){}
};
