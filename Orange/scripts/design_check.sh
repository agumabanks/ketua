#!/usr/bin/env bash
# =============================================================================
# KETUA Design Checker
# =============================================================================
# Verifies the UI redesign requirements are present in the Flutter source:
#   - Dark theme applied (dark surfaces, ThemeMode.dark)
#   - KETUA rendered UPPERCASE with real font weight 900 (gilroy_heavy)
#   - Rounded controls (StadiumBorder / rounded radii on buttons, cards, nav)
#   - Floating navigation bar (rounded, elevated, inset)
# Run from the Orange/ project root. Exit 0 = all present.
# =============================================================================
set -u
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
declare -a R
chk(){ if eval "$2" >/dev/null 2>&1; then PASS=$((PASS+1)); R+=("PASS  $1"); else FAIL=$((FAIL+1)); R+=("FAIL  $1"); fi; }

echo "== KETUA Design Checker =="

# Dark theme wired into the app.
chk "Dark theme applied (themeMode dark + KetuaTheme.dark)" \
  "grep -q 'KetuaTheme.dark' lib/main.dart && grep -q 'ThemeMode.dark' lib/main.dart"

# Dark surface tokens exist.
chk "Dark surface color tokens defined" \
  "grep -q 'bgDark' lib/utils/color_res.dart && grep -q 'surfaceDark' lib/utils/color_res.dart"

# KETUA brand name uppercase.
chk "Brand name is uppercase KETUA" \
  "grep -q \"brandName = 'KETUA'\" lib/utils/ketua_theme.dart"

# Real font weight 900 using the heavy family.
chk "KETUA wordmark uses weight-900 heavy font" \
  "grep -q 'FontWeight.w900' lib/utils/ketua_theme.dart && grep -q 'FontRes.heavy' lib/utils/ketua_theme.dart"

# gilroy_heavy font family is declared.
chk "gilroy_heavy (weight-900) font family declared in pubspec" \
  "grep -q 'gilroy_heavy' pubspec.yaml"

# Reusable wordmark widget exists.
chk "Reusable KetuaWordmark widget present" \
  "test -f lib/common/ketua_wordmark.dart"

# Rounded controls: stadium borders on buttons + rounded card theme.
chk "Rounded controls (StadiumBorder / rounded radii)" \
  "grep -q 'StadiumBorder' lib/utils/ketua_theme.dart && grep -q 'BorderRadius.circular' lib/utils/ketua_theme.dart"

# Floating navigation bar (rounded, elevated, inset).
chk "Floating navigation bar (rounded + shadow + inset)" \
  "grep -q 'BorderRadius.circular(28)' lib/screen/dashboard/dashboard_screen.dart && grep -q 'boxShadow' lib/screen/dashboard/dashboard_screen.dart && grep -q 'EdgeInsets' lib/screen/dashboard/dashboard_screen.dart"

# Splash shows the KETUA wordmark.
chk "Splash renders KETUA wordmark (ShaderMask + brandName)" \
  "grep -q 'KetuaTheme.brandName' lib/screen/splash_screen/splash_screen.dart"

echo "RESULTS:"; for r in "${R[@]}"; do echo "  $r"; done
echo "TOTAL: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
