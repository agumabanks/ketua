<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('data_deletion_requests', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->string('username')->nullable();
            $table->string('full_name')->nullable();
            $table->string('request_type')->default('full_account'); // full_account | data_only
            $table->text('reason')->nullable();
            $table->string('status')->default('pending'); // pending | processing | completed | rejected
            $table->text('admin_notes')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();

            $table->index('email');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('data_deletion_requests');
    }
};
