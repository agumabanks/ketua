<?php
use Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;
return new class extends Migration {public function up():void {Schema::table('user_notification',function(Blueprint $t){$t->string('message',1000)->nullable();});}public function down():void {Schema::table('user_notification',fn(Blueprint $t)=>$t->dropColumn('message'));}};
