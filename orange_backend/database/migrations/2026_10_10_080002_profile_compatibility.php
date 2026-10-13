<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
return new class extends Migration {
 public function up() {
  foreach (['interests', 'blocked_users', 'likedprofile'] as $field) {
   if (!Schema::hasColumn('users', $field)) Schema::table('users', function (Blueprint $table) use ($field) { $table->longText($field)->nullable(); });
  }
  if (Schema::hasColumn('users', 'interest_id')) DB::table('users')->whereNull('interests')->whereNotNull('interest_id')->update(['interests' => DB::raw('interest_id')]);
 }
 public function down() { /* Preserve user preferences on rollback. */ }
};
