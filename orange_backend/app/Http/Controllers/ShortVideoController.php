<?php

namespace App\Http\Controllers;

use App\Models\ShortVideo;
use App\Models\UserActivityDay;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\Process\Process;

/**
 * Mission feature: short video.
 *
 * All endpoints derive the acting user from the bearer token. Uploads are
 * validated (extension, size). Like is idempotent (unique user_id+video_id).
 * Views are counted server-side. The actor is NEVER taken from the request body.
 */
class ShortVideoController extends Controller
{
    private function available(Users $me)
    {
        $blocked = array_filter(array_map('intval', explode(',', $me->blocked_users ?? '')));
        return ShortVideo::whereHas('user', function ($q) use ($me,$blocked) {
            $q->where('is_block',0)->where('anonymous',0)->whereNotIn('id',$blocked)
              ->whereRaw('NOT FIND_IN_SET(?, COALESCE(blocked_users, ?))', [$me->id,'']);
        });
    }

    /**
     * POST /api/shortVideo/feed  (auth) — paginated short-video feed.
     */
    public function feed(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $start = max(0, (int) ($request->input('start', 0)));
        $count = max(1, min((int) ($request->input('count', 10)), 50));

        $blocked = array_filter(array_map('intval', explode(',', $me->blocked_users ?? '')));

        $query = $this->available($me)->with('user.images')
            ->orderByDesc('created_at')
            ->offset($start)
            ->limit($count);

        $videos = $query->get();

        $likedIds = DB::table('short_video_likes')
            ->where('user_id', $me->id)
            ->whereIn('short_video_id', $videos->pluck('id'))
            ->pluck('short_video_id')
            ->all();

        $videos->each(function ($v) use ($likedIds) {
            $v->is_liked = in_array($v->id, $likedIds);
            // Never serialize the entire account into a public video card.
            $owner = $v->user;
            $v->setRelation('user', collect($owner->only(['id','fullname','username','bio','is_verified','images'])));
        });

        return response()->json([
            'status' => true,
            'message' => 'Short videos fetched successfully.',
            'data' => $videos,
        ]);
    }

    /**
     * POST /api/shortVideo/create  (auth) — create a short video post.
     * Accepts multipart video + optional thumbnail + caption + hashtags.
     */
    public function create(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $validator = Validator::make($request->all(), [
            'caption' => 'nullable|string|max:2200',
            'hashtags' => 'nullable|string|max:500',
            'duration_sec' => 'nullable|integer|min:1|max:600',
            'video' => 'required|file|mimetypes:video/mp4,video/quicktime,video/webm,video/x-msvideo|max:51200',
            'thumbnail' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        // Validate the actual media, not a client-supplied duration.
        $videoFile = $request->file('video');
        if ($videoFile == null) {
            return response()->json(['status' => false, 'message' => 'Video file is required.'], 422);
        }
        if (!$videoFile->isValid()) {
            return response()->json(['status' => false, 'message' => 'Video upload failed.'], 422);
        }

        $allowed = ['mp4', 'mov', 'webm'];
        $ext = strtolower($videoFile->getClientOriginalExtension() ?? $videoFile->extension());
        if (!in_array($ext, $allowed, true)) {
            return response()->json(['status' => false, 'message' => 'Video type not allowed. Allowed: ' . implode(', ', $allowed)], 422);
        }
        if ($videoFile->getSize() > 50 * 1024 * 1024) {
            return response()->json(['status' => false, 'message' => 'Video exceeds the 50MB limit.'], 422);
        }

        try {
            $probe = new Process(['/usr/bin/ffprobe', '-v', 'error', '-show_entries', 'format=duration:stream=codec_type', '-of', 'json', $videoFile->getRealPath()]);
            $probe->setTimeout(15);
            $probe->mustRun();
            $metadata = json_decode($probe->getOutput(), true);
            $duration = (float) ($metadata['format']['duration'] ?? 0);
            $hasVideo = in_array('video', array_column($metadata['streams'] ?? [], 'codec_type'), true);
            if (!$hasVideo || !is_finite($duration) || $duration < 1 || $duration > 600) {
                return response()->json(['status'=>false,'message'=>'Choose a playable video between 1 second and 10 minutes.'], 422);
            }
        } catch (\Throwable $e) {
            return response()->json(['status'=>false,'message'=>'Video could not be validated. Choose another video.'], 422);
        }

        $path = $videoFile->storeAs('short_videos', time() . '_' . bin2hex(random_bytes(8)) . '.' . $ext, 'public');

        $thumbnail = null;
        if ($request->hasFile('thumbnail')) {
            $thumb = $request->file('thumbnail');
            $tExt = strtolower($thumb->getClientOriginalExtension());
            if (in_array($tExt, ['jpg', 'jpeg', 'png', 'webp'], true)) {
                $thumbnail = $thumb->storeAs('short_videos/thumbs', time() . '_' . bin2hex(random_bytes(6)) . '.' . $tExt, 'public');
            }
        }

        $video = ShortVideo::create([
            'user_id' => $me->id,
            'video' => $path,
            'thumbnail' => $thumbnail,
            'caption' => $request->input('caption'),
            'hashtags' => $request->input('hashtags'),
            'duration_sec' => (int) ceil($duration),
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Short video created successfully.',
            'data' => $video,
        ]);
    }

    /**
     * POST /api/shortVideo/like  (auth) — toggle like (idempotent).
     */
    public function like(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), ['short_video_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $video = $this->available($me)->find($request->short_video_id);
        if ($video == null) {
            return response()->json(['status' => false, 'message' => 'Short video not found.']);
        }

        return DB::transaction(function () use ($me,$video) {
        $video = ShortVideo::whereKey($video->id)->lockForUpdate()->firstOrFail();
        $existing = DB::table('short_video_likes')
            ->where('user_id', $me->id)
            ->where('short_video_id', $video->id)
            ->first();

        if ($existing) {
            DB::table('short_video_likes')
                ->where('user_id', $me->id)
                ->where('short_video_id', $video->id)
                ->delete();
            $video->likes_count = max(0, (int) $video->likes_count - 1);
            $video->save();
            return response()->json(['status' => true, 'message' => 'Unliked.', 'likes_count' => $video->likes_count, 'is_liked' => false]);
        }

        DB::table('short_video_likes')->insert([
            'user_id' => $me->id,
            'short_video_id' => $video->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $video->likes_count = (int) $video->likes_count + 1;
        $video->save();

        return response()->json(['status' => true, 'message' => 'Liked.', 'likes_count' => $video->likes_count, 'is_liked' => true]);
        });
    }

    /**
     * POST /api/shortVideo/view  (auth) — record a view. Idempotent per (user, video, day).
     */
    public function view(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), ['short_video_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $video = $this->available($me)->find($request->short_video_id);
        if ($video == null) {
            return response()->json(['status' => false, 'message' => 'Short video not found.']);
        }

        return DB::transaction(function () use ($me,$video) {
        $video = ShortVideo::whereKey($video->id)->lockForUpdate()->firstOrFail();
        $today = now('UTC')->toDateString();
        $exists = DB::table('short_video_views')
            ->where('user_id', $me->id)
            ->where('short_video_id', $video->id)
            ->whereDate('created_at', $today)
            ->exists();

        if (!$exists) {
            DB::table('short_video_views')->insert([
                'user_id' => $me->id,
                'short_video_id' => $video->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $video->views_count = (int) $video->views_count + 1;
            $video->save();
        }

        return response()->json(['status' => true, 'message' => 'View recorded.', 'views_count' => $video->views_count]);
        });
    }

    /**
     * POST /api/shortVideo/share  (auth) — record a share.
     */
    public function share(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), ['short_video_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $video = $this->available($me)->find($request->short_video_id);
        if ($video == null) {
            return response()->json(['status' => false, 'message' => 'Short video not found.']);
        }

        $video->increment('shares_count');

        return response()->json(['status' => true, 'message' => 'Share recorded.', 'shares_count' => $video->shares_count]);
    }

    /**
     * POST /api/shortVideo/delete  (auth) — delete own short video.
     */
    public function delete(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), ['short_video_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $video = ShortVideo::where('id', $request->short_video_id)->where('user_id', $me->id)->first();
        if ($video == null) {
            return response()->json(['status' => false, 'message' => 'Short video not found or not yours.']);
        }

        $paths = [$video->video, $video->thumbnail];
        $video->delete();
        foreach ($paths as $path) {
            if ($path && str_starts_with($path, 'short_videos/') && !str_contains($path, '..')) {
                Storage::disk('public')->delete($path);
            }
        }

        return response()->json(['status' => true, 'message' => 'Short video deleted.']);
    }
}
