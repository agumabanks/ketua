<?php
use Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;
return new class extends Migration {public function up():void{Schema::table('super_like_packs',fn(Blueprint $t)=>$t->string('reward_type',12)->default('star'));}public function down():void{Schema::table('super_like_packs',fn(Blueprint $t)=>$t->dropColumn('reward_type'));}};
