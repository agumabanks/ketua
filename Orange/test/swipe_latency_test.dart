import 'dart:async';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/explore_screen/explore_screen_view_model.dart';
import 'package:ketua_ui/screen/subscription_sheet/subscription_sheet_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Get.put(SubscriptionSheetController()));
  tearDown(() => Get.reset());
  test('a slow like request does not hold the card transition', () async {
    final response = Completer<Map<String, dynamic>>();
    final model = ExploreScreenViewModel(saveSwipe: (id, like) => response.future);
    model.combinedList = List.generate(6, (i) => UserData(id: i + 1));
    expect(await model.onSwipe(0, 1, CardSwiperDirection.right).timeout(const Duration(milliseconds: 100)), true);
    expect(model.currentCombinedIndex, 1);
    expect(model.pendingSwipeCount, 1);
    expect(model.combinedList.first.isLiked, isNull);
    response.complete({'status': true});
    await Future<void>.delayed(Duration.zero);
    expect(model.pendingSwipeCount, 0);
    expect(model.combinedList.first.isLiked, true);
    model.dispose();
  });
  test('failed saves retry the original profile after the deck advances', () async {
    final calls = <int>[];
    var fail = true;
    final model = ExploreScreenViewModel(saveSwipe: (id, like) async {
      calls.add(id);
      return {'status': !fail};
    });
    model.combinedList = List.generate(6, (i) => UserData(id: i + 1));
    await model.onSwipe(0, 1, CardSwiperDirection.left);
    await Future<void>.delayed(Duration.zero);
    expect(model.failedSwipeCount, 1);
    expect(model.combinedList.first.isLiked, isNull);
    model.currentCombinedIndex = 3;
    model.combinedList.clear(); // Changing preferences must not lose the retry target.
    fail = false;
    model.retryFailedSwipes();
    await Future<void>.delayed(Duration.zero);
    expect(calls, [1, 1]);
    expect(model.failedSwipeCount, 0);
    expect(model.pendingSwipeCount, 0);
    model.dispose();
  });
  test('passing an unliked profile is accepted as an idempotent pass', () async {
    final model = ExploreScreenViewModel(saveSwipe: (id, like) async =>
        {'status': false, 'message': 'Already Disliked Profile!'});
    model.combinedList = List.generate(6, (i) => UserData(id: i + 1));
    expect(await model.onSwipe(0, 1, CardSwiperDirection.left), true);
    await Future<void>.delayed(Duration.zero);
    expect(model.failedSwipeCount, 0);
    expect(model.combinedList.first.isLiked, false);
    model.dispose();
  });

}
