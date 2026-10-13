import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/screen/auth_screen/auth_screen.dart';
import 'package:ketua_ui/screen/auth_screen/auth_screen_view_model.dart';
import 'package:ketua_ui/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';

class SplashScreenViewModel extends BaseViewModel {
  bool failed = false;
  bool loading = false;
  void init() {
    _firstLocationPermission().whenComplete(_settingApiCall);
  }

  Future<void> _firstLocationPermission() async {
    const key = 'location_boot_prompted';
    await GetStorage.init('ketua_device_prefs');
    final device = GetStorage('ketua_device_prefs');
    if (device.read<bool>(key) == true) return;
    await device.write(key, true);
    try {
      if (await Geolocator.checkPermission() == LocationPermission.denied)
        await Geolocator.requestPermission();
    } catch (_) {/* Location is optional; registration remains available. */}
  }

  void _settingApiCall() async {
    if (loading) return;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      await ApiProvider()
          .getSettingData()
          .timeout(const Duration(seconds: 20))
          .then((value) async {
        if (value.status == true) {
          bool isLogin =
              SessionManager.instance.getBool(key: SessionKeys.isLogin);

          if (isLogin && SessionManager.instance.isAuthenticated) {
            await fetchProfile();
          } else {
            final List<Onboarding> onBoardingItems =
                value.data?.onboardingScreen ?? [];
            bool isDating = value.data?.appdata?.isDating == 1;
            if (isDating && onBoardingItems.isNotEmpty) {
              Get.off(() => OnBoardingScreen(onBoarding: onBoardingItems));
            } else {
              Get.off(() => const AuthScreen());
            }
          }
        } else {
          failed = true;
        }
      });
    } catch (_) {
      failed = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    final userData = SessionManager.instance.getUser();

    if (userData == null) {
      Get.off(() => const AuthScreen());
      return;
    }
    try {
      final response = await ApiProvider()
          .fetchMyUserProfile()
          .timeout(const Duration(seconds: 20));

      if (response.status == true && response.data?.id != null) {
        await AuthScreenViewModel().navigateScreen(userData: response.data!);
      } else {
        Get.off(() => const AuthScreen());
      }
    } catch (e) {
      // Handle API or unexpected error
      failed = true;
    }
  }
}
