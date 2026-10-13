import 'package:get/get.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/service/subscription/subscription_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionSheetController extends GetxController {
  RxList<Package> packages = <Package>[].obs;
  Rx<Package?> selectedPackage = Rx(null);
  Function()? purchaseCallBack;

  @override
  void onInit() {
    super.onInit();
    packages.value = SubscriptionManager.shared.packages;
    if (packages.isNotEmpty) {
      selectedPackage.value = SubscriptionManager.shared.packages.first;
    }
  }

  void onSubscriptionTap(Package package) {
    selectedPackage.value = package;
  }

  void onMakePurchase(Package? package) async {
    if (package != null) {
      CommonUI.lottieLoader();
      bool? status = await SubscriptionManager.shared.makePurchase(package);
      Get.back();
      if (status == true) {
        purchaseCallBack?.call();
        Get.back(result: true);
      }
    }
  }
}
