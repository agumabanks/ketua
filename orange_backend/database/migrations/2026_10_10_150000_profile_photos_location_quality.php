<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(): void { Schema::table('images',function(Blueprint $t){$t->unsignedInteger('sort_order')->default(0);});Schema::table('users',function(Blueprint $t){$t->timestamp('location_updated_at')->nullable();$t->float('location_accuracy_m')->nullable();}); }
 public function down(): void {Schema::table('images',fn(Blueprint $t)=>$t->dropColumn('sort_order'));Schema::table('users',fn(Blueprint $t)=>$t->dropColumn(['location_updated_at','location_accuracy_m']));}
};
