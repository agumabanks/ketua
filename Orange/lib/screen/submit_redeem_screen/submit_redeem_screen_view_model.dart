import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/place_redeem_request.dart';
import 'package:ketua_ui/model/setting_model.dart';

import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/urls.dart';
import 'package:stacked/stacked.dart';

class SubmitRedeemScreenViewModel extends BaseViewModel {
  int coinValue = 0;
  TextEditingController accountDetailController = TextEditingController();
  String? paymentGateway = S.current.paypal;
  String accountError = '';
  bool isEmpty = false;
  List<String> paymentList = [S.current.paypal, S.current.bankTransfer];

  Appdata? settingAppData;

  void init() {
    coinValue = Get.arguments;
    getPrefData();
  }

  void onBackBtnTap() {
    Get.back();
  }

  void onPaymentChange(String? value) {
    paymentGateway = value;
    notifyListeners();
  }

  void onSubmitBtnTap() async {
    if (!isValid()) return;
    CommonUI.lottieLoader();

    ApiProvider().callPost(
        completion: (response) {
          PlaceRedeemRequest placeRedeemRequest = PlaceRedeemRequest.fromJson(response);
          Get.back();
          if (placeRedeemRequest.status == true) {
            Get.back(result: true);
          } else {
            CommonUI.snackBar(message: '${placeRedeemRequest.message}');
          }
        },
        url: Urls.aPlaceRedeemRequest,
        param: {
          Urls.userId: SessionManager.instance.getUserID().toString(),
          Urls.aAccountDetails: paymentGateway,
          Urls.aPaymentGateway: accountDetailController.text.trim(),
        });
  }

  bool isValid() {
    int i = 0;
    if (accountDetailController.text == '') {
      accountError = S.current.enterAccountDetails;
      isEmpty = true;
      i++;
    }
    notifyListeners();
    return i == 0 ? true : false;
  }

  void getPrefData() {
    settingAppData = SessionManager.instance.getSettings()?.appdata;
    notifyListeners();
  }
}
