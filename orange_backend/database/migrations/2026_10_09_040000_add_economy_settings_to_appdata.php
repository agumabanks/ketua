<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mission feature: swipe-up "Stars" + consistency milestones + boosts need a
 * few app-level price/threshold settings. Back-fill them onto appdata.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('appdata', function (Blueprint $table) {
            if (!Schema::hasColumn('appdata', 'star_price')) {
                $table->integer('star_price')->default(0)->after('new_user_free_coins');
            }
            if (!Schema::hasColumn('appdata', 'boost_price')) {
                $table->integer('boost_price')->default(0)->after('star_price');
            }
            if (!Schema::hasColumn('appdata', 'milestone_days')) {
                $table->integer('milestone_days')->default(3)->after('boost_price');
            }
        });
    }

    public function down(): void
    {
        Schema::table('appdata', function (Blueprint $table) {
            foreach (['star_price', 'boost_price', 'milestone_days'] as $col) {
                if (Schema::hasColumn('appdata', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
