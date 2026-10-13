<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The stock Laravel `users` scaffold was deployed without the application's
 * columns. The admin dashboard (LoginController@index) and the users module
 * query fields that never existed on this database, causing HTTP 500 after
 * login ("Unknown column 'can_go_live'"). This migration back-fills the full
 * application schema for `users`. The table is empty, so this is non-destructive.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Identity / profile
            if (!Schema::hasColumn('users', 'identity'))      $table->string('identity')->nullable();
            if (!Schema::hasColumn('users', 'fullname'))      $table->string('fullname')->nullable();
            if (!Schema::hasColumn('users', 'username'))      $table->string('username')->nullable();
            if (!Schema::hasColumn('users', 'bio'))           $table->text('bio')->nullable();
            if (!Schema::hasColumn('users', 'about'))         $table->text('about')->nullable();
            if (!Schema::hasColumn('users', 'image'))         $table->longText('image')->nullable();
            if (!Schema::hasColumn('users', 'images'))        $table->longText('images')->nullable();
            if (!Schema::hasColumn('users', 'dob'))           $table->date('dob')->nullable();
            if (!Schema::hasColumn('users', 'gender'))        $table->string('gender')->nullable();

            // Location
            if (!Schema::hasColumn('users', 'country'))       $table->string('country')->nullable();
            if (!Schema::hasColumn('users', 'state'))         $table->string('state')->nullable();
            if (!Schema::hasColumn('users', 'city'))          $table->string('city')->nullable();
            if (!Schema::hasColumn('users', 'lat'))           $table->string('lat')->nullable();
            if (!Schema::hasColumn('users', 'lattitude'))     $table->string('lattitude')->nullable();
            if (!Schema::hasColumn('users', 'long'))          $table->string('long')->nullable();
            if (!Schema::hasColumn('users', 'longitude'))     $table->string('longitude')->nullable();
            if (!Schema::hasColumn('users', 'show_on_map'))   $table->integer('show_on_map')->default(0);
            if (!Schema::hasColumn('users', 'distance_preference')) $table->string('distance_preference')->nullable();

            // Preferences
            if (!Schema::hasColumn('users', 'age_preferred_min'))  $table->integer('age_preferred_min')->nullable();
            if (!Schema::hasColumn('users', 'age_preferred_max'))  $table->integer('age_preferred_max')->nullable();
            if (!Schema::hasColumn('users', 'gender_preferred'))   $table->string('gender_preferred')->nullable();
            if (!Schema::hasColumn('users', 'relationship_goal_id')) $table->integer('relationship_goal_id')->nullable();
            if (!Schema::hasColumn('users', 'religion_key'))       $table->string('religion_key')->nullable();
            if (!Schema::hasColumn('users', 'language_keys'))      $table->longText('language_keys')->nullable();
            if (!Schema::hasColumn('users', 'hidden_user_ids'))    $table->longText('hidden_user_ids')->nullable();
            if (!Schema::hasColumn('users', 'app_language'))       $table->string('app_language')->nullable();
            if (!Schema::hasColumn('users', 'interest_id'))        $table->longText('interest_id')->nullable();

            // Social
            if (!Schema::hasColumn('users', 'youtube'))       $table->string('youtube')->nullable();
            if (!Schema::hasColumn('users', 'facebook'))      $table->string('facebook')->nullable();
            if (!Schema::hasColumn('users', 'instagram'))     $table->string('instagram')->nullable();
            if (!Schema::hasColumn('users', 'following'))     $table->longText('following')->nullable();
            if (!Schema::hasColumn('users', 'followers'))     $table->longText('followers')->nullable();
            if (!Schema::hasColumn('users', 'savedprofile'))  $table->longText('savedprofile')->nullable();

            // Wallet / economy
            if (!Schema::hasColumn('users', 'coins'))         $table->bigInteger('coins')->default(0);
            if (!Schema::hasColumn('users', 'wallet'))        $table->string('wallet')->nullable();
            if (!Schema::hasColumn('users', 'total_collected')) $table->string('total_collected')->nullable();

            // Device / auth
            if (!Schema::hasColumn('users', 'device_token'))  $table->text('device_token')->nullable();
            if (!Schema::hasColumn('users', 'device_type'))   $table->string('device_type')->nullable();
            if (!Schema::hasColumn('users', 'login_type'))    $table->string('login_type')->nullable();

            // Status flags
            if (!Schema::hasColumn('users', 'is_verified'))   $table->integer('is_verified')->default(0);
            if (!Schema::hasColumn('users', 'is_fake'))       $table->integer('is_fake')->default(0);
            if (!Schema::hasColumn('users', 'is_block'))      $table->integer('is_block')->default(0);
            if (!Schema::hasColumn('users', 'is_notification')) $table->integer('is_notification')->default(1);
            if (!Schema::hasColumn('users', 'is_video_call')) $table->integer('is_video_call')->default(0);
            if (!Schema::hasColumn('users', 'is_like'))       $table->longText('is_like')->nullable();

            // Live streaming
            if (!Schema::hasColumn('users', 'can_go_live'))   $table->integer('can_go_live')->default(0);
            if (!Schema::hasColumn('users', 'is_live_now'))   $table->integer('is_live_now')->default(0);
            if (!Schema::hasColumn('users', 'total_streams')) $table->integer('total_streams')->default(0);
        });
    }

    public function down(): void
    {
        // Non-destructive scaffold: leave columns in place on rollback.
    }
};
