<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mission feature: swipe-up "Stars" (a premium super-like). Adds a nullable
 * `star` flag + star price snapshot to the like ledger so a star is
 * distinguishable from a plain like and is auditable.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('like_profiles', function (Blueprint $table) {
            if (!Schema::hasColumn('like_profiles', 'star')) {
                $table->boolean('star')->default(0)->after('my_user_id');
            }
            if (!Schema::hasColumn('like_profiles', 'star_price')) {
                $table->string('star_price')->nullable()->after('star');
            }
        });
    }

    public function down(): void
    {
        Schema::table('like_profiles', function (Blueprint $table) {
            if (Schema::hasColumn('like_profiles', 'star')) {
                $table->dropColumn('star');
            }
            if (Schema::hasColumn('like_profiles', 'star_price')) {
                $table->dropColumn('star_price');
            }
        });
    }
};
