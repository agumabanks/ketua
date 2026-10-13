<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Preserve DAILY activity history so consistency milestones (3/5-day streaks)
 * can be computed. The previous user_heartbeats table kept only the latest
 * ping per user (updateOrCreate on unique user_id), which destroyed history.
 * This table records one row per (user, activity-day) — idempotent on replay
 * within the same day — and is the source of truth for streaks.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('user_activity_days')) {
            Schema::create('user_activity_days', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->date('activity_date');           // server day (UTC) the user was active
                $table->timestamp('first_seen_at')->nullable();
                $table->timestamp('last_seen_at')->nullable();
                $table->timestamps();

                // One row per user per day: replays within a day update, never duplicate.
                $table->unique(['user_id', 'activity_date']);
                $table->index(['user_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_activity_days');
    }
};
