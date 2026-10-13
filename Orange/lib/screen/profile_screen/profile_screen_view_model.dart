import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/edit_profile_screen/edit_profile_screen.dart';
import 'package:ketua_ui/screen/options_screen/options_screen.dart';
import 'package:ketua_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreenViewModel extends BaseViewModel {
  UserData? userData;
  bool isLoading = false;
  bool _fetching=false,_disposed=false;
  void _activated(){if(SessionManager.instance.activeTab.value==4){userData=SessionManager.instance.getUser();notifyListeners();profileScreenApiCall();}}
  int currentImageIndex = 0;
  PageController pageController = PageController();
  Appdata? settingAppData;

  void init() {
    pageController = PageController(initialPage: 0, viewportFraction: 1.01)
      ..addListener(() {
        onMainImageChange();
      });
    SessionManager.instance.activeTab.addListener(_activated);
    userData = SessionManager.instance.getUser();
    getSettingData();
    profileScreenApiCall();
  }

  Future<void> profileScreenApiCall() async {
    if(_fetching || _disposed)return; _fetching=true;
    isLoading=userData==null;
    try {
      final value=await ApiProvider().getProfile(userID:SessionManager.instance.getUserID()).timeout(const Duration(seconds:15));
      if(_disposed)return;
      if(value.status==true && value.data!=null)userData=value.data;
    } catch(_) { /* Keep the saved profile visible during an outage. */ }
    finally {_fetching=false;if(!_disposed){isLoading=false;notifyListeners();}}
  }
  @override void dispose(){_disposed=true;SessionManager.instance.activeTab.removeListener(_activated);pageController.dispose();super.dispose();}

  void onEditProfileTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to<UserData>(() => EditProfileScreen(userData: userData))
            ?.then((value) {
          final updated = value ?? SessionManager.instance.getUser();
          if (updated != null) {
            if (updated.id == SessionManager.instance.getUserID()) {
              userData = updated;
              notifyListeners();
            }
          }
        });
      },
    );
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch ';
  }

  bool isSocialBtnVisible(String? socialLink) {
    if (socialLink != null) {
      return socialLink.contains("https://");
    } else {
      return false;
    }
  }

  void onSocialBtnTap(String? value) {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        _launchUrl(value ?? '');
      },
    );
  }

  void onMainImageChange() {
    if (pageController.page!.round() != currentImageIndex) {
      currentImageIndex = pageController.page!.round();
      notifyListeners();
    }
  }

  void onImageTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => UserDetailScreen(userData: userData));
      },
    );
  }

  void onMoreBtnTap() {
    Get.to(() => const OptionScreen())?.then((value) {
      userData = SessionManager.instance.getUser();
      notifyListeners();
    });
  }

  void getSettingData() {
    settingAppData = SessionManager.instance.getSettings()?.appdata;
    notifyListeners();
  }
}
