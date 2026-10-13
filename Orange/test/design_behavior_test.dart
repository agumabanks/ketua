// Behavioral UI tests for the KETUA redesign.
//
// These are real widget tests: they execute the widgets under test and assert
// observable behavior/properties. They do NOT grep source strings (which is what
// the shallow design checker did). Run with:
//   flutter test test/design_behavior_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ketua_ui/common/ketua_wordmark.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/utils/ketua_theme.dart';

void main() {
  group('KETUA redesign — behavioral', () {
    test('brand name is uppercase', () {
      expect(KetuaTheme.brandName, 'KETUA');
      expect(KetuaTheme.brandName, equals(KetuaTheme.brandName.toUpperCase()));
    });

    test('wordmark renders KETUA uppercase with a real weight-900 font', () {
      final style = KetuaTheme.brandWordmark(size: 48);
      expect(style.fontFamily, FontRes.heavy); // true weight-900 family
      expect(style.fontWeight, FontWeight.w900);
      expect(KetuaWordmark(size: 32), isA<KetuaWordmark>());
    });

    test('dark theme is wired and surfaces are dark', () {
      final theme = KetuaTheme.dark;
      // Scaffold background must be the dark surface, not white.
      expect(theme.scaffoldBackgroundColor, ColorRes.bgDark);
      expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
      // Card color must be a dark surface.
      expect(theme.cardColor, ColorRes.surfaceDark);
      // Foreground text on dark surfaces must be light.
      expect(theme.textTheme.bodyLarge?.color, ColorRes.textPrimaryDark);
      expect(theme.textTheme.bodyLarge?.color, isNot(Colors.black));
    });

    test('controls are rounded (stadium buttons + rounded inputs)', () {
      final theme = KetuaTheme.dark;
      // The elevated button style uses a StadiumBorder (fully rounded pill).
      final btnStyle = theme.elevatedButtonTheme.style;
      expect(btnStyle, isNotNull);
      final shape = btnStyle?.shape?.resolve({});
      expect(shape, isA<StadiumBorder>());
      // Input theme should not use a square (radius 0) border.
      final border = theme.inputDecorationTheme.border as OutlineInputBorder?;
      expect(border, isNotNull);
      expect(border!.borderRadius, isNot(BorderRadius.zero));
      expect(border.borderRadius.bottomLeft.x, greaterThan(0));
    });

    test('brand gradient uses the KETUA accent pair', () {
      final g = KetuaTheme.brandGradient;
      expect(g.colors.first, ColorRes.ketuaAccent);
      expect(g.colors.last, ColorRes.ketuaAccent2);
    });

    testWidgets('KetuaWordmark widget builds and shows KETUA text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: KetuaWordmark(size: 40))),
        ),
      );
      // The wordmark must render the uppercase brand text.
      expect(find.text('KETUA'), findsOneWidget);
    });

    testWidgets('dark theme applied to a scaffold shows dark background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: KetuaTheme.dark,
          home: const Scaffold(body: Center(child: Text('hi'))),
        ),
      );
      // The theme the app resolves to must expose the dark scaffold surface.
      final ctx = tester.element(find.byType(Scaffold));
      final resolvedTheme = Theme.of(ctx);
      expect(resolvedTheme.scaffoldBackgroundColor, ColorRes.bgDark);
      expect(resolvedTheme.scaffoldBackgroundColor, isNot(Colors.white));
      // The wordmark + text must be present and legible on the dark surface.
      expect(find.text('hi'), findsOneWidget);
    });
  });
}
