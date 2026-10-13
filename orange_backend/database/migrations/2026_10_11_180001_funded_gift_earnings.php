<?php
use Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;use Illuminate\Support\Facades\DB;
return new class extends Migration {
 public function up():void {
 Schema::create('earning_policy',function(Blueprint $t){$t->unsignedInteger('id')->primary();$t->unsignedInteger('gift_creator_bps')->nullable();$t->unsignedInteger('content_creator_bps')->nullable();$t->boolean('withdrawals_enabled')->default(false);$t->timestamps();});DB::table('earning_policy')->insert(['id'=>1,'created_at'=>now(),'updated_at'=>now()]);
 Schema::create('coin_funding_lots',function(Blueprint $t){$t->id();$t->unsignedBigInteger('user_id')->index();$t->uuid('source_order');$t->string('currency_code',3);$t->unsignedInteger('coins_remaining');$t->unsignedBigInteger('value_remaining');$t->timestamps();$t->unique(['user_id','source_order']);});
 Schema::create('gift_cash_earnings',function(Blueprint $t){$t->id();$t->unsignedBigInteger('gift_transaction_id');$t->unsignedBigInteger('creator_id')->index();$t->uuid('source_order');$t->string('currency_code',3);$t->unsignedBigInteger('gross_minor');$t->unsignedBigInteger('net_minor')->nullable();$t->unsignedInteger('creator_bps')->nullable();$t->string('status',20)->default('pending_payout');$t->uuid('withdrawal_id')->nullable()->index();$t->timestamps();$t->unique(['gift_transaction_id','source_order']);});
 Schema::table('creator_sales',function(Blueprint $t){$t->unsignedBigInteger('net_minor')->nullable();$t->unsignedInteger('creator_bps')->nullable();});
 }
 public function down():void {Schema::table('creator_sales',fn(Blueprint $t)=>$t->dropColumn(['net_minor','creator_bps']));foreach(['gift_cash_earnings','coin_funding_lots','earning_policy'] as $n)Schema::dropIfExists($n);}
};
