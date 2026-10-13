import 'package:ketua_ui/screen/commerce/commerce_api.dart';
import 'package:ketua_ui/screen/commerce/super_likes_screen.dart';
import 'package:ketua_ui/service/share_manager.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/common/location_sheet.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/map_screen/map_screen.dart';
import 'package:ketua_ui/screen/subscription_sheet/subscription_sheet_controller.dart';
import 'package:ketua_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/service/subscription/subscription_manager.dart';
import 'package:ketua_ui/utils/app_res.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploreScreenViewModel extends BaseViewModel {
  ExploreScreenViewModel(
      {Future<Map<String, dynamic>> Function(int, bool)? saveSwipe})
      : _saveSwipeRequest = saveSwipe;
  final Future<Map<String, dynamic>> Function(int, bool)? _saveSwipeRequest;
  final Set<int> _pendingSwipes = {};
  final Map<int, bool> _failedSwipes = {};
  final Map<int, UserData> _swipeProfiles = {};
  int get pendingSwipeCount => _pendingSwipes.length;
  int get failedSwipeCount => _failedSwipes.length;
  bool _disposed = false;
  bool _fetchingProfiles = false;
  bool _allowanceBusy = false;
  bool _adsSuppressed = false;
  int _profileGeneration = 0;
  String? _savedPreferences;
  String _preferences() {
    final u = SessionManager.instance.getUser();
    return '${u?.genderPreferred.value}|${u?.agePreferredMin}|${u?.agePreferredMax}|${u?.distancePreference}';
  }

  void _activated() {
    if (SessionManager.instance.activeTab.value != 0 || _disposed) return;
    if (_savedPreferences != _preferences()) resetDiscovery();
    unawaited(_refreshAllowance());
  }

  void resetDiscovery() {
    _savedPreferences = _preferences();
    _profileGeneration++;
    combinedList.clear();
    currentCombinedIndex = 0;
    deckExhausted = false;
    deckRevision++;
    disposePageControllers();
    notifyListeners();
    unawaited(exploreScreenApiCall());
  }

  Future<void> _refreshAllowance() async {
    if (_allowanceBusy || _disposed) return;
    _allowanceBusy = true;
    try {
      final r = await commerceRequest('premium/status');
      if (_disposed || r['status'] != true) return;
      if (_pendingSwipes.isEmpty)
        _likesRemaining = r['data']?['session_likes_remaining'];
      if (r['data']?['hide_ads'] != true && _adsSuppressed) {
        _adsLoaded = false;
        _adsSuppressed = false;
      }
      if (r['data']?['hide_ads'] == true) {
        _adsSuppressed = true;
        _catalogAds = [];
        _adsLoaded = true;
        final before = combinedList
            .take(currentCombinedIndex)
            .where((p) => p.id == -2)
            .length;
        final hadAds = combinedList.any((p) => p.id == -2);
        combinedList.removeWhere((p) => p.id == -2);
        if (hadAds) {
          currentCombinedIndex = (currentCombinedIndex - before)
              .clamp(0, combinedList.length)
              .toInt();
          deckExhausted = currentCombinedIndex >= combinedList.length;
          deckRevision++;
        }
      }
      notifyListeners();
    } catch (_) {
      /* Server still authorizes every swipe. Keep the deck visible. */
    } finally {
      _allowanceBusy = false;
    }
  }

  bool deckExhausted = false;
  int deckRevision = 0;

  bool isLoading = false;
  int walletCoin = 0;
  UserData? userData;
  bool isCheckboxSelected = false;
  int count = 0;
  int? _likesRemaining;
  List<Map<String, dynamic>> _catalogAds = [];
  bool _adsLoaded = false;
  int suggestSwipeStatus = 0;
  int suggestPhotoTapStatus = 0;
  bool isSwipeDisable = true;
  int currentCombinedIndex = 0;
  Appdata? settingAppData;
  int likeStatus = 0;
  CardSwiperController cardController = CardSwiperController();
  bool isLikeDisLikeStatus = false;
  final controller = Get.find<SubscriptionSheetController>();
  List<UserData> combinedList = [];

  void onShareTap() {
    if (currentCombinedIndex < 0 || currentCombinedIndex >= combinedList.length)
      return;
    final id = combinedList[currentCombinedIndex].id;
    if (id == null || id <= 0) return;
    ShareManager.shared.shareTheContent(key: ShareKeys.user, value: id);
  }

  Future<void> onBoostTap() async {
    if (_actionInFlight) return;
    try {
      final status = await ApiProvider()
          .boostStatus()
          .timeout(const Duration(seconds: 12));
      if (status['status'] != true) {
        CommonUI.snackBarWidget('Unable to load Boost.');
        return;
      }
      final price = num.tryParse('${status['coin_price']}');
      if (price == null || price <= 0) {
        CommonUI.snackBarWidget('Boost pricing is not configured yet.');
        return;
      }
      final confirmed = await Get.dialog<bool>(AlertDialog(
        title: const Text('Boost your profile'),
        content: Text(
            '${status['duration_minutes']} minutes • $price coins\nBalance: ${status['wallet']} coins${status['active'] == true ? "\nAn active Boost will be extended." : ""}'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Activate Boost'))
        ],
      ));
      if (confirmed != true) return;
      _actionInFlight = true;
      final result = await ApiProvider()
          .activateBoost()
          .timeout(const Duration(seconds: 12));
      CommonUI.snackBarWidget(
          result['message']?.toString() ?? 'Unable to activate Boost.');
      walletCoin = int.tryParse('${result['wallet']}') ?? walletCoin;
      notifyListeners();
    } catch (_) {
      CommonUI.snackBarWidget('Connection interrupted. Try again.');
    } finally {
      _actionInFlight = false;
    }
  }

  void init() {
    _savedPreferences = _preferences();
    SessionManager.instance.activeTab.addListener(_activated);
    initialCalling();
  }

  // your existing fields...
  final Map<int, PageController> _pageControllers = {};

  /// Returns the page controller for the given card index.
  PageController getPageController(int index) {
    return _pageControllers.putIfAbsent(
        index, () => PageController(initialPage: 0));
  }

  /// Dispose all controllers when screen is disposed
  void disposePageControllers() {
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    _pageControllers.clear();
  }

  /// Reset page to 0 when card becomes visible
  void resetPageAt(int index) {
    if (_pageControllers.containsKey(index)) {
      if (_pageControllers[index]!.hasClients)
        _pageControllers[index]!.jumpToPage(0);
    }
  }

  void initialCalling() {
    prefSetting();
    exploreScreenApiCall();
    getProfileAPi();
    controller.purchaseCallBack = () {
      combinedList.removeWhere((element) => element.id == -1);
      notifyListeners();
    };
  }

  void prefSetting() async {
    settingAppData = SessionManager.instance.getSettings()?.appdata;
    notifyListeners();
    suggestSwipeStatus =
        SessionManager.instance.getInt(key: SessionKeys.suggestSwipe);
    suggestPhotoTapStatus =
        SessionManager.instance.getInt(key: SessionKeys.suggestPhotoTap);
    if (suggestSwipeStatus == 1 && suggestPhotoTapStatus == 1) {
      isSwipeDisable = false;
      notifyListeners();
    }
  }

  Future<void> exploreScreenApiCall() async {
    if (_fetchingProfiles || _disposed) return;
    _fetchingProfiles = true;
    final generation = _profileGeneration;
    if (combinedList.isEmpty) isLoading = true;
    try {
      final value = await ApiProvider()
          .getExplorePageProfileList(
              excludeIds: combinedList
                  .where((p) => (p.id ?? 0) > 0)
                  .map((p) => p.id!)
                  .toList())
          .timeout(const Duration(seconds: 15));
      if (_disposed || generation != _profileGeneration) return;
      final known = combinedList.map((p) => p.id).toSet();
      final newData = (value.data ?? [])
          .where((p) =>
              p.id != null &&
              p.id != SessionManager.instance.getUserID() &&
              known.add(p.id))
          .toList();
      if (deckExhausted && newData.isNotEmpty) {
        currentCombinedIndex = combinedList.length;
        deckExhausted = false;
        deckRevision++;
      }
      List<Map<String, dynamic>> ads = _catalogAds;
      if (!_adsLoaded)
        try {
          final r = await commerceRequest('ads?placement=swipe');
          ads = List<Map<String, dynamic>>.from(r['data'] ?? []);
          _catalogAds = ads;
          _adsLoaded = true;
        } catch (_) {}
      if (_disposed || generation != _profileGeneration) return;
      var realCount = combinedList.where((p) => p.id != -1).length;
      for (final profile in newData) {
        combinedList.add(profile);
        realCount++;
        if (ads.isNotEmpty && realCount % 6 == 0) {
          final card = UserData(id: -2);
          card.sponsoredAd = ads[(realCount ~/ 6 - 1) % ads.length];
          combinedList.add(card);
        }
        if (isPurchaseConfig &&
            SubscriptionManager.shared.packages.isNotEmpty &&
            !isSubscribe.value &&
            realCount % 5 == 0) combinedList.add(UserData(id: -1));
      }
    } catch (_) {
      if (!_disposed && combinedList.isEmpty)
        CommonUI.snackBarWidget('Unable to load profiles. Try again.');
    } finally {
      _fetchingProfiles = false;
      if (!_disposed && generation != _profileGeneration)
        unawaited(exploreScreenApiCall());
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void onDeckEnd() {
    deckExhausted = true;
    notifyListeners();
  }

  Future<void> _saveOrdinarySwipe(UserData profile, bool like) async {
    final id = profile.id!;
    _swipeProfiles[id] = profile;
    _pendingSwipes.add(id);
    _failedSwipes.remove(id);
    try {
      final result = await (_saveSwipeRequest != null
              ? _saveSwipeRequest!(id, like)
              : _requestOrdinarySwipe(id, like))
          .timeout(const Duration(seconds: 15));
      if (result['status'] != true &&
          !(like && result['message'] == 'Already liked.') &&
          !(!like && result['message'] == 'Already Disliked Profile!')) {
        if (!_disposed && result['limit_reached'] == true) {
          _likesRemaining = 0;
          CommonUI.snackBarWidget('${result['message']}');
        }
        throw StateError('Swipe rejected');
      }
      profile.isLiked = like;
      if (!_disposed && result['matched'] == true)
        CommonUI.snackBarWidget(S.current.itsAMatch);
    } catch (_) {
      _failedSwipes[id] = like;
    } finally {
      _pendingSwipes.remove(id);
      if (!_failedSwipes.containsKey(id)) _swipeProfiles.remove(id);
      if (!_disposed) notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _requestOrdinarySwipe(int id, bool like) async {
    if (like) return ApiProvider().matchLike(id);
    final result = await ApiProvider().dislikedProfile(id);
    return {'status': result.status, 'message': result.message};
  }

  void retryFailedSwipes() {
    for (final entry in _failedSwipes.entries.toList()) {
      final profile = _swipeProfiles[entry.key];
      if (profile != null && !_pendingSwipes.contains(entry.key)) {
        unawaited(_saveOrdinarySwipe(profile, entry.value));
      }
    }
    notifyListeners();
  }

  Future<void> getProfileAPi() async {
    ApiProvider()
        .getProfile(userID: SessionManager.instance.getUserID())
        .then((value) async {
      userData = value.data;
      walletCoin = value.data?.wallet ?? 0;
      notifyListeners();
      try {
        final premium = await commerceRequest('premium/status');
        _likesRemaining = premium['data']?['session_likes_remaining'];
      } catch (_) {}
      if (settingAppData?.isDating == 1) {
        final hasOpenedLocationSheet = SessionManager.instance
            .getBool(key: SessionKeys.hasOpenedLocationSheet);

        final isUserLocationMissing =
            userData?.latitude == null || userData?.longitude == null;

        if (!hasOpenedLocationSheet && isUserLocationMissing) {
          locationSheet();
          SessionManager.instance
              .setBool(key: SessionKeys.hasOpenedLocationSheet, value: true);
        } else {
          await CommonFun.getUserCurrentLocation(requestPermission: false);
        }
      }
    });
    isCheckboxSelected =
        SessionManager.instance.getBool(key: SessionKeys.isDialogDialog);
  }

  void locationSheet() {
    Get.bottomSheet(const LocationSheet(),
        isScrollControlled: true, enableDrag: false);
  }

  bool isSocialBtnVisible(String? socialLink) {
    if (socialLink != null) {
      return socialLink.contains(AppRes.isHttp) ||
          socialLink.contains(AppRes.isHttps);
    } else {
      return false;
    }
  }

  Future<void> minusCoinApi() async {
    walletCoin -= (settingAppData?.reverseSwipePrice ?? 0);
    await ApiProvider()
        .minusCoinFromWallet(settingAppData?.reverseSwipePrice)
        .then((value) {
      if (value.status == false) {
        walletCoin += (settingAppData?.reverseSwipePrice ?? 0);
        notifyListeners();
      }
    });
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw '${S.current.couldNotLaunch} ';
    }
  }

  void onSocialBtnTap(int type) {
    if (type == 0) {
      _launchUrl(combinedList[currentCombinedIndex].youtube ?? '');
    } else if (type == 1) {
      _launchUrl(combinedList[currentCombinedIndex].facebook ?? '');
    } else if (type == 2) {
      _launchUrl(combinedList[currentCombinedIndex].instagram ?? '');
    }
  }

  void _suggestView() {
    if (suggestSwipeStatus == 0) {
      onTapSwipeView();
    } else if (suggestSwipeStatus == 1 && suggestPhotoTapStatus == 0) {
      onSuggestPhotoTap(true);
    } else if (suggestSwipeStatus == 1 && suggestPhotoTapStatus == 1) {
      isSwipeDisable = false;
      notifyListeners();
    }
  }

  void onReverseBtnTap() async {
    if (currentCombinedIndex <= 0 ||
        currentCombinedIndex > combinedList.length ||
        _actionInFlight ||
        _pendingSwipes.isNotEmpty) return;
    final target = combinedList[currentCombinedIndex - 1];
    if ((target.id ?? 0) < 0) {
      cardController.undo();
      return;
    }
    _actionInFlight = true;
    notifyListeners();
    try {
      final r =
          await commerceRequest('match/rewind', body: {'user_id': target.id});
      if (_disposed) return;
      if (r['status'] == true) {
        target.isLiked = false;
        cardController.undo();
      } else
        CommonUI.snackBarWidget('${r['message'] ?? 'Unable to rewind'}');
    } catch (_) {
      if (!_disposed) CommonUI.snackBarWidget('Rewind unavailable. Try again.');
    } finally {
      _actionInFlight = false;
      if (!_disposed) notifyListeners();
    }
  }

  void onIndexChange(int index) {
    currentCombinedIndex = index;
    notifyListeners();
  }

  void onTitleTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => const MapScreen());
      },
    );
  }

  void onImageTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => UserDetailScreen(
            userData: combinedList[currentCombinedIndex],
            onUpdateUser: (userData) {
              _toggleLikeStatus(userData?.isLiked ?? false);
            }));
      },
    );
  }

  bool onUndo(
      int? previousIndex, int currentIndex, CardSwiperDirection direction) {
    currentCombinedIndex = currentIndex;
    notifyListeners();
    return true;
  }

  bool _actionInFlight = false;
  bool get actionPending => _actionInFlight;

  Future<bool> onSwipe(int previousIndex, int? currentIndex,
      CardSwiperDirection direction) async {
    if (_actionInFlight ||
        userData?.isBlock == 1 ||
        previousIndex >= combinedList.length) return false;
    final profile = combinedList[previousIndex];
    if ((profile.id ?? 0) > 0 && direction != CardSwiperDirection.top) {
      if (direction == CardSwiperDirection.right &&
          _likesRemaining != null &&
          _likesRemaining! <= 0) {
        CommonUI.snackBarWidget(
            'Session like limit reached. Upgrade for unlimited likes.');
        return false;
      }
      if (direction == CardSwiperDirection.right && _likesRemaining != null)
        _likesRemaining = _likesRemaining! - 1;
      if (profile.id == null ||
          _pendingSwipes.contains(profile.id) ||
          _pendingSwipes.length >= 8) return false;
      unawaited(
          _saveOrdinarySwipe(profile, direction == CardSwiperDirection.right));
    }
    if ((profile.id ?? 0) > 0 && direction == CardSwiperDirection.top) {
      _actionInFlight = true;
      notifyListeners();
      try {
        if (direction == CardSwiperDirection.top) {
          final result = await ApiProvider()
              .starProfile(profile.id)
              .timeout(const Duration(seconds: 15));
          if (result['status'] != true) {
            CommonUI.snackBarWidget(
                result['message']?.toString() ?? 'Could not send Super Like.');
            if ('${result['message']}'.contains('Get Super Likes'))
              await Get.to(() => const SuperLikesScreen());
            return false;
          }
          walletCoin = int.tryParse('${result['wallet']}') ?? walletCoin;
          CommonUI.snackBarWidget(result['matched'] == true
              ? S.current.itsAMatch
              : 'Super Like sent!');
        }
      } catch (_) {
        CommonUI.snackBarWidget('Connection interrupted. Try again.');
        return false;
      } finally {
        _actionInFlight = false;
        if (!_disposed) notifyListeners();
      }
    }
    currentCombinedIndex = currentIndex ?? combinedList.length;
    notifyListeners();
    if (combinedList.length - currentCombinedIndex <= 3) exploreScreenApiCall();
    return true;
  }

  void onLikeDislikeTap(bool isLikeAction) {
    _suggestView();
    if (isSwipeDisable || _actionInFlight || combinedList.isEmpty) return;
    cardController.swipe(
        isLikeAction ? CardSwiperDirection.right : CardSwiperDirection.left);
  }

  void onStarTap() {
    _suggestView();
    if (isSwipeDisable || _actionInFlight || combinedList.isEmpty) return;
    cardController.swipe(CardSwiperDirection.top);
  }

  void _toggleLikeStatus(bool isLike) {
    for (var element in combinedList) {
      if (element.id == combinedList[currentCombinedIndex].id) {
        element.isLiked = isLike;
      }
    }
    notifyListeners();
  }

  void onSuggestPhotoTap(bool value, {bool isSwipe = false}) {
    isSwipeDisable = value;
    suggestPhotoTapStatus = 1;
    if (isSwipe) {
      isSwipeDisable = false;
    }
    notifyListeners();
    SessionManager.instance.setInt(key: SessionKeys.suggestPhotoTap, value: 1);
  }

  void onTapSwipeView() {
    suggestSwipeStatus = 1;
    notifyListeners();
    SessionManager.instance.setInt(key: SessionKeys.suggestSwipe, value: 1);
  }

  void onImageLeftTap(PageController pageController, int currentImageIndex) {
    if (currentImageIndex == 0) return;
    pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  void onImageRightTap(
      PageController pageController, int currentImageIndex, int imageLength) {
    if (imageLength - 1 == currentImageIndex) return;
    pageController.nextPage(
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  @override
  void dispose() {
    _disposed = true;
    SessionManager.instance.activeTab.removeListener(_activated);
    cardController.dispose();
    disposePageControllers();

    super.dispose();
  }
}
