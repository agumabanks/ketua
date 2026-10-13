<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('currencies', function (Blueprint $t) {
            $t->string('code', 3)->primary();
            $t->string('name', 80);
            $t->unsignedTinyInteger('decimals');
            $t->boolean('enabled')->default(true);
            $t->boolean('is_default')->default(false);
            $t->timestamps();
        });
        Schema::create('membership_plans', function (Blueprint $t) {
            $t->string('code', 20)->primary();
            $t->string('name', 80);
            $t->json('features');
            $t->boolean('enabled')->default(true);
            $t->string('store_product_id', 150)->nullable();
            $t->timestamps();
        });
        Schema::create('membership_prices', function (Blueprint $t) {
            $t->id();
            $t->string('plan_code', 20);
            $t->string('currency_code', 3);
            $t->unsignedBigInteger('amount_minor')->nullable();
            $t->unsignedInteger('period_days')->default(30);
            $t->unique(['plan_code', 'currency_code', 'period_days']);
            $t->foreign('plan_code')->references('code')->on('membership_plans');
            $t->foreign('currency_code')->references('code')->on('currencies');
        });
        $now = now();
        DB::table('currencies')->insert([
            ['code'=>'UGX','name'=>'Ugandan shilling','decimals'=>0,'enabled'=>true,'is_default'=>true,'created_at'=>$now,'updated_at'=>$now],
            ['code'=>'USD','name'=>'US dollar','decimals'=>2,'enabled'=>true,'is_default'=>false,'created_at'=>$now,'updated_at'=>$now],
        ]);
        foreach (['free'=>'Free', 'gold'=>'Gold', 'pro'=>'Pro'] as $code=>$name) {
            DB::table('membership_plans')->insert(['code'=>$code,'name'=>$name,
                'features'=>json_encode($code === 'free' ? ['matching','chat','report_block'] : ['matching','chat','report_block','see_likes']),
                'enabled'=>true,'created_at'=>$now,'updated_at'=>$now]);
            foreach (['UGX','USD'] as $currency) {
                DB::table('membership_prices')->insert(['plan_code'=>$code,'currency_code'=>$currency,
                    'amount_minor'=>$code === 'free' ? 0 : ($code === 'gold' && $currency === 'UGX' ? 37000 : null), 'period_days'=>30]);
            }
        }
    }
    public function down(): void
    {
        Schema::dropIfExists('membership_prices');
        Schema::dropIfExists('membership_plans');
        Schema::dropIfExists('currencies');
    }
};
