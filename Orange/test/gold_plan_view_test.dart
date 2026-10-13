import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/subscription_sheet/gold_plan_view.dart';
import 'package:ketua_ui/screen/subscription_sheet/subscription_sheet_controller.dart';
import 'package:ketua_ui/utils/ketua_theme.dart';

void main() {
  tearDown(() => Get.reset());
  testWidgets('Gold is readable at large text and unavailable checkout cannot charge', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put(SubscriptionSheetController());
    await tester.pumpWidget(GetMaterialApp(theme: KetuaTheme.dark,
      home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(1.4)), child: const GoldPlanView())));
    await tester.pumpAndSettle();
    expect(find.text('KETUA'), findsOneWidget);
    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('Purchases unavailable'), findsOneWidget);
    final checkout = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(checkout.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
