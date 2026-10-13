<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

use App\Models\AppData;
use App\Models\Comment;
use App\Models\Constants;
use App\Models\FollowingList;
use App\Models\GlobalFunction;
use App\Models\Images;
use App\Models\Interest;
use App\Models\Language;
use App\Models\Like;
use App\Models\LikedProfile;
use App\Models\LiveApplications;
use App\Models\LiveHistory;
use App\Models\Myfunction;
use App\Models\UserActivityDay;
use App\Models\Post;
use App\Models\PostContent;
use App\Models\RedeemRequest;
use App\Models\RelationshipGoal;
use App\Models\Religion;
use App\Models\Report;
use App\Models\Story;
use App\Models\User;
use App\Models\UserNotification;
use App\Models\Users;
use App\Models\VerifyRequest;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UsersController extends Controller
{
    function addCoinsToUserWalletFromAdmin(Request $request)
    {
        $result = Users::where('id', $request->id)->increment('wallet', $request->coins);
        if ($result) {
            $response['success'] = 1;
        } else {
            $response['success'] = 0;
        }
        echo json_encode($response);
    }

    function logOutUser(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        // Revoke the current bearer token and clear the device token.
        if ($me->currentAccessToken()) {
            $me->currentAccessToken()->delete();
        }
        $me->device_token = null;
        $me->save();

        return response()->json(['status' => true, 'message' => 'User logged out successfully !']);
    }

    function fetchUsersByCordinates(Request $request)
    {
        $rules = [
            'lat' => 'required',
            'long' => 'required',
            'km' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        // K13: require an authenticated caller; never expose other users' raw
        // coordinates. We return an approximate (rounded) distance instead.
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $users = Users::with('images')->where('is_block', 0)->where('is_fake', 0)->where('show_on_map', 1)->where('anonymous', 0)->where('id', '!=', $me->id)->get();

        $usersData = [];
        foreach ($users as $user) {
            $within = Myfunction::point2point_distance($request->lat, $request->long, $user->lattitude, $user->longitude, "K", $request->km);
            if ($within) {
                // Privacy-aware: compute an approximate km distance, round it,
                // and strip the raw coordinates from the payload.
                $approxKm = $this->approxDistanceKm($request->lat, $request->long, $user->lattitude, $user->longitude);
                $user->approximate_distance_km = $approxKm;
                $user->makeHidden(['lat', 'long', 'lattitude', 'longitude']);
                array_push($usersData, $user);
            }
        }
        return response()->json(['status' => true, 'message' => 'Data fetched successfully !', 'data' => $usersData]);
    }

    /**
     * K13: great-circle distance in km (haversine), rounded to 1 decimal for
     * privacy. Independent of the boolean point2point_distance helper.
     */
    private function approxDistanceKm($lat1, $lon1, $lat2, $lon2)
    {
        if ($lat1 === null || $lon1 === null || $lat2 === null || $lon2 === null) {
            return null;
        }
        $earth = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return round($earth * $c, 1);
    }

    function addUserImage(Request $req)
    {
        $req->validate(['id'=>'required|integer|exists:users,id','image'=>'required|image|max:10240']);
        return DB::transaction(function() use ($req) {
        $owner=Users::where('id',$req->id)->lockForUpdate()->firstOrFail();
        if(Images::where('user_id',$owner->id)->count()>=6)return response()->json(['status'=>false,'message'=>'A profile can have up to 6 photos.'],422);
        $img = new Images();
        $file = $req->file('image');
        $path = GlobalFunction::saveFileAndGivePath($file);
        $img->image = $path;
        $img->user_id = $req->id;
        $img->save();

        return json_encode([
            'status' => true,
            'message' => 'Image Added successfully!',
        ]);
        });
    }

    function deleteUserImage($imgId)
    {
        $img = Images::find($imgId);
        if ($img == null) {
            return json_encode([
                'status' => false,
                'message' => 'Image not found!',
            ]);
        }

        $imgCount = Images::where('user_id', $img->user_id)->count();
        if ($imgCount <= 1) {
            return json_encode([
                'status' => false,
                'message' => 'Minimum one image is required !',
            ]);
        }

        $safePath = basename($img->image);
        $fullPath = storage_path('app/public/' . $safePath);
        if (file_exists($fullPath) && strpos(realpath($fullPath), realpath(storage_path('app/public'))) === 0) {
            unlink($fullPath);
        }
        $img->delete();
        return json_encode([
            'status' => true,
            'message' => 'Image Deleted successfully!',
        ]);
    }

    function updateUser(Request $req)
    {
        // K04: hash any provided password (never store plaintext). This admin
        // route is protected by checkLogin session auth; the id is admin-supplied.
        $update = [
            "fullname" => $req->fullname,
            "bio" => $req->bio,
            "about" => $req->about,
            "instagram" => $req->instagram,
            "youtube" => $req->youtube,
            "facebook" => $req->facebook,
            "country" => $req->country,
            "state" => $req->state,
            "city" => $req->city,
        ];
        if ($req->filled('password')) {
            $update['password'] = Hash::make($req->password);
        }
        $result = Users::where('id', $req->id)->update($update);

        return json_encode([
            'status' => true,
            'message' => 'data updates successfully!',
        ]);
    }

    function addFakeUserFromAdmin(Request $request)
    {
        $user = new Users();
        $user->identity = Myfunction::generateFakeUserIdentity();
        $user->fullname = $request->fullname;
        $user->youtube = $request->youtube;
        $user->facebook = $request->facebook;
        $user->instagram = $request->instagram;
        $user->country = $request->country;
        $user->state = $request->state;
        $user->city = $request->city;
        $user->about = $request->about;
        $user->bio = $request->bio;
        $user->dob = \Carbon\Carbon::now()->subYears(rand(20, 40))->format('Y-m-d');
        $user->password = Hash::make($request->password);
        $user->gender = $request->gender;
        $user->is_verified = 2;
        $user->can_go_live = 2;
        $user->is_fake = 1;

        // Interests
        $interestIds = Interest::inRandomOrder()->limit(4)->pluck('id')->toArray();
        $user->interests = implode(',', $interestIds);

        // gender_preferred: random 1,2,3
        $user->gender_preferred = rand(1, 3);

        // relationship_goal_id: random existing id
        $user->relationship_goal_id = RelationshipGoal::inRandomOrder()->value('id');

        // religion_key: random existing key
        $user->religion_key = Religion::inRandomOrder()->value('title');

        // language_keys: random 2–4 existing keys
        $randomLangs = Language::inRandomOrder()->limit(rand(2, 4))->pluck('title')->toArray();
        $user->language_keys = implode(',', $randomLangs);

        $user->save();

        if ($request->hasFile('image')) {
            $files = $request->file('image');
            for ($i = 0; $i < count($files); $i++) {
                $image = new Images();
                $image->user_id = $user->id;
                $path = GlobalFunction::saveFileAndGivePath($files[$i]);
                $image->image = $path;
                $image->save();
            }
        }

        return response()->json(['status' => true, 'message' => "Fake user added successfully !"]);
    }

    public function getExplorePageProfileList(Request $request)
    {
        $rules = [
            'user_id' => 'required',
            'exclude_ids' => ['nullable', 'string', 'max:12000', 'regex:/^[0-9]+(?:,[0-9]+)*$/'],
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = auth('app_users')->user();
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'User not found!',
            ]);
        }

        $excludeIds = $request->filled('exclude_ids')
            ? array_unique(array_map('intval', explode(',', $request->exclude_ids))) : [];
        if (count($excludeIds) > 1000) return response()->json(['status'=>false,'message'=>'Too many excluded profiles.'], 422);
        $genderPreference = $user->gender_preferred;
        $ageMin = $user->age_preferred_min;
        $ageMax = $user->age_preferred_max;
        $blockedUsers = array_merge(explode(',', $user->blocked_users), [$user->id]);
        $hiddenUsers = array_merge(explode(',', $user->hidden_user_ids), [$user->id]);
        $likedUsers = LikedProfile::where('my_user_id', $user->id)->pluck('user_id')->toArray();

        $profilesQuery = Users::with('images')
            ->has('images')
            ->whereNotIn('id', $blockedUsers)
            ->whereNotIn('id', $excludeIds)
            ->whereNotIn('id', $hiddenUsers)
            ->where('is_block', 0)
            ->where('anonymous', 0)
            ->whereNotIn('id',function($q)use($user){$q->select('premium_usage.user_id')->from('premium_usage')->where('incognito',true)->whereIn('user_id',function($q){$q->select('user_id')->from('subscriptions')->whereIn('plan',['gold','pro'])->whereIn('status',['active','cancelled'])->where('expires_at','>',now());})->whereNotIn('user_id',function($q)use($user){$q->select('my_user_id')->from('like_profiles')->where('user_id',$user->id);});})
            ->whereRaw("NOT FIND_IN_SET(?, COALESCE(blocked_users, ''))", [$user->id])
            ->whereRaw("TIMESTAMPDIFF(YEAR, dob, CURDATE()) >= 18")
            ->when($genderPreference != 3, function ($query) use ($genderPreference) {
                $query->where('gender', $genderPreference == 1 ? 1 : 2);
            })
            ->whereRaw("TIMESTAMPDIFF(YEAR, dob, CURDATE()) BETWEEN ? AND ?", [$ageMin, $ageMax]);

        if(\App\Services\PremiumAccess::rules($user->id)->passport){$country=DB::table('premium_usage')->where('user_id',$user->id)->value('passport_country');if($country)$profilesQuery->where('country',$country);}
        $profiles = $profilesQuery->get()->each(function ($profile) use ($likedUsers) {
            $profile->is_like = in_array($profile->id, $likedUsers);
        });

        // F02: rank by a deterministic recommendation score instead of random.
        $scored = $this->scoreRecommendations($profiles, $user);

        return response()->json([
            'status' => true,
            'message' => 'Data found successfully!',
            'data' => $scored->map(fn ($profile) => $this->publicProfile($profile)),
        ]);
    }

    /**
     * F02 — ranked recommendations.
     *
     * Deterministic scoring (no client input): profile completeness, mutual
     * interest overlap, verification, photo count, and recent activity.
     * Returns the top $limit profiles sorted by score descending.
     */
    private function publicProfile(Users $user): array
    {
        $data = $user->only(['id','fullname','username','bio','about','gender','country','state','city','interests','relationship_goal_id','religion_key','language_keys','youtube','facebook','instagram','is_verified','is_like','images','recommend_score','followingStatus','stories','matched_interests','matched_languages','matched_relationship_goal_id','matched_religion','match_score']);
        $data['super_like_received']=auth('app_users')->user()?->id ? LikedProfile::where('my_user_id',$user->id)->where('user_id',auth('app_users')->user()?->id)->where('star',1)->exists() : false;
        $data['age'] = $user->dob ? Carbon::parse($user->dob)->age : null;
        $me = auth('app_users')->user();
        $data['distance_km'] = null;
        $data['distance_meters'] = null;
        if ($me && is_numeric($me->lattitude) && is_numeric($me->longitude) && is_numeric($user->lattitude) && is_numeric($user->longitude)) {
            $lat1 = deg2rad((float)$me->lattitude); $lat2 = deg2rad((float)$user->lattitude);
            $dlat = $lat2-$lat1; $dlon=deg2rad((float)$user->longitude-(float)$me->longitude);
            $a=sin($dlat/2)**2+cos($lat1)*cos($lat2)*sin($dlon/2)**2;
            $metres = 6371000*2*asin(sqrt(min(1,max(0,$a))));
            $data['distance_km'] = max(1, (int)round($metres/1000));
            // Distance is an approximate, bounded display; never disclose the target's coordinates.
            $fresh = $me->location_updated_at && $user->location_updated_at
                && Carbon::parse($me->location_updated_at)->gte(now()->subMinutes(15))
                && Carbon::parse($user->location_updated_at)->gte(now()->subMinutes(15));
            if ($fresh && $me->location_accuracy_m !== null && $user->location_accuracy_m !== null
                && $me->location_accuracy_m <= 100 && $user->location_accuracy_m <= 100) {
                $data['distance_meters'] = $metres < 1000 ? max(100,(int)round($metres/100)*100) : (int)round($metres/1000)*1000;
            }
        }
        if(\App\Services\PremiumAccess::plan($user->id)!=='free'){
            $privacy=DB::table('premium_usage')->where('user_id',$user->id)->first();
            if($privacy?->hide_age)$data['age']=null;
            if($privacy?->hide_distance){$data['distance_km']=null;$data['distance_meters']=null;}
        }
        return $data;
    }

    private function scoreRecommendations($profiles, $me, int $limit = 15)
    {
        $myInterests = array_filter(array_map('intval', explode(',', $me->getOriginal('interests') ?? '')));
        $activity = UserActivityDay::whereIn('user_id', $profiles->pluck('id'))
            ->orderByDesc('last_seen_at')
            ->get(['user_id', 'last_seen_at']);

        $boosted = \App\Models\UserBoost::active()->whereIn('user_id', $profiles->pluck('id'))->pluck('user_id')->all();
        $priority = \App\Models\Subscription::active()->where('plan','pro')->whereIn('user_id',$profiles->pluck('id'))->pluck('user_id')->all();
        $stars=LikedProfile::where('user_id',$me->id)->where('star',1)->pluck('my_user_id')->all();
        $scored = $profiles->map(function ($p) use ($myInterests, $activity, $boosted, $priority, $stars) {
            $score = in_array($p->id,$stars)?12:0;

            // Completeness: fullname + bio + about + dob + location + photo count.
            $score += (!empty($p->fullname) ? 1 : 0) * 2;
            $score += (!empty($p->bio) ? 1 : 0) * 2;
            $score += (!empty($p->about) ? 1 : 0);
            $score += (!empty($p->dob) ? 1 : 0);
            $score += (!empty($p->city) || !empty($p->country) ? 1 : 0);
            $score += min(count($p->images ?? []), 5); // up to 5

            // Mutual interest overlap.
            $theirInterests = array_filter(array_map('intval', explode(',', $p->getOriginal('interests') ?? '')));
            $overlap = count(array_intersect($myInterests, $theirInterests));
            $score += $overlap * 3;

            // Verified users rank higher.
            if ((int) $p->is_verified === 2) $score += 8;

            // Recent activity (within 7 days) boosts.
            $lastSeen = $activity->firstWhere('user_id', $p->id);
            if ($lastSeen && $lastSeen->last_seen_at && $lastSeen->last_seen_at->gt(now()->subDays(7))) {
                $score += 6;
            }

            if (in_array($p->id, $boosted)) $score += 20;
            // Modest Pro visibility signal after all privacy/preferences filters;
            // it never bypasses blocks or implies a guaranteed match.
            if (in_array($p->id, $priority)) $score += 4;
            $p->recommend_score = $score;
            return $p;
        });

        return $scored->sortByDesc('recommend_score')->values()->take($limit);
    }

    function getRandomProfile(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['user_id'=>auth('app_users')->user()->id]);
        $rules = [
            'user_id' => 'required',
            'gender' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->user_id)->first();
        if ($user == null) {
            return response()->json([
                'status' => false,
                'message' => 'User not found!',
            ]);
        }

        $blocked_users = explode(',', $user->blocked_users);
        array_push($blocked_users, $user->id);

        $hiddenUserArray = explode(',', $user->hidden_user_ids);
        array_push($hiddenUserArray, $user->id);

        if ($request->gender == 3) {
            $randomUser = Users::with('images')->has('images')->whereNotIn('id', $blocked_users)->whereNotIn('id', $hiddenUserArray)->where('is_block', 0)->whereDate('dob', '<=', now()->subYears(18)->toDateString())->whereRaw("NOT FIND_IN_SET(?, COALESCE(blocked_users, ''))", [$user->id])->whereNotIn('id',function($q)use($user){$q->select('premium_usage.user_id')->from('premium_usage')->where('incognito',true)->whereIn('user_id',function($q){$q->select('user_id')->from('subscriptions')->whereIn('plan',['gold','pro'])->whereIn('status',['active','cancelled'])->where('expires_at','>',now());})->whereNotIn('user_id',function($q)use($user){$q->select('my_user_id')->from('like_profiles')->where('user_id',$user->id);});})->inRandomOrder()->first();
        } else {
            $randomUser = Users::with('images')->has('images')->whereNotIn('id', $blocked_users)->whereNotIn('id', $hiddenUserArray)->where('is_block', 0)->where('gender', $request->gender)->whereDate('dob', '<=', now()->subYears(18)->toDateString())->whereRaw("NOT FIND_IN_SET(?, COALESCE(blocked_users, ''))", [$user->id])->whereNotIn('id',function($q)use($user){$q->select('premium_usage.user_id')->from('premium_usage')->where('incognito',true)->whereIn('user_id',function($q){$q->select('user_id')->from('subscriptions')->whereIn('plan',['gold','pro'])->whereIn('status',['active','cancelled'])->where('expires_at','>',now());})->whereNotIn('user_id',function($q)use($user){$q->select('my_user_id')->from('like_profiles')->where('user_id',$user->id);});})->inRandomOrder()->first();
        }

        if ($randomUser == null) {
            return response()->json([
                'status' => false,
                'message' => 'User not found!',
            ]);
        }

        return response()->json([
            'status' => true,
            'message' => 'data found successfully!',
            'data' => $this->publicProfile($randomUser),
        ]);
    }

    function updateUserBlockList(Request $request)
    {
        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $validator = Validator::make($request->all(), [
            'blocked_users'=>'present|nullable|string|max:10000|regex:/^(?:[1-9][0-9]*(?:,[1-9][0-9]*)*)?$/',
        ]);
        if ($validator->fails()) return response()->json(['status'=>false, 'message'=>'Invalid block list.'], 422);
        $ids = array_values(array_unique(array_filter(array_map('intval', explode(',', $request->blocked_users ?? '')),
            fn ($id) => $id > 0 && $id !== (int) $user->id)));
        if (count($ids) > 500) return response()->json(['status'=>false, 'message'=>'Too many blocked profiles.'], 422);
        \Illuminate\Support\Facades\DB::transaction(function () use ($user, $ids) {
            $conversations = \App\Models\Conversation::where(fn ($q) => $q->where('user_a',$user->id)->orWhere('user_b',$user->id))
                ->orderBy('id')->lockForUpdate()->get();
            $actor = Users::whereKey($user->id)->lockForUpdate()->firstOrFail();
            $actor->blocked_users = implode(',', $ids);
            $actor->save();
            foreach ($conversations as $conversation) {
                $column = $conversation->user_a == $user->id ? 'blocked_by_a' : 'blocked_by_b';
                $otherId = $conversation->user_a == $user->id ? $conversation->user_b : $conversation->user_a;
                $conversation->$column = in_array((int) $otherId, $ids, true);
                $conversation->save();
            }
        });

        $data = Users::with('images')->where('id', $user->id)->first();

        return response()->json(['status' => true, 'message' => "Blocklist updated successfully !", 'data' => $data]);
    }

    function deleteMyAccount(Request $request)
    {
        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $images = Images::where('user_id', $user->id)->get();
        foreach ($images as $image) {
            GlobalFunction::deleteFile($image->image);
            $image->delete();
        }

        $likes = Like::where('user_id', $user->id)->get();
        foreach ($likes as $like) {
            $postLikeCount = Post::where('id', $like->post_id)->first();
            if ($postLikeCount) {
                $postLikeCount->likes_count = max(0, $postLikeCount->likes_count - 1);
                $postLikeCount->save();
            }
            $like->delete();
        }
        $comments = Comment::where('user_id', $user->id)->get();
        foreach ($comments as $comment) {
            $postCommentCount = Post::where('id', $comment->post_id)->first();
            if ($postCommentCount) {
                $postCommentCount->comments_count = max(0, $postCommentCount->comments_count - 1);
                $postCommentCount->save();
            }
            $comment->delete();
        }

        $followerList = FollowingList::where('my_user_id', $user->id)->get();
        foreach ($followerList as $follower) {
            $followerUser = User::where('id', $follower->user_id)->first();
            if ($followerUser) {
                $followerUser->followers = max(0, $followerUser->followers - 1);
                $followerUser->save();
            }

            $follower->delete();
        }

        $followingList = FollowingList::where('user_id', $user->id)->get();
        foreach ($followingList as $following) {
            $followingUser = User::where('id', $following->user_id)->first();
            if ($followingUser) {
                $followingUser->following = max(0, $followingUser->following - 1);
                $followingUser->save();
            }

            $following->delete();
        }

        \App\Services\PremiumAccess::deleteProfile($user->id);
        if (\Illuminate\Support\Facades\Schema::hasTable('experience_tickets')) \Illuminate\Support\Facades\DB::table('experience_tickets')->where('user_id', $user->id)->delete();
        LikedProfile::where('my_user_id', $user->id)->delete();
        LikedProfile::where('user_id', $user->id)->delete();

        $liveApplication = LiveApplications::where('user_id', $user->id)->first();
        if ($liveApplication) {
            GlobalFunction::deleteFile($liveApplication->intro_video);
            $liveApplication->delete();
        }

        LiveHistory::where('user_id', $user->id)->delete();

        $posts = Post::where('user_id', $user->id)->get();
        foreach ($posts as $post) {
            $postContents = PostContent::where('post_id', $post->id)->get();
            foreach ($postContents as $postContent) {
                GlobalFunction::deleteFile($postContent->content);
                GlobalFunction::deleteFile($postContent->thumbnail);
                $postContent->delete();
            }

            Comment::where('post_id', $post->id)->delete();
            Like::where('post_id', $post->id)->delete();
            Report::where('post_id', $post->id)->delete();
            UserNotification::where('item_id', $post->id)->where('type', Constants::notificationTypeLike)->delete();

            $post->delete();
        }

        RedeemRequest::where('user_id', $user->id)->delete();
        Report::where('user_id', $user->id)->delete();

        $stories = Story::where('user_id', $user->id)->get();
        foreach ($stories as $story) {
            GlobalFunction::deleteFile($story->content);
            $story->delete();
        }

        UserNotification::where('user_id', $user->id)->delete();
        UserNotification::where('my_user_id', $user->id)->delete();

        $verificationRequest = VerifyRequest::where('user_id', $user->id)->first();
        if ($verificationRequest) {
            GlobalFunction::deleteFile($verificationRequest->document, 'local');
            GlobalFunction::deleteFile($verificationRequest->selfie, 'local');
            $verificationRequest->delete();
        }

        // Login tokens are issued by the legacy Users model; the request
        // guard resolves the same row as User. Revoke both morph types.
        Users::findOrFail($user->id)->tokens()->delete();
        $user->tokens()->delete();
        $user->delete();

        return response()->json(['status' => true, 'message' => "Account Deleted Successfully!"]);
    }

    function rejectVerificationRequest(Request $request)
    {
        $verifyRequest = VerifyRequest::where('id', $request->verification_id)->first();
        $verifyRequest->user->is_verified = 0;
        $verifyRequest->user->save();

        GlobalFunction::deleteFile($verifyRequest->document, 'local');
        GlobalFunction::deleteFile($verifyRequest->selfie, 'local');

        $verifyRequest->delete();

        return response()->json([
            'status' => true,
            'message' => 'Reject Verification Request',
        ]);
    }

    function approveVerificationRequest(Request $request)
    {
        $verifyRequest = VerifyRequest::where('id', $request->verification_id)->first();
        $verifyRequest->user->is_verified = 2;
        $verifyRequest->user->save();

        GlobalFunction::deleteFile($verifyRequest->document, 'local');
        GlobalFunction::deleteFile($verifyRequest->selfie, 'local');

        $verifyRequest->delete();

        return response()->json([
            'status' => true,
            'message' => 'Approve Verification Request',
        ]);
    }

    public function fetchverificationRequests(Request $request)
    {
        $totalData = VerifyRequest::count();
        $rows = VerifyRequest::orderBy('id', 'DESC')->get();

        $result = $rows;

        $columns = array(
            0 => 'id'
        );

        $limit = $request->input('length');
        $start = $request->input('start');
        $order = $columns[$request->input('order.0.column')];
        $dir = $request->input('order.0.dir');
        $totalData = VerifyRequest::count();
        $totalFiltered = $totalData;
        if (empty($request->input('search.value'))) {
            $result = VerifyRequest::offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
        } else {
            $search = $request->input('search.value');
            $result =  VerifyRequest::with('user')
                ->whereHas('user', function ($query) use ($search) {
                    $query->Where('fullname', 'LIKE', "%{$search}%")
                        ->orWhere('identity', 'LIKE', "%{$search}%");
                })
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
            $totalFiltered = VerifyRequest::with('user')
                ->whereHas('user', function ($query) use ($search) {
                    $query->Where('fullname', 'LIKE', "%{$search}%")
                        ->orWhere('identity', 'LIKE', "%{$search}%");
                })
                ->count();
        }
        $data = array();
        foreach ($result as $item) {

            $imgUrl = "http://placehold.jp/150x150.png"; // Default placeholder image URL

            if ($item->user->images->isNotEmpty() && $item->user->images[0]->image != null) {
                $imgUrl = asset('storage/' . $item->user->images[0]->image);
            }

            $image = '<img src="' . $imgUrl . '" width="50" height="50">';

            $selfieUrl = route('verificationMedia', ['id'=>$item->id,'kind'=>'selfie']);
            $selfie = '<img style="cursor: pointer;" class="img-preview" rel="' . $selfieUrl . '" src="' . $selfieUrl . '" width="50" height="50">';

            $docUrl = route('verificationMedia', ['id'=>$item->id,'kind'=>'document']);
            $document = '<img style="cursor: pointer;" class="img-preview" rel="' . $docUrl . '" src="' . $docUrl . '" width="50" height="50">';

            $approve = '<a href=""class=" btn btn-success text-white approve ml-2" rel=' . $item->id . ' >' . __("Approve") . '</a>';
            $reject = '<a href=""class=" btn btn-danger text-white reject ml-2" rel=' . $item->id . ' >' . __("Reject") . '</a>';

            $action = '<span class="float-end d-flex">' . $approve . $reject . ' </span>';

            $data[] = array(
                $image,
                $selfie,
                $document,
                e($item->document_type),
                e($item->fullname),
                $item->user->identity,
                $action
            );
        }
        $json_data = array(
            "draw"            => intval($request->input('draw')),
            "recordsTotal"    => intval($totalData),
            "recordsFiltered" => $totalFiltered,
            "data"            => $data
        );
        echo json_encode($json_data);
        exit();
    }

    public function verificationMedia(int $id, string $kind)
    {
        abort_unless(in_array($kind, ['document','selfie'], true), 404);
        $record = VerifyRequest::findOrFail($id);
        $path = $record->$kind;
        abort_unless(is_string($path) && preg_match('~^(?:verification|uploads)/[A-Za-z0-9_.-]+\.(?:jpg|jpeg|png|webp)$~', $path), 404);
        $disk = \Illuminate\Support\Facades\Storage::disk('local');
        abort_unless($disk->exists($path), 404);
        $root = realpath($disk->path(''));
        $file = realpath($disk->path($path));
        abort_unless($root && $file && str_starts_with($file, $root . DIRECTORY_SEPARATOR), 404);
        return response()->file($file, ['Cache-Control'=>'private, no-store', 'X-Content-Type-Options'=>'nosniff']);
    }

    function verificationrequests()
    {
        return view('verificationrequests');
    }

    function applyForVerification(Request $request)
    {
        $rules = [
            'document' => 'required|file|mimes:jpg,jpeg,png,webp|max:10240',
            'document_type' => 'required|string|max:50',
            'selfie' => 'required|file|mimes:jpg,jpeg,png,webp|max:10240',
            'fullname' => 'required|string|max:100',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        // Ownership: acting user comes from the bearer token, not client user_id.
        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        // is_verified semantics: 0 = none, 1 = PENDING admin review (set here),
        // 2 = VERIFIED (set ONLY by an admin approving the request). Submitting
        // a request never grants the verified badge (mission rule).
        if ($user->is_verified == 1) {
            return response()->json([
                'status' => false,
                'message' => 'The request has been submitted already!',
            ]);
        }
        if ($user->is_verified == 2) {
            return response()->json([
                'status' => false,
                'message' => 'This user is already verified !',
            ]);
        }

        $verifyReq = new VerifyRequest();
        $verifyReq->user_id = $user->id;
        $verifyReq->document_type = $request->document_type;
        $verifyReq->fullname = $request->fullname;
        $verifyReq->status = 0;

        try {
            $verifyReq->document = GlobalFunction::saveFileAndGivePath($request->file('document'), ['jpg','jpeg','png','webp'], 10*1024*1024, 'local', 'verification');
            $verifyReq->selfie = GlobalFunction::saveFileAndGivePath($request->file('selfie'), ['jpg','jpeg','png','webp'], 10*1024*1024, 'local', 'verification');
        } catch (\InvalidArgumentException | \RuntimeException $e) {
            GlobalFunction::deleteFile($verifyReq->document, 'local');
            return response()->json(['status'=>false, 'message'=>'Choose valid images up to 10 MB and 25 megapixels.'], 422);
        }

        $verifyReq->save();

        $user->is_verified = 1;
        $user->save();

        $user['images'] = Images::where('user_id', $user->id)->get();

        return response()->json([
            'status' => true,
            'message' => "Verification request submitted successfully !",
            'data' => $user
        ]);
    }

    public function likedProfile(Request $request)
    { return (new MatchController)->likeProfile($request); }

    public function dislikedProfile(Request $request)
    { return (new MatchController)->dislikeProfile($request); }

    function fetchBlockedProfiles(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['user_id'=>auth('app_users')->user()->id]);
        $rules = [
            'user_id' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->user_id)->first();

        if ($user == null) {
            return json_encode([
                'status' => false,
                'message' => 'user not found!',
            ]);
        }

        $array = explode(',', $user->blocked_users);
        $data = Users::whereIn('id', $array)->where('is_block', 0)->with('images')->has('images')->get();
        $data = $data->reverse()->values();

        return json_encode([
            'status' => true,
            'message' => 'blocked profiles fetched successfully!',
            'data' => $data->map(fn ($profile) => $this->publicProfile($profile))->values()
        ]);
    }

    function fetchLikedProfiles(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['user_id'=>auth('app_users')->user()->id]);
        $rules = [
            'user_id' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->user_id)->first();
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'user not found!',
            ]);
        }

        $likedProfiles = LikedProfile::where('my_user_id', $request->user_id)
            ->with('user')
            ->whereRelation('user', 'is_block', 0)
            ->has('user.images')
            ->with('user.images')
            ->orderBy('id', 'DESC')
            ->get()
            ->pluck('user');

        foreach ($likedProfiles as $likedProfile) {
            $likedProfile->is_like = true;
        }

        return response()->json([
            'status' => true,
            'message' => 'profiles fetched successfully!',
            'data' => $likedProfiles->map(fn ($profile) => $this->publicProfile($profile))->values()
        ]);
    }

    function fetchSavedProfiles(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['user_id'=>auth('app_users')->user()->id]);
        $rules = [
            'user_id' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->user_id)->first();
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'user not found!',
            ]);
        }

        $array = explode(',', $user->savedprofile);
        $blocked_users = explode(',', $user->blocked_users);
        $hidden_user_ids = explode(',', $user->hidden_user_ids);
        $data = Users::whereIn('id', $array)->whereNotIn('id', $blocked_users)->whereNotIn('id', $hidden_user_ids)->where('is_block', 0)->has('images')->with('images')->get();
        $data = $data->reverse()->values();

        return response()->json([
            'status' => true,
            'message' => 'Fetched Saved Profiles Successfully!',
            'data' => $data->map(fn ($profile) => $this->publicProfile($profile))->values()
        ]);
    }

    function allowLiveToUser(Request $request)
    {
        $user = Users::where('id', $request->user_id)->first();

        if ($user) {
            $user->can_go_live = 2;
            $user->save();

            return response()->json([
                'status' => true,
                'message' => "This user is allowed to go live.",
                'data' => $user,
            ]);
        } else {
            return response()->json([
                'status' => false,
                'message' => 'User not found',
            ]);
        }
    }

    function restrictLiveToUser(Request $request)
    {
        $user = Users::where('id', $request->user_id)->first();

        if ($user) {
            $user->can_go_live = 0;
            $user->save();

            return response()->json([
                'status' => true,
                'message' => "Restrict Live Access to User.",
                'data' => $user,
            ]);
        } else {
            return response()->json([
                'status' => false,
                'message' => 'User not found',
            ]);
        }
    }

    function increaseStreamCountOfUser(Request $request) {
        return response()->json(['status'=>false,'message'=>'Stream counts are provider-derived.'],409);
    }

    function minusCoinsFromWallet(Request $request) {
        return response()->json(['status'=>false,'message'=>'Use the feature-specific purchase flow. Direct wallet deductions are disabled.'],409);
    }

    function addCoinsToWallet(Request $request)
    {
        // K02: wallet credit is no longer a client-driven operation. Coins are
        // only ever added server-side by a verified purchase/gift/entitlement
        // flow. This endpoint now requires an authenticated caller and refuses
        // to mint coins from request params.
        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        return response()->json([
            'status'  => false,
            'message' => 'Direct wallet credit is disabled. Coins are granted only by verified purchases.',
        ], 403);
    }

    function updateLiveStatus(Request $request)
    {
        $rules = [
            'state' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $me->is_live_now = $request->state;
        $me->save();

        $data = Users::with('images')->has('images')->where('id', $me->id)->first();

        return json_encode([
            'status' => true,
            'message' => 'is_live_now state updated successfully',
            'data' => $data
        ]);
    }

    function onOffVideoCalls(Request $request)
    {
        $rules = [
            'state' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $user->is_video_call = $request->state;
        $user->save();

        $data = Users::with('images')->has('images')->where('id', $user->id)->first();

        return json_encode([
            'status' => true,
            'message' => 'is_video_call state updated successfully',
            'data' => $data
        ]);
    }

    function onOffAnonymous(Request $request)
    {
        $rules = [
            'state' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $user->anonymous = $request->state;
        $user->save();

        $data = Users::with('images')->has('images')->where('id', $user->id)->first();

        return json_encode([
            'status' => true,
            'message' => 'anonymous state updated successfully',
            'data' => $data
        ]);
    }

    function onOffShowMeOnMap(Request $request)
    {
        $rules = [
            'state' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $user->show_on_map = $request->state;
        $user->save();

        $data = Users::with('images')->has('images')->where('id', $user->id)->first();

        return json_encode([
            'status' => true,
            'message' => 'show_on_map state updated successfully',
            'data' => $data
        ]);
    }

    function onOffNotification(Request $request)
    {
        $rules = [
            'state' => 'required'
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = auth('app_users')->user();
        if ($user == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $user->is_notification = $request->state;
        $user->save();

        $data = Users::with('images')->has('images')->where('id', $user->id)->first();

        return json_encode([
            'status' => true,
            'message' => 'notification state updated successfully',
            'data' => $data
        ]);
    }

    function fetchAllUsers(Request $request)
    {
        $columns = [
            0 => 'id',
            1 => 'fullname'
        ];

        $limit = $request->input('length');
        $start = $request->input('start');
        $orderIndex = $request->input('order.0.column');
        $order = $columns[$orderIndex] ?? 'id';
        $dir = $request->input('order.0.dir', 'DESC');

        $search = $request->input('search.value');

        $query = Users::query();

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('fullname', 'LIKE', "%{$search}%")
                    ->orWhere('identity', 'LIKE', "%{$search}%");
            });
        }

        $totalData = Users::count();              // total without filter
        $totalFiltered = $query->count();         // total with filter

        // Fetch paginated data
        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy($order, $dir)
            ->get();

        $data = [];
        foreach ($result as $item) {
            $block = $item->is_block == 0
                ? '<a class="btn btn-danger text-white block" rel=' . $item->id . '>' . __('app.Block') . '</a>'
                : '<a class="btn btn-success text-white unblock" rel=' . $item->id . '>' . __('app.Unblock') . '</a>';

            $gender = $item->gender == 1
                ? '<span class="badge bg-dark text-white">' . __('app.Male') . '</span>'
                : '<span class="badge bg-dark text-white">' . __('app.Female') . '</span>';

            $image = (count($item->images) > 0)
                ? '<img src="public/storage/' . $item->images[0]->image . '" width="50" height="50">'
                : '<img src="http://placehold.jp/150x150.png" width="50" height="50">';

            $liveEligible = $item->can_go_live == 2
                ? '<span class="badge bg-success text-white">Yes</span>'
                : '<span class="badge bg-danger text-white">No</span>';

            $age = $item->dob ? Carbon::parse($item->dob)->age : '';

            $action = '<a href="' . route('viewUserDetails', $item->id) . '" class="btn btn-primary text-white" rel=' . $item->id . '><i class="fas fa-eye"></i></a>';

            $addCoin = '<a href="" data-id="' . $item->id . '" class="addCoins"><i class="i-cl-3 fas fa-plus-circle primary font-20 pointer p-l-5 p-r-5 me-2"></i></a>';

            $data[] = [
                $image,
                $item->identity,
                $item->fullname,
                $addCoin . $item->wallet,
                $liveEligible,
                $age,
                $gender,
                $block,
                $action,
            ];
        }

        return response()->json([
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data
        ]);
    }

    function fetchStreamerUsers(Request $request)
    {
        $columns = [
            0 => 'id',
            1 => 'fullname'
        ];

        $limit = $request->input('length');
        $start = $request->input('start');
        $orderIndex = $request->input('order.0.column');
        $order = $columns[$orderIndex] ?? 'id';  // fallback if index missing
        $dir = $request->input('order.0.dir', 'DESC');

        $search = $request->input('search.value');

        // ✅ Start base query: only streamers (can_go_live = 2)
        $query = Users::where('can_go_live', 2);

        // Apply search filter if present
        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('fullname', 'LIKE', "%{$search}%")
                    ->orWhere('identity', 'LIKE', "%{$search}%");
            });
        }

        // Count total data without filter
        $totalData = Users::where('can_go_live', 2)->count();

        // Count after filters
        $totalFiltered = $query->count();

        // Get paginated & ordered result
        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy($order, $dir)
            ->get();

        // Build data array
        $data = [];
        foreach ($result as $item) {
            $block = ($item->is_block == 0)
                ? '<a class="btn btn-danger text-white block" rel=' . $item->id . '>' . __('app.Block') . '</a>'
                : '<a class="btn btn-success text-white unblock" rel=' . $item->id . '>' . __('app.Unblock') . '</a>';

            $age = $item->dob ? Carbon::parse($item->dob)->age : '';

            $gender = ($item->gender == 1)
                ? '<span class="badge bg-dark text-white">' . __('app.Male') . '</span>'
                : '<span class="badge bg-dark text-white">' . __('app.Female') . '</span>';

            $image = (count($item->images) > 0)
                ? '<img src="public/storage/' . $item->images[0]->image . '" width="50" height="50">'
                : '<img src="http://placehold.jp/150x150.png" width="50" height="50">';

            $liveEligible = '<span class="badge bg-success text-white">Yes</span>';

            $action = '<a href="' . route('viewUserDetails', $item->id) . '" class="btn btn-primary text-white" rel=' . $item->id . '><i class="fas fa-eye"></i></a>';

            $data[] = [
                $image,
                $item->identity,
                $item->fullname,
                $liveEligible,
                $age,
                $gender,
                $block,
                $action,
            ];
        }

        return response()->json([
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data
        ]);
    }

    function fetchFakeUsers(Request $request)
    {
        $columns = [
            0 => 'id',
            1 => 'fullname'
        ];

        $limit = $request->input('length');
        $start = $request->input('start');
        $orderIndex = $request->input('order.0.column');
        $order = $columns[$orderIndex] ?? 'id';
        $dir = $request->input('order.0.dir', 'DESC');

        $search = $request->input('search.value');

        $query = Users::where('is_fake', 1);

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('fullname', 'LIKE', "%{$search}%")
                    ->orWhere('identity', 'LIKE', "%{$search}%");
            });
        }

        $totalData = Users::where('is_fake', 1)->count();
        $totalFiltered = $query->count();
        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy($order, $dir)
            ->get();

        $data = [];
        foreach ($result as $item) {
            $block = ($item->is_block == 0)
                ? '<a class="btn btn-danger text-white block" rel=' . $item->id . '>' . __('app.Block') . '</a>'
                : '<a class="btn btn-success text-white unblock" rel=' . $item->id . '>' . __('app.Unblock') . '</a>';

            $age = $item->dob ? Carbon::parse($item->dob)->age : '';

            $gender = ($item->gender == 1)
                ? '<span class="badge bg-dark text-white">' . __('app.Male') . '</span>'
                : '<span class="badge bg-dark text-white">' . __('app.Female') . '</span>';

            $image = (count($item->images) > 0)
                ? '<img src="public/storage/' . $item->images[0]->image . '" width="50" height="50">'
                : '<img src="http://placehold.jp/150x150.png" width="50" height="50">';

            $action = '<a href="' . route('viewUserDetails', $item->id) . '" class="btn btn-primary text-white" rel=' . $item->id . '><i class="fas fa-eye"></i></a>';

            $data[] = [
                $image,
                $item->fullname,
                $item->identity,
                $item->password,
                $age,
                $gender,
                $block,
                $action,
            ];
        }

        return response()->json([
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data
        ]);
    }

    function generateUniqueUsername()
    {
        $characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
        $username = '';
        $length = 8;

        do {
            for ($i = 0; $i < $length; $i++) {
                $username .= $characters[rand(0, strlen($characters) - 1)];
            }

            $existingUser = Users::where('username', $username)->first();
        } while ($existingUser);

        return $username;
    }

    function addUserDetails(Request $req)
    {
        // K05: removed the plaintext `where('password', $req->password)` check.
        // Social-login registration keys off the provider identity only and
        // never stores or compares a plaintext password. Use /api/auth/register
        // for the authenticated, token-issuing flow.
        $appData = AppData::first();
        $data = Users::where('identity', $req->identity)->first();

        if ($data == null) {
            $user = new Users;
            $user->fullname = Myfunction::customReplace($req->fullname ?? 'User');
            $user->identity = $req->identity;
            $user->device_token = $req->device_token;
            $user->device_type = $req->device_type;
            $user->login_type = $req->login_type;
            $user->wallet = $appData->new_user_free_coins ?? 0;
            $user->total_collected = $appData->new_user_free_coins ?? 0;
            $user->coins = $appData->new_user_free_coins ?? 0;
            $user->username = $this->generateUniqueUsername();
            // Populate the NOT NULL scaffold columns deterministically; the
            // password is a random unusable hash (auth is token-based).
            $user->name = $req->identity;
            $user->email = filter_var($req->identity, FILTER_VALIDATE_EMAIL)
                ? $req->identity
                : $req->identity . '@ketua.local';
            $user->password = Hash::make(\Illuminate\Support\Str::random(32));
            $user->is_verified = 0;
            $user->save();

            $data = Users::with('images')->where('id', $user->id)->first();

            return response()->json([
                'status' => true,
                'message' => __('app.UserAddSuccessful'),
                'data' => $data
            ]);
        } else {
            Users::where('identity', $req->identity)->update([
                'device_token' => $req->device_token,
                'device_type' => $req->device_type,
                'login_type' => $req->login_type,
            ]);

            $data = Users::with('images')->where('id', $data['id'])->first();

            return response()->json(['status' => true, 'message' => __('app.UserAllReadyExists'), 'data' => $data]);
        }
    }

    public function searchUsersForInterest(Request $req)
    {
        $rules = [
            'start' => 'required|integer|min:0',
            'count' => 'required|integer|min:1',
            'interest_id' => 'required|integer|min:1',
            'user_id' => 'required|integer|min:1'
        ];

        $validator = Validator::make($req->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::find($req->user_id);
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'User not found!',
            ]);
        }

        // Clean up blocked and hidden IDs
        $blocked_users = array_filter(array_map('intval', explode(',', $user->blocked_users ?? '')), fn($id) => $id > 0);
        $hidden_user_ids = array_filter(array_map('intval', explode(',', $user->hidden_user_ids ?? '')), fn($id) => $id > 0);

        $keyword = $req->keyword ?? '';
        $interestID = (int) $req->interest_id;
        $start = (int) $req->start;
        $count = (int) $req->count;

        $query = Users::with('images')
            ->where(function ($q) use ($keyword) {
                $q->where('fullname', 'LIKE', "%" . addslashes($keyword) . "%")
                    ->orWhere('username', 'LIKE', "%" . addslashes($keyword) . "%");
            })
            ->whereNotIn('id', $blocked_users)
            ->whereNotIn('id', $hidden_user_ids)
            ->where('id', '!=', $user->id)
            ->whereRaw("FIND_IN_SET(?, interests)", [$interestID])
            ->has('images')
            ->where('is_block', 0)
            ->where('anonymous', 0)
            ->whereNotIn('id',function($q)use($user){$q->select('premium_usage.user_id')->from('premium_usage')->where('incognito',true)->whereIn('user_id',function($q){$q->select('user_id')->from('subscriptions')->whereIn('plan',['gold','pro'])->whereIn('status',['active','cancelled'])->where('expires_at','>',now());})->whereNotIn('user_id',function($q)use($user){$q->select('my_user_id')->from('like_profiles')->where('user_id',$user->id);});});

        $total = $query->count();

        $result = $query
            ->offset($start)
            ->limit($count)
            ->get();

        if ($result->isEmpty()) {
            return response()->json([
                'status' => true,
                'message' => 'No data found',
                'total' => 0,
                'data' => []
            ]);
        }

        return response()->json([
            'status' => true,
            'message' => 'Data retrieved successfully',
            'total' => $total,
            'data' => $result
        ]);
    }

    public function searchUsers(Request $req)
    {
        $rules = [
            'user_id' => 'required|integer',
            'start' => 'required|integer|min:0',
            'count' => 'required|integer|min:1',
        ];

        $validator = Validator::make($req->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::find($req->user_id);
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'User not found!',
            ]);
        }

        $blocked_users = array_filter(array_map('intval', explode(',', $user->blocked_users ?? '')), fn($id) => $id > 0);
        $hidden_user_ids = array_filter(array_map('intval', explode(',', $user->hidden_user_ids ?? '')), fn($id) => $id > 0);

        $keyword = $req->keyword ?? '';

        $result = Users::with('images')
            ->where(function ($q) use ($keyword) {
                $q->where('fullname', 'LIKE', "%" . addslashes($keyword) . "%")
                    ->orWhere('username', 'LIKE', "%" . addslashes($keyword) . "%");
            })
            ->whereNotIn('id', $blocked_users)
            ->whereNotIn('id', $hidden_user_ids)
            ->where('id', '!=', $user->id)
            ->has('images')
            ->where('is_block', 0)
            ->where('anonymous', 0)
            ->whereNotIn('id',function($q)use($user){$q->select('premium_usage.user_id')->from('premium_usage')->where('incognito',true)->whereIn('user_id',function($q){$q->select('user_id')->from('subscriptions')->whereIn('plan',['gold','pro'])->whereIn('status',['active','cancelled'])->where('expires_at','>',now());})->whereNotIn('user_id',function($q)use($user){$q->select('my_user_id')->from('like_profiles')->where('user_id',$user->id);});})
            ->offset((int)$req->start)
            ->limit((int)$req->count)
            ->get();

        if ($result->isEmpty()) {
            return response()->json([
                'status' => true,
                'message' => 'No data found',
                'data' => []
            ]);
        }

        return response()->json([
            'status' => true,
            'message' => 'Data retrieved successfully',
            'data' => $result
        ]);
    }

    function updateProfile(Request $req)
    {
        // K01/K04 ownership: derive the acting user from the bearer token, not
        // the client-supplied user_id.
        $user = auth('app_users')->user();
        if (!$user) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $validator = \Illuminate\Support\Facades\Validator::make($req->all(), [
            'gender'=>'sometimes|integer|in:1,2','gender_preferred'=>'sometimes|integer|in:1,2,3',
            'country'=>'sometimes|nullable|string|max:100','state'=>'sometimes|nullable|string|max:100','city'=>'sometimes|nullable|string|max:100',
            'fullname' => 'sometimes|string|max:100', 'username' => 'sometimes|string|max:50',
            'bio' => 'sometimes|nullable|string|max:1000', 'about' => 'sometimes|nullable|string|max:5000',
            'dob' => 'sometimes|date_format:Y-m-d|before_or_equal:'.now()->subYears(18)->format('Y-m-d'),
            'lattitude' => 'sometimes|nullable|numeric|between:-90,90',
            'longitude' => 'sometimes|nullable|numeric|between:-180,180',
            'location_accuracy_m' => 'sometimes|required|numeric|between:0,10000',
            'image_order' => 'sometimes|array|max:6', 'image_order.*' => 'string|max:30|distinct',
            'age_preferred_min' => 'sometimes|integer|min:18|max:100',
            'age_preferred_max' => 'sometimes|integer|min:18|max:100',
            'distance_preference' => 'sometimes|numeric|min:1|max:20000',
            'app_language' => 'sometimes|in:en,fr,sw',
            'interests' => 'sometimes|nullable|string|max:2000',
            'deleteimageids' => 'sometimes|array|max:20', 'deleteimageids.*' => 'integer',
            'deleteimagestitle' => 'sometimes|array|max:20', 'deleteimagestitle.*' => 'string|max:500',
            'image' => 'sometimes|array|max:6', 'image.*' => 'image|max:10240',
        ]);
        if ($validator->fails()) return response()->json(['status'=>false, 'message'=>'Invalid profile data.', 'errors'=>$validator->errors()], 422);
        $minimum = $req->input('age_preferred_min', $user->age_preferred_min ?: 18);
        $maximum = $req->input('age_preferred_max', $user->age_preferred_max ?: 100);
        if ($minimum > $maximum) return response()->json(['status'=>false, 'message'=>'Minimum age must not exceed maximum age.'], 422);
        if ($req->has('location_accuracy_m') && (!$req->filled('lattitude') || !$req->filled('longitude'))) return response()->json(['status'=>false,'message'=>'A location fix needs both coordinates.'],422);
        if ($req->has('username') && Users::where('username',$req->username)->where('id','!=',$user->id)->exists()) return response()->json(['status'=>false,'message'=>'Username is already taken.'],422);
        $stagedPaths=[]; $deletedPaths=[];
        DB::beginTransaction();
        try {
        $user=Users::where('id',$user->id)->lockForUpdate()->firstOrFail();
        // Resolve deletion through owned database records before touching storage.
        $ownedImages = Images::where('user_id', $user->id)->where(function ($query) use ($req) {
            $query->whereIn('id', $req->input('deleteimageids', []))
                  ->orWhereIn('image', $req->input('deleteimagestitle', []));
        })->get();
        $kept=Images::where('user_id',$user->id)->whereNotIn('id',$ownedImages->pluck('id'))->orderBy('sort_order')->orderBy('id')->get();
        $files=$req->file('image',[]);
        if($ownedImages->count()>0 && $kept->count()+count($files)===0){DB::rollBack();return response()->json(['status'=>false,'message'=>'Keep at least one profile photo.'],422);}
        if ($kept->count()+count($files)>6) {DB::rollBack();return response()->json(['status'=>false,'message'=>'Your profile can have up to 6 photos.'],422);}
        $keys=$kept->pluck('id')->map(fn($id)=>(string)$id)->all();
        foreach ($files as $i=>$file) $keys[]='new:'.$i;
        $order=$req->input('image_order',$keys);
        if (count($order)!==count($keys) || array_diff($order,$keys) || array_diff($keys,$order)) {DB::rollBack();return response()->json(['status'=>false,'message'=>'Choose an order for your own photos.'],422);}
        $newImages=[];
        foreach ($files as $i=>$file) {
            $path=GlobalFunction::saveFileAndGivePath($file);$stagedPaths[]=$path;
            $photo=new Images();$photo->user_id=$user->id;$photo->image=$path;$photo->save();$newImages['new:'.$i]=$photo;
        }
        foreach($order as $rank=>$key){$photo=$newImages[$key]??$kept->firstWhere('id',(int)$key);$photo->sort_order=$rank;$photo->save();}
        foreach($ownedImages as $photo){$deletedPaths[]=$photo->image;$photo->delete();}


        if ($req->has("fullname")) {
            $user->fullname = Myfunction::customReplace($req->fullname);
        }
        if ($req->has('username')) $user->username=Myfunction::customReplace($req->username);
        // NOTE: is_verified is intentionally NOT settable here. Identity
        // verification is a separate admin-approved flow and must never be
        // granted by a profile edit (mission rule).
        if ($req->has("gender")) {
            $user->gender = $req->gender;
        }
        if ($req->has('youtube')) {
            $user->youtube = $req->youtube;
        }
        if ($req->has("instagram")) {
            $user->instagram = $req->instagram;
        }
        if ($req->has("facebook")) {
            $user->facebook = $req->facebook;
        }
        if ($req->has("country")) {
            $user->country = $req->country;
        }
        if ($req->has("state")) {
            $user->state = $req->state;
        }
        if ($req->has("city")) {
            $user->city = $req->city;
        }
        if ($req->has("bio")) {
            $user->bio = Myfunction::customReplace($req->bio);
        }
        if ($req->has("about")) {
            $user->about = Myfunction::customReplace($req->about);
        }
        if ($req->has("lattitude")) {
            $user->lattitude = $req->lattitude;
        }
        if ($req->has("longitude")) {
            $user->longitude = $req->longitude;
        }
        if ($req->has("dob")) {
            $user->dob = $req->dob;
        }
        if ($req->has("interests")) {
            $user->interests = $req->interests;
        }
        if ($req->has("gender_preferred")) {
            $user->gender_preferred = $req->gender_preferred;
        }
        if ($req->has("age_preferred_min")) {
            $user->age_preferred_min = $req->age_preferred_min;
        }
        if ($req->has("age_preferred_max")) {
            $user->age_preferred_max = $req->age_preferred_max;
        }
        if ($req->has("distance_preference")) {
            $user->distance_preference = $req->distance_preference;
        }
        if ($req->has("relationship_goal_id")) {
            $user->relationship_goal_id = $req->relationship_goal_id;
        }
        if ($req->has("religion_key")) {
            $user->religion_key = $req->religion_key;
        }
        if ($req->has("language_keys")) {
            $user->language_keys = $req->language_keys;
        }
        if ($req->has("app_language")) {
            $user->app_language = $req->app_language;
        }
        if ($req->has("hidden_user_ids")) {
            $user->hidden_user_ids = $req->hidden_user_ids;
        }
        if ($req->has('lattitude') || $req->has('longitude')) {
            $user->location_accuracy_m=$req->input('location_accuracy_m');
            $user->location_updated_at=$req->has('location_accuracy_m') ? now() : null;
        }
        $user->save();

        DB::commit();

        } catch (\Throwable $e) {
            DB::rollBack();foreach($stagedPaths as $path) \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
            report($e);return response()->json(['status'=>false,'message'=>'Unable to save your profile. Your previous profile has been kept.'],422);
        }

        foreach($deletedPaths as $path) {try{\Illuminate\Support\Facades\Storage::disk('public')->delete($path);}catch(\Throwable $e){report($e);}}
        $updatedUser = Users::where('id', $user->id)->with('images')->first();

        return response()->json(['status' => true, 'message' => __('app.Updatesuccessful'), 'data' => $updatedUser]);
    }

    function blockUser(Request $request)
    {
        $user = Users::where('id', $request->user_id)->first();

        if ($user) {
            $user->is_block = Constants::blocked;
            $user->save();

            Report::where('user_id', $request->user_id)->delete();

            return response()->json([
                'status' => true,
                'message' => 'This user has been blocked',
                'data' => $user,
            ]);
        } else {
            return response()->json([
                'status' => false,
                'message' => 'User not found',
            ]);
        }
    }

    function unblockUser(Request $request)
    {
        $user = Users::where('id', $request->user_id)->first();

        if ($user) {
            $user->is_block = Constants::unblocked;
            $user->save();

            return response()->json([
                'status' => true,
                'message' => 'This user has been blocked',
                'data' => $user,
            ]);
        } else {
            return response()->json([
                'status' => false,
                'message' => 'User not found',
            ]);
        }
    }

    function viewUserDetails($id)
    {
        $data = Users::where('id', $id)->with('images')->first();
        $interestIds = explode(',', $data->interests);
        // $interests = Interest::get();
        $interestTitles = Interest::orderByDesc('id')->whereIn('id', $interestIds)->get()->pluck('title');

        $data->interestTitles = $interestTitles;

        $matchedRelationshipGoal = RelationshipGoal::where('id', $data->relationship_goal_id)->first();

        return view('viewuser', [
            'data' => $data,
            'interestTitles' => $interestTitles,
            'matchedRelationshipGoal' => $matchedRelationshipGoal,
        ]);
    }

    function getProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'my_user_id' => 'required',
            'user_id' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::with(['images', 'stories'])->has('images')->where('id', $request->user_id)->first();
        $myUser = auth('app_users')->user();
        $request->merge(['my_user_id'=>$myUser->id]);
        if ($user && (int)$user->id !== (int)$myUser->id && ($user->is_block || $user->anonymous || in_array($user->id, explode(',', ($myUser->blocked_users ?? '').','.($myUser->hidden_user_ids ?? ''))) || in_array($myUser->id, explode(',', $user->blocked_users ?? '')))) return response()->json(['status'=>false,'message'=>'Profile unavailable.'], 404);
        if($user && $myUser && $user->id!=$myUser->id && \App\Services\PremiumAccess::plan($user->id)!=='free' && DB::table('premium_usage')->where('user_id',$user->id)->value('incognito') && !LikedProfile::where('my_user_id',$user->id)->where('user_id',$myUser->id)->exists())return response()->json(['status'=>false,'message'=>'Profile unavailable.'],404);
        if ($user == null || $myUser == null) {
            return response()->json([
                'status' => false,
                'message' =>  'User Not Found!',
            ]);
        }

        $followingStatus = FollowingList::whereRelation('user', 'is_block', 0)->where('user_id', $request->my_user_id)->where('my_user_id', $request->user_id)->first();
        $followingStatus2 = FollowingList::whereRelation('user', 'is_block', 0)->where('my_user_id', $request->my_user_id)->where('user_id', $request->user_id)->first();

        // koi ek bija ne follow nathi kartu to 0
        if ($followingStatus == null && $followingStatus2 == null) {
            $user->followingStatus = 0;
        }
        // same valo mane follow kar che to 1
        if ($followingStatus != null) {
            $user->followingStatus = 1;
        }
        // hu same vala ne follow karu chu to 2
        if ($followingStatus2) {
            $user->followingStatus = 2;
        }
        // banne ek bija ne follow kare to 3
        if ($followingStatus && $followingStatus2) {
            $user->followingStatus = 3;
        }

        $fetchUserisLiked = UserNotification::where('my_user_id', $request->my_user_id)
            ->where('user_id', $request->user_id)
            ->where('type', Constants::notificationTypeLikeProfile)
            ->first();

        if ($fetchUserisLiked) {
            $user->is_like = true;
        } else {
            $user->is_like = false;
        }

        return response()->json([
            'status' => true,
            'message' =>  __('app.fetchSuccessful'),
            'data' => (int)$user->id === (int)$myUser->id ? $user : $this->publicProfile($user),
        ]);
    }

    function fetchMyUserProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $myUser = Users::with('images')->where('id', $request->user_id)->first();
        if ($myUser == null) {
            return response()->json([
                'status' => false,
                'message' =>  'User Not Found!',
            ]);
        }

        $me = auth('app_users')->user();
        if ((int)$myUser->id !== (int)$me->id) {
            $mine = array_filter(explode(',', ($me->blocked_users ?? '').','.($me->hidden_user_ids ?? '')));
            $theirs = array_filter(explode(',', $myUser->blocked_users ?? ''));
            if ($myUser->is_block || $myUser->anonymous || in_array($myUser->id, $mine) || in_array($me->id, $theirs)) return response()->json(['status'=>false,'message'=>'Profile unavailable.'], 404);
        }
        return response()->json([
            'status' => true,
            'message' =>  __('app.fetchSuccessful'),
            'data' => (int)$myUser->id === (int)$me->id ? $myUser : $this->publicProfile($myUser),
        ]);
    }

    public function updateSavedProfile(Request $req)
    {
        abort_unless(auth('app_users')->check(),401);
        $req->validate(['profiles'=>'present|nullable|string|max:10000|regex:/^(?:[1-9][0-9]*(?:,[1-9][0-9]*)*)?$/']);
        $req->merge(['user_id'=>auth('app_users')->user()->id]);
        $user = Users::with('images')->where('id', $req->user_id)->first();
        $user->savedprofile = $req->profiles;
        $user->save();

        return response()->json(['status' => true, 'message' => __('app.Updatesuccessful'), 'data' => $user]);
    }

    function getUserDetails(Request $request)
    {
        $data = auth('app_users')->user();

        if ($data != null) {
            $data['image']  = Images::where('user_id', $data['id'])->first();
        } else {
            return response()->json(['status' => false, 'message' => __('app.UserNotFound')]);
        }
        $data['password'] = '';
        return response()->json(['status' => true, 'message' => __('app.fetchSuccessful'), 'data' => $data]);
    }

    public function followUser(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['my_user_id'=>auth('app_users')->user()->id]);
        $validator = Validator::make($request->all(), [
            'my_user_id' => 'required',
            'user_id' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $fromUserQuery = Users::query();
        $toUserQuery = Users::query();

        $fromUser = $fromUserQuery->where('id', $request->my_user_id)->first();
        $toUser = $toUserQuery->where('id', $request->user_id)->first();

        if ($fromUser && $toUser) {
            if ($fromUser == $toUser) {
                return response()->json([
                    'status' => false,
                    'message' => 'Lol you did not follow yourself',
                ]);
            } else {
                $followingList = FollowingList::where('my_user_id', $request->my_user_id)->where('user_id', $request->user_id)->first();
                if ($followingList) {
                    return response()->json([
                        'status' => false,
                        'message' => 'User is Already in following list',
                    ]);
                }

                $blockUserIds = explode(',', $fromUser->blocked_users);

                foreach ($blockUserIds as $blockUserId) {
                    if ($blockUserId == $request->user_id) {
                        return response()->json([
                            'status' => false,
                            'message' => 'You blocked this User',
                        ]);
                    }
                }

                $following = new FollowingList();
                $following->my_user_id = (int) $request->my_user_id;
                $following->user_id = (int) $request->user_id;
                $following->save();

                $followingCount = $fromUserQuery->where('id', $request->my_user_id)->first();
                $followingCount->following += 1;
                $followingCount->save();

                $followersCount = $toUserQuery->where('id', $request->user_id)->first();
                $followersCount->followers += 1;
                $followersCount->save();

                $updatedUser = Users::where('id', $request->user_id)->first();

                $updatedUser->images;

                $following->user = $this->publicProfile($updatedUser);

                $type = Constants::notificationTypeFollow;

                $userNotification = new UserNotification();
                $userNotification->my_user_id = (int) $request->my_user_id;
                $userNotification->user_id = (int) $request->user_id;
                $userNotification->item_id = (int) $request->user_id;
                $userNotification->type = $type;
                $userNotification->save();

                return response()->json([
                    'status' => true,
                    'message' => 'User Added in Following List',
                    'data' => $following,
                ]);
            }
        } else {
            return response()->json([
                'status' => false,
                'message' => 'User Not Found',
            ]);
        }
    }

    public function fetchFollowingList(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required',
            'start' => 'required',
            'limit' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->user_id)->first();
        if (!$user) {
            return response()->json(['status' => false, 'message' => 'User not found']);
        }

        $blockUserIds = [];
        if (!empty($user->blocked_users)) {
            $blockUserIds = explode(',', $user->blocked_users);
        }
        $hiddenUserIds = [];
        if (!empty($user->hidden_user_ids)) {
            $hiddenUserIds = explode(',', $user->hidden_user_ids);
        }

        $fetchFollowingList = FollowingList::whereRelation('user', 'is_block', 0)
            ->whereNotIn('user_id', $blockUserIds)
            ->whereNotIn('user_id', $hiddenUserIds)
            ->where('my_user_id', $request->user_id)
            ->with([
                'user' => function ($query) {
                    $query->whereHas('images');
                },
                'user.images'
            ])
            ->offset($request->start)
            ->limit($request->limit)
            ->get()
            ->pluck('user');

        return response()->json([
            'status' => true,
            'message' => 'Fetch Following List',
            'data' => $fetchFollowingList,
        ]);
    }

    public function fetchFollowersList(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required',
            'start' => 'required',
            'limit' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->user_id)->first();
        if (!$user) {
            return response()->json(['status' => false, 'message' => 'User not found']);
        }

        $blockUserIds = [];
        if (!empty($user->blocked_users)) {
            $blockUserIds = explode(',', $user->blocked_users);
        }
        $hiddenUserIds = [];
        if (!empty($user->hidden_user_ids)) {
            $hiddenUserIds = explode(',', $user->hidden_user_ids);
        }

        $fetchFollowersList = FollowingList::where('user_id', $request->user_id)
            ->whereNotIn('my_user_id', $blockUserIds)
            ->whereNotIn('my_user_id', $hiddenUserIds)
            // ->whereNotIn('my_user_id', function ($query) use ($request) {
            //     $query->select('id')
            //         ->from('users')
            //         ->whereRaw("FIND_IN_SET(?, blocked_users)", [$request->user_id]);
            // })
            ->with('followerUser', 'followerUser.images')
            ->offset($request->start)
            ->limit($request->limit)
            ->get()
            ->pluck('followerUser');

        return response()->json([
            'status' => true,
            'message' => 'Fetch Followers List',
            'data' => $fetchFollowersList,
        ]);
    }

    public function unfollowUser(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['my_user_id'=>auth('app_users')->user()->id]);
        $validator = Validator::make($request->all(), [
            'my_user_id' => 'required',
            'user_id' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }


        $fromUserQuery = Users::query();
        $toUserQuery = Users::query();

        $fromUser = $fromUserQuery->where('id', $request->my_user_id)->first();
        $toUser = $toUserQuery->where('id', $request->user_id)->first();

        if ($fromUser && $toUser) {
            if ($fromUser == $toUser) {
                return response()->json([
                    'status' => false,
                    'message' => 'Lol You did not Remove yourself, Bcz You dont follow yourself',
                ]);
            } else {
                $followingList = FollowingList::where('my_user_id', $request->my_user_id)->where('user_id', $request->user_id)->first();
                if ($followingList) {
                    $followingCount = $fromUserQuery->where('id', $request->my_user_id)->first();
                    $followingCount->following = max(0, $followingCount->following - 1);
                    $followingCount->save();

                    $followersCount = $toUserQuery->where('id', $request->user_id)->first();
                    $followersCount->followers = max(0, $followersCount->followers - 1);;
                    $followersCount->save();

                    $userNotification = UserNotification::where('my_user_id', $request->my_user_id)
                        ->where('user_id', $request->user_id)
                        ->where('type', Constants::notificationTypeFollow)
                        ->get();
                    $userNotification->each->delete();

                    $followingList->delete();

                    return response()->json([
                        'status' => true,
                        'message' => 'Unfollow user',
                        'data' => $followingList,
                    ]);
                } else {
                    return response()->json([
                        'status' => false,
                        'message' => 'User Not Found',
                    ]);
                }
            }
        } else {
            return response()->json([
                'status' => false,
                'message' => 'User Not Found',
            ]);
        }
    }

    public function fetchHomePageData(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['my_user_id'=>auth('app_users')->user()->id]);
        $validator = Validator::make($request->all(), [
            'my_user_id' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->my_user_id)->first();

        if ($user) {

            $blockUserIds = explode(',', $user->blocked_users);
            $hiddenUserIds = explode(',', $user->hidden_user_ids);

            $followingUsers = FollowingList::where('my_user_id', $request->my_user_id)
                ->whereRelation('story', 'created_at', '>=', now()->subDay()->toDateTimeString())
                ->with('user', 'user.images')
                ->whereRelation('user', 'is_block', 0)
                ->get()
                ->pluck('user');

            foreach ($followingUsers as $followingUser) {
                $stories = Story::where('user_id', $followingUser->id)
                    ->where('created_at', '>=', now()->subDay()->toDateTimeString())
                    ->get();

                foreach ($stories as $story) {
                    $story->storyView = $story->view_by_user_ids ? in_array($request->my_user_id, explode(',', $story->view_by_user_ids)) : false;
                }
                $followingUser->stories = $stories;
            }

            $fetchPosts = Post::with('content')
                ->inRandomOrder()
                ->with(['user', 'user.stories', 'user.images'])
                ->whereRelation('user', 'is_block', 0)
                ->whereNotIn('user_id', array_merge($blockUserIds))
                ->whereNotIn('user_id', array_merge($hiddenUserIds))
                ->limit(50)
                ->get();


            if (!$fetchPosts->isEmpty()) {
                foreach ($fetchPosts as $fetchPost) {
                    $isPostLike = Like::where('user_id', $request->my_user_id)->where('post_id', $fetchPost->id)->first();
                    if ($isPostLike) {
                        $fetchPost->is_like = 1;
                    } else {
                        $fetchPost->is_like = 0;
                    }
                }

                return response()->json([
                    'status' => true,
                    'message' => 'Fetch posts',
                    'data' =>  [
                        'users_stories' => $followingUsers,
                        'posts' => $fetchPosts,
                    ]
                ]);
            } else {
                return response()->json([
                    'status' => false,
                    'message' => 'Posts not Available',
                ]);
            }

            return response()->json([
                'status' => true,
                'message' => 'Fetch Home Page Data Successfully',
                'data' =>  [
                    'users_stories' => $followingUser,
                    'posts' => $fetchPosts,
                ]
            ]);
        } else {
            return response()->json([
                'status' => false,
                'message' => 'User Not Found',
            ]);
        }
    }

    public function deleteUserFromAdmin(Request $request)
    {
        $rules = [
            'user_id' => 'required|integer|min:1',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('id', $request->user_id)->first();
        if (!$user) {
            return json_encode([
                'status' => false,
                'message' => 'user not found!',
            ]);
        }

        $images = Images::where('user_id', $user->id)->get();
        foreach ($images as $image) {
            GlobalFunction::deleteFile($image->image);
            $image->delete();
        }
        $likes = Like::where('user_id', $user->id)->get();
        foreach ($likes as $like) {
            $postLikeCount = Post::where('id', $like->post_id)->first();
            if ($postLikeCount) {
                $postLikeCount->likes_count = max(0, $postLikeCount->likes_count - 1);
                $postLikeCount->save();
            }
            $like->delete();
        }
        $comments = Comment::where('user_id', $user->id)->get();
        foreach ($comments as $comment) {
            $postCommentCount = Post::where('id', $comment->post_id)->first();
            if ($postCommentCount) {
                $postCommentCount->comments_count = max(0, $postCommentCount->comments_count - 1);
                $postCommentCount->save();
            }
            $comment->delete();
        }

        $followerList = FollowingList::where('my_user_id', $user->id)->get();
        foreach ($followerList as $follower) {
            $followerUser = User::where('id', $follower->user_id)->first();
            if ($followerUser) {
                $followerUser->followers = max(0, $followerUser->followers - 1);
                $followerUser->save();
            }

            $follower->delete();
        }

        $followingList = FollowingList::where('user_id', $user->id)->get();
        foreach ($followingList as $following) {
            $followingUser = User::where('id', $following->user_id)->first();
            if ($followingUser) {
                $followingUser->following = max(0, $followingUser->following - 1);
                $followingUser->save();
            }

            $following->delete();
        }

        \App\Services\PremiumAccess::deleteProfile($user->id);
        if (\Illuminate\Support\Facades\Schema::hasTable('experience_tickets')) \Illuminate\Support\Facades\DB::table('experience_tickets')->where('user_id', $user->id)->delete();
        LikedProfile::where('my_user_id', $user->id)->delete();
        LikedProfile::where('user_id', $user->id)->delete();

        $liveApplication = LiveApplications::where('user_id', $user->id)->first();
        if ($liveApplication) {
            GlobalFunction::deleteFile($liveApplication->intro_video);
            $liveApplication->delete();
        }

        LiveHistory::where('user_id', $user->id)->delete();

        $posts = Post::where('user_id', $user->id)->get();
        foreach ($posts as $post) {
            $postContents = PostContent::where('post_id', $post->id)->get();
            foreach ($postContents as $postContent) {
                GlobalFunction::deleteFile($postContent->content);
                GlobalFunction::deleteFile($postContent->thumbnail);
                $postContent->delete();
            }

            Comment::where('post_id', $post->id)->delete();
            Like::where('post_id', $post->id)->delete();
            Report::where('post_id', $post->id)->delete();
            UserNotification::where('item_id', $post->id)->where('type', Constants::notificationTypeLike)->delete();

            $post->delete();
        }

        RedeemRequest::where('user_id', $user->id)->delete();
        Report::where('user_id', $user->id)->delete();

        $stories = Story::where('user_id', $user->id)->get();
        foreach ($stories as $story) {
            GlobalFunction::deleteFile($story->content);
            $story->delete();
        }

        UserNotification::where('user_id', $user->id)->delete();
        UserNotification::where('my_user_id', $user->id)->delete();

        $verificationRequest = VerifyRequest::where('user_id', $user->id)->first();
        if ($verificationRequest) {
            GlobalFunction::deleteFile($verificationRequest->document, 'local');
            GlobalFunction::deleteFile($verificationRequest->selfie, 'local');
            $verificationRequest->delete();
        }

        $user->tokens()->delete();
        $apiUser = User::find($user->id);
        if ($apiUser) $apiUser->tokens()->delete();
        $user->delete();

        return response()->json(['status' => true, 'message' => "Account Deleted Successfully !"]);
    }

    public function filteredProfiles(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'gender'=>'nullable|integer|in:1,2,3',
            'age_preferred_min'=>'nullable|integer|min:18|max:100',
            'age_preferred_max'=>'nullable|integer|min:18|max:100|gte:age_preferred_min',
            'distance_preference'=>'nullable|integer|min:1|max:10000',
            'start'=>'nullable|integer|min:0','limit'=>'nullable|integer|min:1|max:50',
            'relationship_goal_id'=>'nullable|integer|min:1',
            'interests'=>'nullable|string|max:500','language_keys'=>'nullable|string|max:500',
            'religion_key'=>'nullable|string|max:150',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = auth('app_users')->user();
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'User not found',
            ]);
        }

        $setting = AppData::first();

        $userInterests = is_array($user->interests) ? $user->interests : explode(',', $user->interests ?? '');
        $userLanguages = is_array($user->language_keys) ? $user->language_keys : explode(',', $user->language_keys ?? '');

        $array = explode(',', $user->hidden_user_ids);

        $query = Users::where('is_block', 0)
            ->where('anonymous',0)
            ->where('id', '!=', $user->id)
            ->whereNotIn('id', $array)
            ->whereNotIn('id',array_filter(explode(',', $user->blocked_users ?? '')))
            ->whereRaw('NOT FIND_IN_SET(?, COALESCE(blocked_users, ?))', [$user->id,''])
            ->whereNotNull('dob')->where('dob','<=',now('UTC')->subYears(18)->toDateString())
            ->with('images')
            ->has('images');

        if ($request->filled('gender') && (int)$request->gender !== 3) {
            $query->where('gender', $request->gender);
        }
        if ($request->filled('relationship_goal_id')) $query->where('relationship_goal_id',$request->relationship_goal_id);
        if ($request->filled('religion_key')) $query->where('religion_key',trim($request->religion_key));
        foreach (['interests','language_keys'] as $field) {
            $selected=array_values(array_filter(array_map('trim',explode(',', $request->input($field,'')))));
            if ($selected) $query->where(function ($q) use ($selected,$field) {
                foreach ($selected as $value) $q->orWhereRaw('FIND_IN_SET(?, '.$field.')',[$value]);
            });
        }

        //	0 = Fake user Not Include | 1 = Fake User Include	
        if ($setting->include_fake_user_in_matching == 0) {
            $query->where('is_fake', 0);
        }

        if ($request->has('age_preferred_min') && $request->has('age_preferred_max')) {
            $query->whereRaw("TIMESTAMPDIFF(YEAR, dob, CURDATE()) BETWEEN ? AND ?", [
                $request->age_preferred_min,
                $request->age_preferred_max
            ]);
        }

        $profiles = $query->get();

        $distanceFiltered = $profiles->filter(function ($candidate) use ($user, $request) {
            if (!$user->lattitude || !$user->longitude || !$candidate->lattitude || !$candidate->longitude) {
                return true;
            }
            $radius = $request->distance_preference ?? 100;
            return Myfunction::point2point_distance(
                $user->lattitude,
                $user->longitude,
                $candidate->lattitude,
                $candidate->longitude,
                'K',
                $radius
            );
        });

        $matchedProfiles = $distanceFiltered->map(function ($candidate) use ($user, $userInterests, $userLanguages) {
            $candidateInterests = is_array($candidate->interests) ? $candidate->interests : explode(',', $candidate->interests ?? '');
            $candidateLanguages = is_array($candidate->language_keys) ? $candidate->language_keys : explode(',', $candidate->language_keys ?? '');

            $matchedInterests = array_values(array_intersect(array_map('trim', $userInterests), array_map('trim', $candidateInterests)));
            $matchedLanguages = array_values(array_intersect(array_map('trim', $userLanguages), array_map('trim', $candidateLanguages)));

            $matchedRelationshipGoal = ($user->relationship_goal_id && $candidate->relationship_goal_id == $user->relationship_goal_id)
                ? $user->relationship_goal_id
                : null;

            $matchedReligion = ($user->religion_key && $candidate->religion_key == $user->religion_key)
                ? $user->religion_key
                : null;

            $score = (count($matchedInterests) * 2) + (count($matchedLanguages) * 2);
            if ($matchedRelationshipGoal) $score += 3;
            if ($matchedReligion) $score += 3;

            $candidate->matched_interests = implode(',', $matchedInterests);
            $candidate->matched_languages = implode(',', $matchedLanguages);
            $candidate->matched_relationship_goal_id = $matchedRelationshipGoal;
            $candidate->matched_religion = $matchedReligion;
            $candidate->match_score = $score;

            return $candidate;
        })
            ->filter(function ($candidate) {
                return $candidate->match_score > 0;
            })
            ->sortByDesc('match_score')
            ->values();

        $start = (int)($request->start ?? 0);
        $limit = (int)($request->limit ?? 10);
        $paginated = $matchedProfiles->slice($start, $limit)->values();

        return response()->json([
            'status' => true,
            'message' => 'Matched profiles retrieved successfully',
            'total' => $matchedProfiles->count(),
            // 'start' => $start,
            // 'limit' => $limit,
            // 'count' => $paginated->count(),
            'data' => $paginated->map(fn ($candidate) => $this->publicProfile($candidate))
        ]);
    }

    public function fetchMyHiddenProfiles(Request $request)
    {
        abort_unless(auth('app_users')->check(),401);
        $request->merge(['my_user_id'=>auth('app_users')->user()->id]);
        $validator = Validator::make($request->all(), [
            'my_user_id' => 'required',
            'start' => 'required',
            'limit' => 'required',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::find($request->my_user_id);
        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'User not found',
            ]);
        }

        $hiddenUserArray = explode(',', $user->hidden_user_ids);

        $query = Users::where('is_block', 0)
            ->where('id', '!=', $user->id)
            ->whereIn('id', $hiddenUserArray)
            ->with('images')
            ->has('images');

        $start = max(0, (int) $request->start);
        $limit = min(100, max(1, (int) $request->limit));

        $profiles = $query
            ->offset($start)
            ->limit($limit)
            ->get();

        return response()->json([
            'status' => true,
            'message' => 'Fetch My Hidden Profiles successfully',
            'data' => $profiles->map(fn ($profile) => $this->publicProfile($profile))->values()
        ]);
    }

    function fakeUserLogin(Request $request)
    {
        // K12: this is a testing/backdoor login surface. Gate it behind an
        // explicit config flag that is OFF in production. When enabled it still
        // requires a valid password and returns a scoped bearer token instead
        // of the raw full user row.
        if (!config('ketua.allow_fake_login', false)) {
            return response()->json([
                'status'  => false,
                'message' => 'This endpoint is disabled.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'identity' => 'required',
            'password' => 'required',
            'device_token' => 'nullable|string',
            'device_type'   => 'nullable|string',
        ]);

        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $user = Users::where('identity', $request->identity)->first();
        if ($user == null) {
            return response()->json([
                'status' => false,
                'message' => 'user not found!',
            ]);
        }

        if ($request->identity !== $user->identity || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid credentials'
            ]);
        }

        if ($request->filled('device_token')) {
            $user->device_token = $request->device_token;
            $user->device_type  = $request->device_type ?? $user->device_type; // keep old if not sent
            $user->save();
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Login successful',
            'token' => $token,
            'data' => $user
        ]);
    }
}
