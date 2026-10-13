<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(): void {
  Schema::table('gifts', function(Blueprint $t) { $t->string('name',80)->nullable(); });
  Schema::create('experiences',function(Blueprint $t){
   $t->id();$t->string('title',120);$t->string('category',20);$t->text('description');$t->string('venue',160);$t->timestamp('starts_at');$t->timestamp('ends_at');$t->string('currency_code',3);$t->unsignedBigInteger('amount_minor');$t->unsignedInteger('capacity');$t->boolean('published')->default(false);$t->boolean('is_demo')->default(false);$t->timestamps();$t->index(['published','starts_at']);
  });
  Schema::create('experience_tickets',function(Blueprint $t){
   $t->id();$t->unsignedBigInteger('experience_id');$t->unsignedBigInteger('user_id');$t->uuid('ticket_code')->unique();$t->string('status',20)->default('confirmed');$t->timestamps();$t->unique(['experience_id','user_id']);
  });
 }
 public function down(): void { Schema::dropIfExists('experience_tickets');Schema::dropIfExists('experiences');Schema::table('gifts',fn(Blueprint $t)=>$t->dropColumn('name')); }
};
