import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/app_res.dart';
import 'package:stacked/stacked.dart';

class PreferenceScreenViewModel extends BaseViewModel {
  GenderType selectedGenderPref = GenderType.male;
  RangeValues selectedAgeRange = const RangeValues(18, 35);
  double selectedDistance = AppRes.defaultDistancePreference;

  UserData? userData = SessionManager.instance.getUser();
  SettingData? settingData = SessionManager.instance.getSettings();

  void init() {
    getPrefSettings();
  }

  void getPrefSettings() async {
    getLocalData();
    notifyListeners();
  }

  void getLocalData() {
    if (userData == null) return;

    selectedGenderPref = userData!.genderPreferred;
    selectedAgeRange = RangeValues(
      (userData?.agePreferredMin ?? AppRes.ageMin).toDouble().clamp(AppRes.ageMin, AppRes.ageMax),
      (userData?.agePreferredMax ?? AppRes.ageMax).toDouble().clamp((userData?.agePreferredMin ?? AppRes.ageMin).toDouble().clamp(AppRes.ageMin,AppRes.ageMax), AppRes.ageMax),
    );
    selectedDistance = (userData?.distancePreference ?? AppRes.defaultDistancePreference).toDouble().clamp(0, AppRes.maximumDistancePreference);

    notifyListeners();
  }

  void onChangeAgeRange(RangeValues value) {
    selectedAgeRange = value;
    notifyListeners();
  }

  void onChangeDistance(double value) {
    selectedDistance = value;
    notifyListeners();
  }

  void onChangeGenderPref(GenderType type) {
    selectedGenderPref = type;
    notifyListeners();
  }

  bool saving = false;
  Future<void> onSaveTap() async {
    if (saving) return;
    saving=true; notifyListeners();
    try {
    final value = await ApiProvider()
        .updateProfile(
      genderPreferred: selectedGenderPref.value,
      ageMin: selectedAgeRange.start,
      ageMax: selectedAgeRange.end,
      distancePreference: selectedDistance,
    )
        ;
      if (value.status == true && value.data != null) {
        SessionManager.instance.setUser(value.data); Get.back(result:true);
      } else { CommonUI.snackBar(message:value.message??'Could not save preferences.'); }
    } catch(_) { CommonUI.snackBar(message:'Connection interrupted. Your choices are still here; retry saving.'); }
    finally { saving=false;notifyListeners(); }
  }
}
