<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(): void {
  if (!Schema::hasColumn('personal_access_tokens','expires_at')) {
   Schema::table('personal_access_tokens',fn (Blueprint $t) => $t->timestamp('expires_at')->nullable());
  }
 }
 public function down(): void { /* Retain backward-compatible metadata on rollback. */ }
};
