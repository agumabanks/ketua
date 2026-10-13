<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mission feature: short video (vertical video feed).
 *
 * Stores short video posts. Distinct from `posts` (the social feed) so the short
 * video surface has its own media type, duration, and like/comment counters.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('short_videos')) {
            Schema::create('short_videos', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('video');            // path or URL to the mp4
                $table->string('thumbnail')->nullable();
                $table->text('caption')->nullable();
                $table->string('sound')->nullable();
                $table->integer('duration_sec')->default(0);
                $table->unsignedBigInteger('likes_count')->default(0);
                $table->unsignedBigInteger('comments_count')->default(0);
                $table->unsignedBigInteger('shares_count')->default(0);
                $table->unsignedBigInteger('views_count')->default(0);
                $table->string('hashtags')->nullable();
                $table->timestamps();

                $table->index(['user_id']);
            });
        }

        if (!Schema::hasTable('short_video_likes')) {
            Schema::create('short_video_likes', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->unsignedBigInteger('short_video_id');
                $table->timestamps();
                $table->unique(['user_id', 'short_video_id']);
            });
        }

        if (!Schema::hasTable('short_video_views')) {
            Schema::create('short_video_views', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->nullable(); // anonymous views allowed
                $table->unsignedBigInteger('short_video_id');
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('short_video_views');
        Schema::dropIfExists('short_video_likes');
        Schema::dropIfExists('short_videos');
    }
};
