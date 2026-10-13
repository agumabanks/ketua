<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up():void {
  Schema::create('earner_accounts',function(Blueprint $t){$t->unsignedBigInteger('user_id')->primary();$t->string('status',20)->default('pending');$t->string('note',500)->nullable();$t->timestamps();});
  Schema::create('earning_withdrawals',function(Blueprint $t){$t->uuid('id')->primary();$t->unsignedBigInteger('user_id')->index();$t->uuid('request_key');$t->string('currency_code',3);$t->unsignedBigInteger('amount_minor');$t->string('method',20);$t->text('destination');$t->string('status',20)->default('requested');$t->string('review_note',500)->nullable();$t->string('payment_reference',120)->nullable()->unique();$t->timestamp('paid_at')->nullable();$t->timestamps();$t->unique(['user_id','request_key']);});
  Schema::create('withdrawal_events',function(Blueprint $t){$t->id();$t->uuid('withdrawal_id')->index();$t->string('action',20);$t->string('actor',120);$t->string('note',500)->nullable();$t->timestamp('created_at');});
  Schema::table('creator_sales',function(Blueprint $t){$t->uuid('withdrawal_id')->nullable()->index();});
  Schema::create('qa_coin_credits',function(Blueprint $t){$t->uuid('id')->primary();$t->unsignedBigInteger('user_id')->index();$t->unsignedInteger('coins');$t->string('reason',200);$t->timestamp('created_at');});
  Schema::table('users',function(Blueprint $t){$t->boolean('qa_coin_mode')->default(false);});
 }
 public function down():void {Schema::table('users',fn(Blueprint $t)=>$t->dropColumn('qa_coin_mode'));Schema::table('creator_sales',fn(Blueprint $t)=>$t->dropColumn('withdrawal_id'));foreach(['qa_coin_credits','withdrawal_events','earning_withdrawals','earner_accounts'] as $n)Schema::dropIfExists($n);}
};
