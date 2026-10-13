import 'package:flutter/material.dart';

import 'color_res.dart';
import 'font_res.dart';

/// KETUA design system.
///
/// Provides the dark, immersive theme (dark surfaces, rounded controls) and the
/// brand wordmark style. The KETUA logo is rendered UPPERCASE with the heavy
/// (weight-900) Gilroy font family and tight letter-spacing.
class KetuaTheme {
  KetuaTheme._();

  /// Brand wordmark: "KETUA" — uppercase, real font weight 900 (gilroy_heavy),
  /// tight tracking, optional gradient fill.
  static const String brandName = 'KETUA';

  static TextStyle brandWordmark({
    double size = 40,
    Color color = ColorRes.textPrimaryDark,
    double letterSpacing = 2.0,
  }) {
    return TextStyle(
      fontFamily: FontRes.heavy, // true weight-900 family
      fontWeight: FontWeight.w900,
      fontSize: size,
      height: 1.0,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Gradient-filled version of the wordmark (wrap in ShaderMask at call site).
  static LinearGradient get brandGradient => const LinearGradient(
        colors: [ColorRes.ketuaAccent, ColorRes.ketuaAccent2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Rounded shape used for cards, sheets, buttons and inputs.
  static RoundedRectangleBorder card([double r = 20]) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

  static StadiumBorder get pill => const StadiumBorder();

  static BorderRadius get radiusLG => BorderRadius.circular(24);
  static BorderRadius get radiusMD => BorderRadius.circular(16);
  static BorderRadius get radiusSM => BorderRadius.circular(12);

  /// The dark theme applied app-wide.
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: false);
    return base.copyWith(
      scaffoldBackgroundColor: ColorRes.bgDark,
      primaryColor: ColorRes.ketuaAccent,
      splashColor: ColorRes.transparent,
      highlightColor: ColorRes.transparent,
      canvasColor: ColorRes.bgDark,
      cardColor: ColorRes.surfaceDark,
      dividerColor: ColorRes.borderDark,
      colorScheme: base.colorScheme.copyWith(
        primary: ColorRes.ketuaAccent,
        secondary: ColorRes.ketuaAccent2,
        surface: ColorRes.surfaceDark,
        background: ColorRes.bgDark,
        onPrimary: Colors.white,
        onSurface: ColorRes.textPrimaryDark,
      ),
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: ColorRes.ketuaAccent),
      textTheme: base.textTheme.apply(
        fontFamily: FontRes.regular,
        bodyColor: ColorRes.textPrimaryDark,
        displayColor: ColorRes.textPrimaryDark,
      ),
      // Rounded controls everywhere.
      cardTheme: CardThemeData(
        color: ColorRes.surfaceDark,
        elevation: 0,
        shape: card(20),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorRes.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorRes.surfaceDark,
        shape: card(24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorRes.ketuaAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: FontRes.semiBold,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorRes.textPrimaryDark,
          side: const BorderSide(color: ColorRes.borderDark),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorRes.surfaceDark2,
        hintStyle: const TextStyle(color: ColorRes.textSecondaryDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorRes.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorRes.ketuaAccent, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorRes.bgDark,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ColorRes.textPrimaryDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorRes.surfaceDark2,
        contentTextStyle: const TextStyle(color: ColorRes.textPrimaryDark),
        behavior: SnackBarBehavior.floating,
        shape: card(14),
      ),
    );
  }
}
