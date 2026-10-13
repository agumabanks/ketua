<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mission feature: gifting. Records every gift sent between users so the
 * economy is auditable and payouts can be reconciled. The `gifts` table is
 * the catalog (title/image/price); this table is the ledger of sends.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('gift_transactions')) {
            Schema::create('gift_transactions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('sender_id');
                $table->unsignedBigInteger('receiver_id');
                $table->unsignedBigInteger('gift_id');
                $table->string('coin_price');
                $table->string('context')->nullable(); // e.g. 'live', 'chat', 'profile'
                $table->timestamps();

                $table->index(['sender_id']);
                $table->index(['receiver_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('gift_transactions');
    }
};
