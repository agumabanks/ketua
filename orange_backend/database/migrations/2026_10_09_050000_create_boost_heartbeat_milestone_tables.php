<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mission features: Boosts, Heartbeat (presence), and consistency milestones.
 *   - user_boosts: paid profile-boost windows (visibility spike).
 *   - user_heartbeats: lightweight presence pings (last-seen / active-now).
 *   - user_milestones: awarded consistency milestones (e.g. 3/5-day streaks).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('user_boosts')) {
            Schema::create('user_boosts', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('coin_price')->default(0);
                $table->timestamp('started_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();
                $table->index(['user_id']);
                $table->index(['expires_at']);
            });
        }

        if (!Schema::hasTable('user_heartbeats')) {
            Schema::create('user_heartbeats', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->unique();
                $table->timestamp('last_seen_at')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('user_milestones')) {
            Schema::create('user_milestones', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->integer('streak_days');          // 3 or 5
                $table->timestamp('achieved_at')->nullable();
                $table->timestamps();
                $table->index(['user_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_boosts');
        Schema::dropIfExists('user_heartbeats');
        Schema::dropIfExists('user_milestones');
    }
};
