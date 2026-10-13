#!/usr/bin/env bash
# =============================================================================
# KETUA Flutter Static-Analysis / Build-Readiness Checker
# =============================================================================
# Verifies the Flutter app tree analyzes without ERRORS and that the auth
# wiring (K09) is present. Run from the Orange/ project root.
#
# Usage:
#   ./scripts/flutter_check.sh
#
# Notes:
#   - Uses Flutter 3.47 (Dart >=3.10) because flutter_local_notifications
#     21.0.0 requires it. The host's default flutter (3.35/Dart 3.9) cannot
#     resolve dependencies.
#   - The nested `flutter/` duplicate copy is excluded from analysis (it is a
#     stale accidental checkout that breaks the analyzer with duplicate types).
#
# Exit 0 = no analyzer errors. Non-zero = errors present.
# =============================================================================
set -u
cd "$(dirname "$0")/.."

FLUTTER_BIN="${FLUTTER_BIN:-/opt/flutter-3.47/bin/flutter}"
if [ ! -x "$FLUTTER_BIN" ]; then
  echo "ERROR: Flutter not found at $FLUTTER_BIN (set FLUTTER_BIN)."
  exit 2
fi
export PATH="$(dirname "$FLUTTER_BIN"):$PATH"

echo "== KETUA Flutter checker =="
flutter --version 2>/dev/null | head -1

echo "-- pub get --"
flutter pub get >/dev/null 2>&1 && echo "pub get OK" || { echo "pub get FAILED"; exit 2; }

echo "-- analyze (errors only matter) --"
OUT=$(flutter analyze 2>&1)
echo "$OUT" | tail -1

ERRORS=$(echo "$OUT" | grep -cE "^\s*error •" || true)
if [ "$ERRORS" -ne 0 ]; then
  echo "FAIL: $ERRORS analyzer error(s):"
  echo "$OUT" | grep -E "^\s*error •"
  exit 1
fi
echo "PASS: 0 analyzer errors."

echo "-- K09 auth wiring present --"
grep -q "Authorization.*Bearer" lib/api_provider/api_provider.dart \
  && echo "PASS: bearer token attached in ApiProvider" \
  || { echo "FAIL: bearer token wiring missing"; exit 1; }
grep -q "getAuthToken" lib/service/session_manager.dart \
  && echo "PASS: SessionManager token storage present" \
  || { echo "FAIL: SessionManager token storage missing"; exit 1; }
grep -q "static const String base = 'https://ketua.sanaa.co/'" lib/utils/const_res.dart \
  && echo "PASS: real base URL configured" \
  || { echo "FAIL: base URL not configured"; exit 1; }

echo "-- behavioral UI tests (not source greps) --"
timeout 300 flutter test test/design_behavior_test.dart >/tmp/kt_uitest.log 2>&1 \
  && echo "PASS: design behavioral widget tests" \
  || { echo "FAIL: design behavioral tests:"; tail -20 /tmp/kt_uitest.log; exit 1; }

echo "== Flutter checker: ALL PASS =="
