<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Schema-drift fix: application code (UsersController: onOffAnonymous toggle,
 * fetchUsersByCordinates, searchUsers, filteredProfiles) references an
 * `anonymous` column on `users` that was never migrated, causing
 * "Unknown column 'anonymous'" 500s. Back-fill it. Idempotent.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('users', 'anonymous')) {
            Schema::table('users', function (Blueprint $table) {
                $table->integer('anonymous')->default(0)->after('show_on_map');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'anonymous')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('anonymous');
            });
        }
    }
};
