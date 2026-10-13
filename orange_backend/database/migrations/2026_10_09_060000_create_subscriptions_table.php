<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mission feature: Gold plans + creator subscriptions (server-enforced).
 *
 * Subscription state lives on the server and is the source of truth for
 * entitlements. It is updated ONLY by verified store/provider events
 * (e.g. a RevenueCat webhook) — never by the client. Payment never grants the
 * identity-verified badge (separate concern).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('subscriptions')) {
            Schema::create('subscriptions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('plan')->default('gold');      // gold | creator
                $table->string('product_id')->nullable();      // store product id
                $table->string('status')->default('active');   // active | expired | cancelled
                $table->timestamp('started_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->string('provider')->nullable();        // revenuecat | apple | google
                $table->string('provider_txn_id')->nullable(); // idempotency key
                $table->timestamps();

                $table->unique(['provider', 'provider_txn_id']);
                $table->index(['user_id', 'status']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
