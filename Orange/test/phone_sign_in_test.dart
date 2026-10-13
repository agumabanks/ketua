import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/auth_screen/phone_sign_in_screen.dart';
import 'package:ketua_ui/utils/ketua_theme.dart';

void main() {
  tearDown(() => Get.reset());
  testWidgets('existing phone users open the sign-in form directly', (tester) async {
    await tester.pumpWidget(GetMaterialApp(theme: KetuaTheme.dark, home: const PhoneSignInScreen(initialRegistration: false)));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Confirm password'), findsNothing);
  });
  testWidgets('phone sign-in rejects an incomplete number before creating an account', (tester) async {
    await tester.pumpWidget(GetMaterialApp(theme: KetuaTheme.dark, home: const PhoneSignInScreen()));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.textContaining('Enter your phone number with its country code'), findsOneWidget);
    expect(find.text('SMS code'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
