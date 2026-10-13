<?php

use App\Http\Controllers\DiamondPackController;
use App\Http\Controllers\InterestController;
use App\Http\Controllers\LanguageController;
use App\Http\Controllers\LiveApplicationController;
use App\Http\Controllers\LoginController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\OnboardingScreenController;
use App\Http\Controllers\PackageController;
use App\Http\Controllers\PagesController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\RedeemRequestsController;
use App\Http\Controllers\RelationshipGoalController;
use App\Http\Controllers\ReligionController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\UsersController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/
 

Route::get('/', [LoginController::class, 'landing'])->name('landing');
Route::get('admin/login', [LoginController::class, 'login'])->name('admin.login');
Route::post('loginForm', [LoginController::class, 'checkLogin'])->name('loginForm');
Route::post('forgotPasswordForm', [LoginController::class, 'forgotPasswordForm'])->middleware(['checkLogin', 'admin'])->name('forgotPasswordForm');
Route::post('changePassword', [SettingController::class, 'changePassword'])->middleware(['checkLogin', 'admin'])->name('changePassword');

// Route::post('loginForm', [LoginController::class, 'checklogin'])->middleware(['checkLogin', 'admin'])->name('loginForm');
Route::post('updateProflie', [LoginController::class, 'updateProflie'])->middleware(['checkLogin', 'admin'])->name('updateProflie');

Route::get('index', [LoginController::class, 'index'])->middleware(['checkLogin', 'admin'])->name('index');
Route::get('logout', [LoginController::class, 'logout'])->middleware(['checkLogin', 'admin'])->name('logout');

Route::get('deleteStoryFromWeb', [PostController::class, 'deleteStoryFromWeb'])->middleware(['checkLogin', 'admin'])->name('deleteStoryFromWeb');

/*|--------------------------------------------------------------------------|
  | users  Route                                                           |
  |--------------------------------------------------------------------------|*/

Route::view('users', 'users')->middleware(['checkLogin', 'admin'])->name('users');
Route::view('addFakeUser', 'addFakeUser')->middleware(['checkLogin', 'admin'])->name('addFakeUser');

Route::post('fetchAllUsers', [UsersController::class, 'fetchAllUsers'])->middleware(['checkLogin', 'admin'])->name('fetchAllUsers');
Route::post('updateUser', [UsersController::class, 'updateUser'])->middleware(['checkLogin', 'admin'])->name('updateUser');
Route::post('addUserImage', [UsersController::class, 'addUserImage'])->middleware(['checkLogin', 'admin'])->name('addUserImage');
Route::post('addFakeUserFromAdmin', [UsersController::class, 'addFakeUserFromAdmin'])->middleware(['checkLogin', 'admin'])->name('addFakeUserFromAdmin');
Route::post('fetchStreamerUsers', [UsersController::class, 'fetchStreamerUsers'])->middleware(['checkLogin', 'admin'])->name('fetchStreamerUsers');
Route::post('fetchFakeUsers', [UsersController::class, 'fetchFakeUsers'])->middleware(['checkLogin', 'admin'])->name('fetchFakeUsers');
Route::post('addCoinsToUserWalletFromAdmin', [UsersController::class, 'addCoinsToUserWalletFromAdmin'])->middleware(['checkLogin', 'admin'])->name('addCoinsToUserWalletFromAdmin');

Route::post('blockUser', [UsersController::class, 'blockUser'])->middleware(['checkLogin', 'admin'])->name('blockUser');
Route::get('deleteUserImage/{id}', [UsersController::class, 'deleteUserImage'])->middleware(['checkLogin', 'admin'])->name('deleteUserImage');
Route::post('unblockUser', [UsersController::class, 'unblockUser'])->middleware(['checkLogin', 'admin'])->name('unblockUser');
Route::get('viewUserDetails/{id}', [UsersController::class, 'viewUserDetails'])->middleware(['checkLogin', 'admin'])->name('viewUserDetails');
Route::post('allowLiveToUser', [UsersController::class, 'allowLiveToUser'])->middleware(['checkLogin', 'admin'])->name('allowLiveToUser');
Route::post('restrictLiveToUser', [UsersController::class, 'restrictLiveToUser'])->middleware(['checkLogin', 'admin'])->name('restrictLiveToUser');

/*|--------------------------------------------------------------------------|
  | package  Route                                                           |
  |--------------------------------------------------------------------------|*/

Route::view('package', 'package')->name('package')->middleware(['checkLogin', 'admin']);
Route::post('fetchAllPackage', [PackageController::class, 'fetchAllPackage'])->middleware(['checkLogin', 'admin'])->name('fetchAllPackage');
Route::post('addPackage', [PackageController::class, 'addPackage'])->middleware(['checkLogin', 'admin'])->name('addPackage');
Route::post('updatePackage', [PackageController::class, 'updatePackage'])->middleware(['checkLogin', 'admin'])->name('updatePackage');
Route::get('getPackageById/{id}', [PackageController::class, 'getPackageById'])->middleware(['checkLogin', 'admin'])->name('getPackageById');
Route::get('deletePackage/{id}', [PackageController::class, 'deletePackage'])->middleware(['checkLogin', 'admin'])->name('deletePackage');



/*|--------------------------------------------------------------------------|
  | Interests Route                                                           |
  |--------------------------------------------------------------------------|*/

Route::view('interest', 'interest')->middleware(['checkLogin', 'admin'])->name('interest');
Route::post('fetchAllInterest', [InterestController::class, 'fetchAllInterest'])->middleware(['checkLogin', 'admin'])->name('fetchAllInterest');
Route::post('addInterest', [InterestController::class, 'addInterest'])->middleware(['checkLogin', 'admin'])->name('addInterest');
Route::post('updateInterest', [InterestController::class, 'updateInterest'])->middleware(['checkLogin', 'admin'])->name('updateInterest');
Route::post('deleteInterest', [InterestController::class, 'deleteInterest'])->name('deleteInterest')->middleware(['checkLogin', 'admin']);


/*|--------------------------------------------------------------------------|
  | Report  Route                                                           |
  |--------------------------------------------------------------------------|*/

Route::view('report', 'report')->name('report')->middleware(['checkLogin', 'admin']);
Route::post('fetchUsersReport', [ReportController::class, 'fetchUsersReport'])->middleware(['checkLogin', 'admin'])->name('fetchUsersReport');
Route::post('postReportList', [ReportController::class, 'postReportList'])->middleware(['checkLogin', 'admin'])->name('postReportList');
Route::post('deleteReport', [ReportController::class, 'deleteReport'])->middleware(['checkLogin', 'admin'])->name('deleteReport');
Route::post('rejectUserReport', [ReportController::class, 'rejectUserReport'])->middleware(['checkLogin', 'admin'])->name('rejectUserReport');
Route::post('deletePostFromReport', [ReportController::class, 'deletePostFromReport'])->middleware(['checkLogin', 'admin'])->name('deletePostFromReport');

/*|--------------------------------------------------------------------------|
| Notification  Route
|--------------------------------------------------------------------------|*/
Route::get('notifications', [NotificationController::class, 'notifications'])->name('notifications')->middleware(['checkLogin', 'admin']);
Route::post('fetchAllNotification', [NotificationController::class, 'fetchAllNotification'])->name('fetchAllNotification')->middleware(['checkLogin', 'admin']);
Route::post('addNotification', [NotificationController::class, 'addNotification'])->name('addNotification')->middleware(['checkLogin', 'admin']);
Route::post('repeatNotification', [NotificationController::class, 'repeatNotification'])->name('repeatNotification')->middleware(['checkLogin', 'admin']);
Route::post('updateNotification', [NotificationController::class, 'updateNotification'])->name('updateNotification')->middleware(['checkLogin', 'admin']);
Route::post('deleteNotification', [NotificationController::class, 'deleteNotification'])->middleware(['checkLogin', 'admin'])->name('deleteNotification');
Route::get('getNotificationById/{id}', [NotificationController::class, 'getNotificationById'])->middleware(['checkLogin', 'admin'])->name('getNotificationById');

/*|--------------------------------------------------------------------------|
| Post Route
|--------------------------------------------------------------------------|*/
Route::get('posts', [PostController::class, 'posts'])->middleware(['checkLogin', 'admin'])->name('posts');
Route::post('postsList', [PostController::class, 'postsList'])->middleware(['checkLogin', 'admin'])->name('postsList');
Route::post('deletePostFromUserPostTable', [PostController::class, 'deletePostFromUserPostTable'])->middleware(['checkLogin', 'admin'])->name('deletePostFromUserPostTable');
Route::post('userPostList', [PostController::class, 'userPostList'])->middleware(['checkLogin', 'admin'])->name('userPostList');

/*|--------------------------------------------------------------------------|
  | Onboarding Route                                                           |
  |--------------------------------------------------------------------------|*/

  Route::view('onboarding', 'onboarding')->middleware(['checkLogin', 'admin'])->name('onboarding');
  Route::post('onboardingList', [OnboardingScreenController::class, 'onboardingList'])->middleware(['checkLogin', 'admin'])->name('onboardingList');
  Route::post('addOnboarding', [OnboardingScreenController::class, 'addOnboarding'])->middleware(['checkLogin', 'admin'])->name('addOnboarding');
  Route::post('updateOnboardingScreen', [OnboardingScreenController::class, 'updateOnboardingScreen'])->middleware(['checkLogin', 'admin'])->name('updateOnboardingScreen');
  Route::post('deleteOnboardingScreen', [OnboardingScreenController::class, 'deleteOnboardingScreen'])->name('deleteOnboardingScreen')->middleware(['checkLogin', 'admin']);
  Route::post('updateOnboardingOrder', [OnboardingScreenController::class, 'updateOnboardingOrder'])->name('updateOnboardingOrder')->middleware(['checkLogin', 'admin']);

/*|--------------------------------------------------------------------------|
| Relationship Goal Route
|--------------------------------------------------------------------------|*/

Route::view('relationshipGoals', 'relationshipGoals')->middleware(['checkLogin', 'admin'])->name('relationshipGoals');
Route::post('relationshipGoalList', [RelationshipGoalController::class, 'relationshipGoalList'])->name('relationshipGoalList')->middleware(['checkLogin', 'admin']);
Route::post('addRelationshipGoal', [RelationshipGoalController::class, 'addRelationshipGoal'])->name('addRelationshipGoal')->middleware(['checkLogin', 'admin']);
Route::post('updateRelationshipGoal', [RelationshipGoalController::class, 'updateRelationshipGoal'])->name('updateRelationshipGoal')->middleware(['checkLogin', 'admin']);
Route::post('deleteRelationshipGoal', [RelationshipGoalController::class, 'deleteRelationshipGoal'])->name('deleteRelationshipGoal')->middleware(['checkLogin', 'admin']);
  
/*|--------------------------------------------------------------------------|
| Religion Route
|--------------------------------------------------------------------------|*/

Route::view('religions', 'religions')->middleware(['checkLogin', 'admin'])->name('religions');
Route::post('religionList', [ReligionController::class, 'religionList'])->name('religionList')->middleware(['checkLogin', 'admin']);
Route::post('addReligion', [ReligionController::class, 'addReligion'])->name('addReligion')->middleware(['checkLogin', 'admin']);
Route::post('updateReligion', [ReligionController::class, 'updateReligion'])->name('updateReligion')->middleware(['checkLogin', 'admin']);
Route::post('deleteReligion', [ReligionController::class, 'deleteReligion'])->name('deleteReligion')->middleware(['checkLogin', 'admin']);
  
/*|--------------------------------------------------------------------------|
| Languages Route
|--------------------------------------------------------------------------|*/

Route::view('languages', 'languages')->middleware(['checkLogin', 'admin'])->name('languages');
Route::post('languageList', [LanguageController::class, 'languageList'])->name('languageList')->middleware(['checkLogin', 'admin']);
Route::post('addLanguage', [LanguageController::class, 'addLanguage'])->name('addLanguage')->middleware(['checkLogin', 'admin']);
Route::post('updateLanguage', [LanguageController::class, 'updateLanguage'])->name('updateLanguage')->middleware(['checkLogin', 'admin']);
Route::post('deleteLanguage', [LanguageController::class, 'deleteLanguage'])->name('deleteLanguage')->middleware(['checkLogin', 'admin']);
  
/*|--------------------------------------------------------------------------|
  | setting  Route                                                           |
  |--------------------------------------------------------------------------|*/

Route::get('setting', [SettingController::class, 'setting'])->name('setting')->middleware(['checkLogin', 'admin']);
Route::post('updateAppdata', [SettingController::class, 'updateAppdata'])->middleware(['checkLogin', 'admin'])->name('updateAppdata');
Route::post('androidDeepLinking', [SettingController::class, 'androidDeepLinking'])->middleware(['checkLogin', 'admin'])->name('androidDeepLinking');
Route::post('iOSDeepLinking', [SettingController::class, 'iOSDeepLinking'])->middleware(['checkLogin', 'admin'])->name('iOSDeepLinking');
Route::get('changeFromDatingAppToLivestreamApp/{value}', [SettingController::class, 'changeFromDatingAppToLivestreamApp'])->name('changeFromDatingAppToLivestreamApp')->middleware(['checkLogin', 'admin']);
Route::get('changeFromSocialMedia/{value}', [SettingController::class, 'changeFromSocialMedia'])->name('changeFromSocialMedia')->middleware(['checkLogin', 'admin']);
Route::get('includeFakeUserInMatching/{value}', [SettingController::class, 'includeFakeUserInMatching'])->name('includeFakeUserInMatching')->middleware(['checkLogin', 'admin']);

/*|--------------------------------------------------------------------------|
  | Diamond Pack  Route
  |--------------------------------------------------------------------------|*/

Route::get('diamondpacks', [DiamondPackController::class, 'diamondpacks'])->name('diamondpacks')->middleware(['checkLogin', 'admin']);
Route::post('fetchDiamondPackages', [DiamondPackController::class, 'fetchDiamondPackages'])->name('fetchDiamondPackages')->middleware(['checkLogin', 'admin']);
Route::post('addDiamondPack', [DiamondPackController::class, 'addDiamondPack'])->name('addDiamondPack')->middleware(['checkLogin', 'admin']);
Route::post('updateDiamondPack', [DiamondPackController::class, 'updateDiamondPack'])->name('updateDiamondPack')->middleware(['checkLogin', 'admin']);
Route::get('getDiamondPackById/{id}', [DiamondPackController::class, 'getDiamondPackById'])->name('getDiamondPackById')->middleware(['checkLogin', 'admin']);
Route::post('deleteDiamondPack', [DiamondPackController::class, 'deleteDiamondPack'])->name('deleteDiamondPack')->middleware(['checkLogin', 'admin']);

/*|--------------------------------------------------------------------------|
  | Gift  Route
  |--------------------------------------------------------------------------|*/

Route::get('gifts', [SettingController::class, 'gifts'])->name('gifts')->middleware(['checkLogin', 'admin']);
Route::post('fetchAllGifts', [SettingController::class, 'fetchAllGifts'])->name('fetchAllGifts')->middleware(['checkLogin', 'admin']);
Route::post('deleteGift', [SettingController::class, 'deleteGift'])->name('deleteGift')->middleware(['checkLogin', 'admin']);
Route::post('addGift', [SettingController::class, 'addGift'])->name('addGift')->middleware(['checkLogin', 'admin']);
Route::post('updateGift', [SettingController::class, 'updateGift'])->name('updateGift')->middleware(['checkLogin', 'admin']);


/*|--------------------------------------------------------------------------|
  | Livestream Application  Route
  |--------------------------------------------------------------------------|*/
Route::get('liveapplication', [LiveApplicationController::class, 'liveapplication'])->name('liveapplication')->middleware(['checkLogin', 'admin']);
Route::post('fetchLiveApplications', [LiveApplicationController::class, 'fetchLiveApplications'])->name('fetchLiveApplications')->middleware(['checkLogin', 'admin']);
Route::post('fetchLiveHistory', [LiveApplicationController::class, 'fetchLiveHistory'])->name('fetchLiveHistory')->middleware(['checkLogin', 'admin']);
Route::post('deleteLiveApplication', [LiveApplicationController::class, 'deleteLiveApplication'])->name('deleteLiveApplication')->middleware(['checkLogin', 'admin']);
Route::post('approveApplication', [LiveApplicationController::class, 'approveApplication'])->name('approveApplication')->middleware(['checkLogin', 'admin']);
Route::get('viewLiveApplication/{id}', [LiveApplicationController::class, 'viewLiveApplication'])->name('viewLiveApplication')->middleware(['checkLogin', 'admin']);
Route::get('livehistory', [LiveApplicationController::class, 'livehistory'])->name('livehistory')->middleware(['checkLogin', 'admin']);

/*|--------------------------------------------------------------------------|
  | Redeem Requests Features Route
  |--------------------------------------------------------------------------|*/
Route::get('redeemrequests', [RedeemRequestsController::class, 'redeemrequests'])->name('redeemrequests')->middleware(['checkLogin', 'admin']);
Route::post('fetchPendingRedeems', [RedeemRequestsController::class, 'fetchPendingRedeems'])->name('fetchPendingRedeems')->middleware(['checkLogin', 'admin']);
Route::post('fetchCompletedRedeems', [RedeemRequestsController::class, 'fetchCompletedRedeems'])->name('fetchCompletedRedeems')->middleware(['checkLogin', 'admin']);
Route::post('completeRedeem', [RedeemRequestsController::class, 'completeRedeem'])->name('completeRedeem')->middleware(['checkLogin', 'admin']);
Route::post('deleteRedeemRequest', [RedeemRequestsController::class, 'deleteRedeemRequest'])->name('deleteRedeemRequest')->middleware(['checkLogin', 'admin']);
Route::get('getRedeemById/{id}', [RedeemRequestsController::class, 'getRedeemById'])->name('getRedeemById')->middleware(['checkLogin', 'admin']);
Route::post('reconcilePayouts', [RedeemRequestsController::class, 'reconcilePayouts'])->name('reconcilePayouts')->middleware(['checkLogin', 'admin']);

/*|--------------------------------------------------------------------------|
| Verification Requests
|--------------------------------------------------------------------------|*/
Route::get('verificationrequests', [UsersController::class, 'verificationrequests'])->name('verificationrequests')->middleware(['checkLogin', 'admin']);
Route::post('fetchverificationRequests', [UsersController::class, 'fetchverificationRequests'])->name('fetchverificationRequests')->middleware(['checkLogin', 'admin']);
Route::post('rejectVerificationRequest', [UsersController::class, 'rejectVerificationRequest'])->middleware(['checkLogin', 'admin'])->name('rejectVerificationRequest');
Route::post('approveVerificationRequest', [UsersController::class, 'approveVerificationRequest'])->middleware(['checkLogin', 'admin'])->name('approveVerificationRequest');


/*|--------------------------------------------------------------------------|
| Story Web 
|--------------------------------------------------------------------------|*/
Route::get('viewStories', [PostController::class, 'viewStories'])->middleware(['checkLogin', 'admin'])->name('viewStories');
Route::post('userStoryList', [PostController::class, 'userStoryList'])->middleware(['checkLogin', 'admin'])->name('userStoryList');
Route::post('allStoriesList', [PostController::class, 'allStoriesList'])->middleware(['checkLogin', 'admin'])->name('allStoriesList');
Route::post('deleteStoryFromAdmin', [PostController::class, 'deleteStoryFromAdmin'])->middleware(['checkLogin', 'admin'])->name('deleteStoryFromAdmin');


Route::post('deleteUserFromAdmin', [UsersController::class, 'deleteUserFromAdmin'])->middleware(['checkLogin', 'admin'])->name('deleteUserFromAdmin');

Route::post('fetchChartData', [SettingController::class, 'fetchChartData'])->middleware(['checkLogin', 'admin'])->name('fetchChartData');

// Pages Routes
Route::get('viewPrivacy', [PagesController::class, 'viewPrivacy'])->middleware(['checkLogin', 'admin'])->name('viewPrivacy');
Route::post('updatePrivacy', [PagesController::class, 'updatePrivacy'])->middleware(['checkLogin', 'admin'])->name('updatePrivacy');
Route::get('viewTerms', [PagesController::class, 'viewTerms'])->middleware(['checkLogin', 'admin'])->name('viewTerms');
Route::post('updateTerms', [PagesController::class, 'updateTerms'])->middleware(['checkLogin', 'admin'])->name('updateTerms');
Route::get('privacypolicy', [PagesController::class, 'privacypolicy'])->name('privacypolicy');
Route::get('termsOfUse', [PagesController::class, 'termsOfUse'])->name('termsOfUse');
Route::get('csae-standards', [PagesController::class, 'csae'])->name('csae');

// Data Deletion Request Routes
Route::get('data-deletion', [\App\Http\Controllers\DataDeletionController::class, 'create'])->name('dataDeletion.create');
Route::post('data-deletion', [\App\Http\Controllers\DataDeletionController::class, 'store'])->name('dataDeletion.store');
Route::get('data-deletion-admin', [\App\Http\Controllers\DataDeletionController::class, 'index'])->middleware(['checkLogin', 'admin'])->name('dataDeletion.admin');
Route::post('data-deletion-admin/status/{id}', [\App\Http\Controllers\DataDeletionController::class, 'updateStatus'])->middleware(['checkLogin', 'admin'])->name('dataDeletion.updateStatus');
Route::get('data-deletion-admin/lookup', [\App\Http\Controllers\DataDeletionController::class, 'lookupUser'])->middleware(['checkLogin', 'admin'])->name('dataDeletion.lookupUser');

Route::get('plan-catalog', [\App\Http\Controllers\PlanCatalogController::class, 'index'])->middleware(['checkLogin','admin'])->name('planCatalog');
Route::post('plan-catalog/currency', [\App\Http\Controllers\PlanCatalogController::class, 'currency'])->middleware(['checkLogin','admin'])->name('planCatalog.currency');
Route::post('plan-catalog/price', [\App\Http\Controllers\PlanCatalogController::class, 'price'])->middleware(['checkLogin','admin'])->name('planCatalog.price');

Route::get('verification-media/{id}/{kind}', [UsersController::class, 'verificationMedia'])->whereNumber('id')->whereIn('kind', ['document','selfie'])->middleware(['checkLogin','admin'])->name('verificationMedia');

Route::get('experiences-admin', [\App\Http\Controllers\ExperienceController::class,'admin'])->middleware(['checkLogin','admin'])->name('experiences.admin');
Route::post('experiences-admin', [\App\Http\Controllers\ExperienceController::class,'save'])->middleware(['checkLogin','admin'])->name('experiences.save');

Route::middleware(['checkLogin','admin'])->group(function(){
 Route::get('premium-commerce',[\App\Http\Controllers\CommerceAdminController::class,'index'])->name('premiumCommerce');
 Route::post('premium-commerce/rules',[\App\Http\Controllers\CommerceAdminController::class,'rules'])->name('premiumCommerce.rules');
 Route::post('premium-commerce/pack',[\App\Http\Controllers\CommerceAdminController::class,'pack'])->name('premiumCommerce.pack');
 Route::post('premium-commerce/ad',[\App\Http\Controllers\CommerceAdminController::class,'ad'])->name('premiumCommerce.ad');
 Route::post('premium-commerce/content',[\App\Http\Controllers\CommerceAdminController::class,'contentSave'])->name('premiumCommerce.content');
});

Route::middleware(['checkLogin','admin'])->group(function(){
 Route::get('places-admin',[\App\Http\Controllers\PlaceController::class,'admin'])->name('places.admin');
 Route::post('places-admin',[\App\Http\Controllers\PlaceController::class,'save'])->name('places.save');
 Route::post('places-admin/slot',[\App\Http\Controllers\PlaceController::class,'slotSave'])->name('places.slot');
 Route::post('places-admin/reservation',[\App\Http\Controllers\PlaceController::class,'review'])->name('places.review');
});

Route::middleware(['checkLogin','admin'])->group(function(){
 Route::get('earnings-admin',[\App\Http\Controllers\EarningsController::class,'admin'])->name('earnings.admin');
 Route::post('earnings-admin/account',[\App\Http\Controllers\EarningsController::class,'account'])->name('earnings.account');
 Route::post('earnings-admin/release',[\App\Http\Controllers\EarningsController::class,'release'])->name('earnings.release');
 Route::post('earnings-admin/review',[\App\Http\Controllers\EarningsController::class,'review'])->name('earnings.review');
 Route::get('earnings-admin/destination/{id}',[\App\Http\Controllers\EarningsController::class,'destination'])->name('earnings.destination');
});

Route::post('earnings-admin/policy',[\App\Http\Controllers\EarningsController::class,'policy'])->middleware(['checkLogin','admin'])->name('earnings.policy');
