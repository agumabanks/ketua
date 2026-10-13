<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        // Older installations lack the flags consumed by the mobile navigation.
        foreach (['is_dating'=>1, 'is_social_media'=>1, 'post_description_limit'=>2200, 'post_upload_image_limit'=>6] as $column=>$default) {
            if (!Schema::hasColumn('appdata', $column)) {
                Schema::table('appdata', function (Blueprint $table) use ($column,$default) {
                    $table->unsignedInteger($column)->default($default);
                });
            }
        }
    }
    public function down(): void {
        // Compatibility fields can predate this migration; retain their data.
    }
};
