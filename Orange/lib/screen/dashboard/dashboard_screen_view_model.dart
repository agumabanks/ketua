import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/social/post/add_post.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/screen/live_grid_screen/live_grid_screen.dart';
import 'package:ketua_ui/screen/notification_screen/notification_screen.dart';
import 'package:ketua_ui/screen/search_screen/search_screen.dart';
import 'package:ketua_ui/screen/single_post_screen/single_post_screen.dart';
import 'package:ketua_ui/screen/subscription_sheet/subscription_sheet_controller.dart';
import 'package:ketua_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/service/share_manager.dart';
import 'package:ketua_ui/service/subscription/subscription_manager.dart';
import 'package:ketua_ui/utils/urls.dart';
import 'package:stacked/stacked.dart';

class DashboardScreenViewModel extends BaseViewModel with WidgetsBindingObserver {
  Timer? _presenceTimer;
  bool _presenceBusy = false;
  bool _closed = false;
  int incomingLikes = 0;
  DateTime? _lastPing;
  Future<void> _prefetchInbox() async {
    final owner=SessionManager.instance.getUserID();
    try {
      final r=await Future.wait([ApiProvider().chatConversations(),ApiProvider().myMatches()]).timeout(const Duration(seconds:15));
      if(_closed || owner!=SessionManager.instance.getUserID() || r.any((v)=>v['status']!=true)) return;
      await SessionManager.instance.writeSnapshot('inbox',{'conversations':r[0]['data']??[],'matches':r[1]['data']??[]});
    } catch(_) {}
  }
  Future<void> _ping() async {
    if (_presenceBusy || _closed || WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) return;
    if(_lastPing!=null && DateTime.now().difference(_lastPing!)<const Duration(seconds:45))return;
    _lastPing=DateTime.now();
    _presenceBusy = true;
    try {
      await ApiProvider().heartbeat().timeout(const Duration(seconds: 12));
      final count = await ApiProvider().incomingLikesCount().timeout(const Duration(seconds: 12));
      if (!_closed && count != incomingLikes) { incomingLikes = count; notifyListeners(); }
    } catch (_) {}
    finally { _presenceBusy = false; }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _presenceTimer?.cancel();
    if (state == AppLifecycleState.resumed) {
      _ping();
      _presenceTimer = Timer.periodic(const Duration(minutes: 2), (_) => _ping());
    }
  }
  @override
  void dispose() {
    _closed = true;
    _presenceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  int pageIndex = 0;
  UserData? userData;

  Appdata? settingAppData = SessionManager.instance.getSettings()?.appdata;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    didChangeAppLifecycleState(AppLifecycleState.resumed);
    AppBadgePlus.updateBadge(0).catchError((_) {});
    initBranch();
    userData=SessionManager.instance.getUser();
    getProfileApiCall();
    _prefetchInbox();
  }

  void getProfileApiCall() {
    ApiProvider()
        .getProfile(userID: SessionManager.instance.getUserID())
        .then((value) {
      if(_closed)return;
      if(value.status==true && value.data!=null)userData = value.data;
      notifyListeners();
    });
    notifyListeners();
    final isRegister = Get.isRegistered<CreateProfileScreenViewModel>();
    if (isRegister) {
      Get.delete<CreateProfileScreenViewModel>();
    }
    SubscriptionManager.shared.subscriptionListener();
    Get.put(SubscriptionSheetController());
  }

  void onBottomBarTap(int index) {
    _ping();
    if (userData?.isBlock == 1 && index == 4) {
      pageIndex = index;
    } else {
      CommonFun.isBloc(
        userData,
        onCompletion: () {
          pageIndex = index;
        },
      );
    }
    notifyListeners();
  }

  void initBranch() {
    ShareManager.shared.listen((key, value) {
      switch (key) {
        case ShareKeys.post:
          ApiProvider().callPost(
              completion: (response) {
                AddPost post = AddPost.fromJson(response);
                if (post.status == true) {
                  Get.to(() => SinglePostScreen(post: post.data));
                } else {
                  CommonUI.snackBar(message: post.message ?? '');
                }
              },
              url: Urls.aFetchPostByPostId,
              param: {Urls.userId: SessionManager.instance.getUserID().toString(), Urls.aPostId: value});
        case ShareKeys.user:
          Get.to(() => UserDetailScreen(userId: value));
      }
    });
  }

  void onNotificationTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => const NotificationScreen());
      },
    );
  }

  void onLivesBtnClick() {
    Get.to(() => const LiveGridScreen());
  }

  void onSearchTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => const SearchScreen());
      },
    );
  }
}

class ImageText {
  final String image;
  final String title;

  ImageText(this.image, this.title);
}
