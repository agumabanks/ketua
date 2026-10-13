<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void {
        Schema::create('subscription_events', function (Blueprint $t) {
            $t->string('event_id',128)->primary();
            $t->string('payload_hash',64);
            $t->unsignedBigInteger('event_timestamp_ms');
            $t->timestamp('created_at');
        });
        Schema::table('subscriptions', function (Blueprint $t) {
            $t->unsignedBigInteger('last_event_ms')->default(0);
        });
    }
    public function down(): void {
        Schema::dropIfExists('subscription_events');
        Schema::table('subscriptions', fn(Blueprint $t)=>$t->dropColumn('last_event_ms'));
    }
};
