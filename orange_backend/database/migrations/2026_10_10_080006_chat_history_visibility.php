<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void {
        foreach (['cleared_through_a','cleared_through_b'] as $column) {
            if (!Schema::hasColumn('conversations', $column)) {
                Schema::table('conversations', fn (Blueprint $table) => $table->unsignedBigInteger($column)->default(0));
            }
        }
    }
    public function down(): void {
        // Preserve each participant's clear boundary when rolling back code.
    }
};
