import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';

class LanguagesScreenViewModel extends BaseViewModel {
  static String selectedLanguage = Platform.localeName.split('_')[0];

  int? value = 0;
  List<String> languages = ['English', 'Français', 'Kiswahili'];
  List<String> subLanguage = ['English', 'French', 'Swahili'];
  List<String> languageCode = ['en', 'fr', 'sw'];

  void init() {
    prefData();
  }

  Timer? _timer;

  void onLanguageChange(int? value) async {
    this.value = value;
    SessionManager.instance.setString(
        key: SessionKeys.languageCode, value: languageCode[value ?? 0]);
    selectedLanguage = languageCode[value ?? 0];
    await Get.updateLocale(Locale(selectedLanguage));
    notifyListeners();
    ApiProvider().updateProfile(appLanguage: selectedLanguage);
  }

  void prefData() async {
    selectedLanguage =
        SessionManager.instance.getString(key: SessionKeys.languageCode) ??
            Platform.localeName.split('_')[0];
    if (!languageCode.contains(selectedLanguage)) selectedLanguage = 'en';
    value = languageCode.indexOf(selectedLanguage);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
