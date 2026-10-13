<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DiamondPackController;
use App\Http\Controllers\GiftController;
use App\Http\Controllers\FeatureController;
use App\Http\Controllers\MatchController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\ShortVideoController;
use App\Http\Controllers\SubscriptionController;
use App\Http\Controllers\InterestController;
use App\Http\Controllers\LiveApplicationController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\PackageController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\RedeemRequestsController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\UsersController;
use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/


/*
|--------------------------------------------------------------------------
| Authentication Routes (K01)
|--------------------------------------------------------------------------
| Token-based auth. These replace the plaintext register/login path.
*/
Route::post('auth/register', [AuthController::class, 'register'])->middleware(['checkHeader', 'throttle:auth']);
Route::post('auth/login',    [AuthController::class, 'login'])->middleware(['checkHeader', 'throttle:auth']);
Route::post('auth/phone/register', [AuthController::class, 'registerPhone'])->middleware(['checkHeader', 'throttle:auth']);
Route::post('auth/phone/login', [AuthController::class, 'loginPhone'])->middleware(['checkHeader', 'throttle:auth']);
Route::post('auth/logout',   [AuthController::class, 'logout'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('auth/me', function (Request $request) {
    return response()->json(['status' => true, 'data' => auth('app_users')->user()]);
})->middleware(['checkHeader', 'auth.app_users']);

/*
|--------------------------------------------------------------------------
| Gifting (mission feature) — server-authoritative wallet transfer
|--------------------------------------------------------------------------
*/
Route::post('sendGift', [GiftController::class, 'sendGift'])->middleware(['checkHeader', 'auth.app_users', 'throttle:money']);
Route::post('myGifts',  [GiftController::class, 'myGifts'])->middleware(['checkHeader', 'auth.app_users']);

/*
|--------------------------------------------------------------------------
| Matching + swipe-up "Stars" (mission features)
|--------------------------------------------------------------------------
*/
Route::post('match/like',    [MatchController::class, 'likeProfile'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('match/star',    [MatchController::class, 'starProfile'])->middleware(['checkHeader', 'auth.app_users', 'throttle:money']);
Route::post('match/dislike', [MatchController::class, 'dislikeProfile'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('match/myMatches', [MatchController::class, 'myMatches'])->middleware(['checkHeader', 'auth.app_users']);

/*
|--------------------------------------------------------------------------
| Boosts, Heartbeat, consistency milestones, profile completeness
|--------------------------------------------------------------------------
*/
Route::post('boost',         [FeatureController::class, 'boost'])->middleware(['checkHeader', 'auth.app_users', 'throttle:money']);
Route::post('boost/status',  [FeatureController::class, 'boostStatus'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('heartbeat',     [FeatureController::class, 'heartbeat'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('profile/completeness', [FeatureController::class, 'profileCompleteness'])->middleware(['checkHeader', 'auth.app_users']);

/*
|--------------------------------------------------------------------------
| Gold plans / creator subscriptions (server-authoritative entitlement)
|--------------------------------------------------------------------------
*/
Route::post('subscription/status', [SubscriptionController::class, 'status'])->middleware(['checkHeader', 'auth.app_users']);
// Provider webhook: authorized by the RevenueCat shared secret, not a user token.
Route::post('webhooks/revenuecat', [SubscriptionController::class, 'revenuecatWebhook']);

/*
|--------------------------------------------------------------------------
| Short video (mission feature)
|--------------------------------------------------------------------------
*/
Route::post('shortVideo/feed',    [ShortVideoController::class, 'feed'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('shortVideo/create',  [ShortVideoController::class, 'create'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('shortVideo/like',    [ShortVideoController::class, 'like'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('shortVideo/view',    [ShortVideoController::class, 'view'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('shortVideo/share',   [ShortVideoController::class, 'share'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('shortVideo/delete',  [ShortVideoController::class, 'delete'])->middleware(['checkHeader', 'auth.app_users']);

/*
|--------------------------------------------------------------------------
| Chat (F06) — server-authoritative messaging
|--------------------------------------------------------------------------
*/
Route::post('chat/conversations', [ChatController::class, 'conversations'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('chat/send',          [ChatController::class, 'send'])->middleware(['checkHeader', 'auth.app_users', 'throttle:money']);
Route::post('chat/messages',      [ChatController::class, 'messages'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('chat/read',          [ChatController::class, 'markRead'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('chat/block',         [ChatController::class, 'block'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('chat/mute',          [ChatController::class, 'mute'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('chat/deleteMessage', [ChatController::class, 'deleteMessage'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('chat/deleteConversation', [ChatController::class, 'deleteConversation'])->middleware(['checkHeader', 'auth.app_users']);


/*|--------------------------------------------------------------------------
  | Users Route                                                              |
  |--------------------------------------------------------------------------|*/

Route::post('register', [AuthController::class, 'register'])->middleware(['checkHeader', 'throttle:auth']);
Route::post('updateProfile', [UsersController::class, 'updateProfile'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchUsersByCordinates', [UsersController::class, 'fetchUsersByCordinates'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('updateUserBlockList', [UsersController::class, 'updateUserBlockList'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('deleteMyAccount', [UsersController::class, 'deleteMyAccount'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchMyUserProfile', [UsersController::class, 'fetchMyUserProfile'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('getProfile', [UsersController::class, 'getProfile'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('getUserDetails', [UsersController::class, 'getUserDetails'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('getRandomProfile', [UsersController::class, 'getRandomProfile'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('getExplorePageProfileList', [UsersController::class, 'getExplorePageProfileList'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('filteredProfiles', [UsersController::class, 'filteredProfiles'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('yourMatchings', [MatchController::class, 'myMatches'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('updateSavedProfile', [UsersController::class, 'updateSavedProfile'])->middleware(['checkHeader', 'auth.app_users']);
// Route::post('updateLikedProfile', [UsersController::class, 'updateLikedProfile'])->middleware('checkHeader');
Route::post('likedProfile', [UsersController::class, 'likedProfile'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('dislikedProfile', [UsersController::class, 'dislikedProfile'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('fetchSavedProfiles', [UsersController::class, 'fetchSavedProfiles'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchLikedProfiles', [UsersController::class, 'fetchLikedProfiles'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('getPackage', [PackageController::class, 'getPackage'])->middleware('checkHeader');
Route::post('addUserReport', [ReportController::class, 'addUserReport'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('getSettingData', [SettingController::class, 'getSettingData'])->middleware('checkHeader');

Route::post('searchUsers', [UsersController::class, 'searchUsers'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('searchUsersForInterest', [UsersController::class, 'searchUsersForInterest'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('getUserNotifications', [NotificationController::class, 'getUserNotifications'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('getAdminNotifications', [NotificationController::class, 'getAdminNotifications'])->middleware('checkHeader');

Route::post('getDiamondPacks', [DiamondPackController::class, 'getDiamondPacks'])->middleware('checkHeader');

Route::post('onOffNotification', [UsersController::class, 'onOffNotification'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('updateLiveStatus', [UsersController::class, 'updateLiveStatus'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('onOffShowMeOnMap', [UsersController::class, 'onOffShowMeOnMap'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('onOffAnonymous', [UsersController::class, 'onOffAnonymous'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('onOffVideoCalls', [UsersController::class, 'onOffVideoCalls'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('fetchBlockedProfiles', [UsersController::class, 'fetchBlockedProfiles'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('applyForLive', [LiveApplicationController::class, 'applyForLive'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('applyForVerification', [UsersController::class, 'applyForVerification'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('addCoinsToWallet', [UsersController::class, 'addCoinsToWallet'])->middleware(['checkHeader', 'auth.app_users', 'throttle:money']);
Route::post('minusCoinsFromWallet', [UsersController::class, 'minusCoinsFromWallet'])->middleware(['checkHeader', 'auth.app_users', 'throttle:money']);
Route::post('increaseStreamCountOfUser', [UsersController::class, 'increaseStreamCountOfUser'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('addLiveStreamHistory', [LiveApplicationController::class, 'addLiveStreamHistory'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('logOutUser', [UsersController::class, 'logOutUser'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchAllLiveStreamHistory', [LiveApplicationController::class, 'fetchAllLiveStreamHistory'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('placeRedeemRequest', [RedeemRequestsController::class, 'placeRedeemRequest'])->middleware(['checkHeader', 'auth.app_users', 'throttle:money']);
Route::post('fetchMyRedeemRequests', [RedeemRequestsController::class, 'fetchMyRedeemRequests'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('pushNotificationToSingleUser', fn() => response()->json(['status'=>false,'message'=>'Notifications are sent by trusted server actions only.'],403))->middleware(['checkHeader','auth.app_users']);

Route::post('followUser', [UsersController::class, 'followUser'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchFollowingList', [UsersController::class, 'fetchFollowingList'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchFollowersList', [UsersController::class, 'fetchFollowersList'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('unfollowUser', [UsersController::class, 'unfollowUser'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchMyHiddenProfiles', [UsersController::class, 'fetchMyHiddenProfiles'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('fetchHomePageData', [UsersController::class, 'fetchHomePageData'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('createStory', [PostController::class, 'createStory'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('viewStory', [PostController::class, 'viewStory'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchStories', [PostController::class, 'fetchStories'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('deleteStory', [PostController::class, 'deleteStory'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('reportPost', [PostController::class, 'reportPost'])->middleware(['checkHeader', 'auth.app_users']);

Route::post('addPost', [PostController::class, 'addPost'])->middleware(['checkHeader', 'auth.app_users']);
// Route::post('fetchPosts', [PostController::class, 'fetchPosts'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('addComment', [PostController::class, 'addComment'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchComments', [PostController::class, 'fetchComments'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('deleteComment', [PostController::class, 'deleteComment'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('likePost', [PostController::class, 'likePost'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('dislikePost', [PostController::class, 'dislikePost'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('deleteMyPost', [PostController::class, 'deleteMyPost'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchPostByUser', [PostController::class, 'fetchPostByUser'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchPostsByHashtag', [PostController::class, 'fetchPostsByHashtag'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('fetchPostByPostId', [PostController::class, 'fetchPostByPostId'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('increasePostViewCount', [PostController::class, 'increasePostViewCount'])->middleware(['checkHeader', 'auth.app_users']);

Route::get('deleteStoryFromWeb', fn () => response()->json(['status'=>false,'message'=>'Story cleanup is an administrator operation.'],403));
Route::post('storeFileGivePath', [SettingController::class, 'storeFileGivePath'])->middleware(['checkHeader', 'auth.app_users']);
Route::post('generateAgoraToken', [SettingController::class, 'generateAgoraToken'])->middleware(['checkHeader', 'auth.app_users', 'throttle:auth']);

Route::post('fakeUserLogin', [UsersController::class, 'fakeUserLogin'])->middleware('checkHeader');

Route::get('catalog', [\App\Http\Controllers\PlanCatalogController::class, 'catalog'])->middleware(['checkHeader']);

Route::get('likes/incoming', [\App\Http\Controllers\IncomingLikesController::class, 'index'])->middleware(['checkHeader','auth.app_users']);

Route::get('experiences', [\App\Http\Controllers\ExperienceController::class,'index'])->middleware(['checkHeader','auth.app_users']);
Route::post('experiences/reserve', [\App\Http\Controllers\ExperienceController::class,'reserve'])->middleware(['checkHeader','auth.app_users','throttle:money']);
Route::get('experiences/tickets', [\App\Http\Controllers\ExperienceController::class,'tickets'])->middleware(['checkHeader','auth.app_users']);
Route::get('creator/earn', [\App\Http\Controllers\ExperienceController::class,'earn'])->middleware(['checkHeader','auth.app_users']);

Route::middleware(['checkHeader','auth.app_users'])->group(function(){
 Route::get('premium/status',[\App\Http\Controllers\PremiumController::class,'status']);
 Route::post('premium/settings',[\App\Http\Controllers\PremiumController::class,'settings']);
 Route::post('match/rewind',[MatchController::class,'rewind']);
 Route::get('account/wallet',[\App\Http\Controllers\CommerceController::class,'wallet']);
 Route::post('commerce/purchase',[\App\Http\Controllers\CommerceController::class,'purchase'])->middleware('throttle:money');
 Route::post('payments/topup',[\App\Http\Controllers\CommerceController::class,'topup'])->middleware('throttle:money');
 Route::post('payments/status',[\App\Http\Controllers\CommerceController::class,'status'])->middleware('throttle:money');
 Route::get('ads',[\App\Http\Controllers\CommerceAdminController::class,'ads']);
 Route::get('premium/content',[\App\Http\Controllers\CommerceAdminController::class,'content']);
 Route::get('premium/content/{id}/media',[\App\Http\Controllers\CommerceAdminController::class,'media'])->whereNumber('id');
});
Route::get('payments/pesapal/ipn',[\App\Http\Controllers\CommerceController::class,'ipn'])->middleware('throttle:60,1');
Route::get('payments/pesapal/return',[\App\Http\Controllers\CommerceController::class,'callback']);

Route::get('live/eligibility', [LiveApplicationController::class, 'eligibility'])->middleware(['checkHeader', 'auth.app_users']);

Route::middleware(['checkHeader','auth.app_users'])->group(function(){
 Route::get('places',[\App\Http\Controllers\PlaceController::class,'index']);
 Route::get('places/mine',[\App\Http\Controllers\PlaceController::class,'mine']);
 Route::post('places/submit',[\App\Http\Controllers\PlaceController::class,'submit'])->middleware('throttle:20,1');
 Route::get('places/{id}/slots',[\App\Http\Controllers\PlaceController::class,'slots'])->whereNumber('id');
 Route::get('reservations',[\App\Http\Controllers\PlaceController::class,'reservations']);
 Route::post('reservations/request',[\App\Http\Controllers\PlaceController::class,'reserve'])->middleware('throttle:20,1');
 Route::post('reservations/cancel',[\App\Http\Controllers\PlaceController::class,'cancel']);
});

Route::post('auth/phone/resolve',[\App\Http\Controllers\AuthController::class,'resolvePhone'])->middleware(['checkHeader','throttle:5,1']);

Route::get('chat/media/{id}',[\App\Http\Controllers\ChatController::class,'media'])->middleware(['checkHeader','auth.app_users'])->whereNumber('id');

Route::post('coins/share',[\App\Http\Controllers\CoinTransferController::class,'send'])->middleware(['checkHeader','auth.app_users','throttle:20,1']);

Route::middleware(['checkHeader','auth.app_users'])->group(function(){
 Route::get('earnings',[\App\Http\Controllers\EarningsController::class,'summary']);
 Route::post('earnings/apply',[\App\Http\Controllers\EarningsController::class,'apply'])->middleware('throttle:5,1');
 Route::post('earnings/withdraw',[\App\Http\Controllers\EarningsController::class,'request'])->middleware('throttle:money');
});

Route::post('notifications/device-token',[NotificationController::class,'deviceToken'])->middleware(['checkHeader','auth.app_users','throttle:10,1']);

Route::get('places/owner-reservations',[\App\Http\Controllers\PlaceController::class,'ownerReservations'])->middleware(['checkHeader','auth.app_users']);
