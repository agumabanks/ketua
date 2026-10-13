import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/screen/commerce/commerce_api.dart';
import 'package:ketua_ui/screen/commerce/account_wallet_screen.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/live_stream_application_screen/live_stream_application_screen.dart';
import 'package:ketua_ui/screen/live_stream_history_screen/live_stream_history_screen.dart';
import 'package:ketua_ui/screen/redeem_screen/redeem_screen.dart';
import 'package:ketua_ui/screen/submit_redeem_screen/submit_redeem_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';

class LiveStreamDashBoardViewModel extends BaseViewModel {
  bool isLoading = false;
  UserData? userData;
  int coinValue = 0;
  Map<String, dynamic>? eligibility;
  String? statusError;

  Appdata? settingAppData;

  void init() {
    getPrefData();

    getSettingData();
    refresh();
  }

  void getPrefData() {
    userData = SessionManager.instance.getUser();
    coinValue = userData?.wallet ?? 0;
    notifyListeners();
  }

  void onRedeemTap() {
    Get.to(() => const SubmitRedeemScreen(), arguments: coinValue)
        ?.then((value) {
      if (value != null) {
        userData?.wallet = 0;
        notifyListeners();
        SessionManager.instance.setUser(userData);
      }
    });
  }

  Future<void> refresh() async {
    try {
      final response = await commerceRequest('live/eligibility');
      if (response['status'] != true) throw StateError('Unavailable');
      eligibility = Map<String, dynamic>.from(response['data']);
      final profile = await ApiProvider()
          .getProfile(userID: SessionManager.instance.getUserID());
      if (profile.status == true && profile.data != null) {
        userData = profile.data;
        coinValue = userData?.wallet ?? 0;
      }
      statusError = null;
    } catch (_) {
      statusError = 'Could not refresh live status. Try again.';
    }
    notifyListeners();
  }

  void onAddCoinsBtnTap() {
    Get.to(() => const AccountWalletScreen())?.then((_) => refresh());
  }

  void onBackBtnTap() {
    Get.back();
  }

  void onHistoryBtnTap() {
    Get.to(() => const LiveStreamHistory());
  }

  void onRedeemBtnTap() {
    Get.to(() => const RedeemScreen());
  }

  void onApplyBtnTap() {
    Get.to(() => const LiveStreamApplicationScreen())?.then((_) => refresh());
  }

  void getSettingData() {
    settingAppData = SessionManager.instance.getSettings()?.appdata;
    notifyListeners();
  }
}
