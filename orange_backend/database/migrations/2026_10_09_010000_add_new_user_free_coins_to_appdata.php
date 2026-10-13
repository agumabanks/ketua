<?php

namespace App\Http\Migrations;

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

/**
 * Feature-repair migration: the application code references
 * `appdata.new_user_free_coins` (UsersController@addUserDetails) and
 * `appdata.new_user_free_coins` was never added to the deployed schema, which
 * crashes registration with "Unknown column". Back-fill it safely.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('appdata', 'new_user_free_coins')) {
            Schema::table('appdata', function (Blueprint $table) {
                $table->integer('new_user_free_coins')->default(0)->after('coin_rate');
            });
        }

        // Sanction safety: ensure the single appdata row exists.
        if (DB::table('appdata')->count() === 0) {
            DB::table('appdata')->insert([
                'app_name' => 'Ketua',
                'currency' => 'USD',
                'coin_rate' => 0.01,
                'min_threshold' => 0.00,
                'new_user_free_coins' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('appdata', 'new_user_free_coins')) {
            Schema::table('appdata', function (Blueprint $table) {
                $table->dropColumn('new_user_free_coins');
            });
        }
    }
};
