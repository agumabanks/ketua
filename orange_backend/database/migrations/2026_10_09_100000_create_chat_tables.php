<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * F06 — Server-side chat. Replaces the Firestore-only client chat with
 * server-authoritative conversations and messages. All endpoints require
 * per-user bearer-token auth; the actor is derived from the token, never
 * from the request body.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('conversations')) {
            Schema::create('conversations', function (Blueprint $table) {
                $table->id();
                $table->string('conversation_id')->unique(); // sorted "id1_id2"
                $table->unsignedBigInteger('user_a');
                $table->unsignedBigInteger('user_b');
                $table->text('last_message')->nullable();
                $table->unsignedBigInteger('last_message_by')->nullable();
                $table->timestamp('last_message_at')->nullable();
                $table->boolean('blocked_by_a')->default(0);
                $table->boolean('blocked_by_b')->default(0);
                $table->boolean('muted_by_a')->default(0);
                $table->boolean('muted_by_b')->default(0);
                $table->timestamps();

                $table->index(['user_a']);
                $table->index(['user_b']);
            });
        }

        if (!Schema::hasTable('messages')) {
            Schema::create('messages', function (Blueprint $table) {
                $table->id();
                $table->string('conversation_id');
                $table->unsignedBigInteger('sender_id');
                $table->unsignedBigInteger('receiver_id');
                $table->text('body')->nullable();
                $table->string('message_type')->default('text'); // text/image/video
                $table->string('media')->nullable();            // stored file path
                $table->boolean('is_read')->default(0);
                $table->timestamp('read_at')->nullable();
                $table->boolean('is_deleted')->default(0);
                $table->timestamps();

                $table->index(['conversation_id', 'created_at']);
                $table->index(['sender_id']);
                $table->index(['receiver_id']);
            });
        }

        if (!Schema::hasTable('message_receipts')) {
            Schema::create('message_receipts', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('conversation_id');
                $table->unsignedBigInteger('last_read_message_id')->default(0);
                $table->timestamps();
                $table->unique(['user_id', 'conversation_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('message_receipts');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversations');
    }
};
