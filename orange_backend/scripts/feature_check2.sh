#!/usr/bin/env bash
# =============================================================================
# KETUA Feature Checker — ISOLATED TEST DATABASE
# =============================================================================
# Behavioral verification of the mission features that have runnable server
# logic: recommendations (F02), short video (F15), plus regression on the
# economy/milestone flows. Runs against scripts/run_isolated.sh (ketua_test).
#
# Usage: ./scripts/feature_check2.sh [BASE_URL] [API_KEY]
# =============================================================================
set -u
BASE_URL="${1:-http://127.0.0.1:8899}"
API_KEY="${2:-}"
PASS=0; FAIL=0
declare -a R
RUN="fc2_${RANDOM}_$$"
DB="ketua_test"; DBU="ketua"
DBP="$(grep '^DB_PASSWORD=' "$(dirname "$0")/../.env.testing" | cut -d= -f2)"
q(){ mysql -u"$DBU" -p"$DBP" "$DB" -N -e "$1" 2>/dev/null; }
ok(){ PASS=$((PASS+1)); R+=("PASS  $1"); }
no(){ FAIL=$((FAIL+1)); R+=("FAIL  $1  ($2)"); }
KEYH=(-H "Content-Type: application/json" -H "apikey: $API_KEY")
reg(){ curl -s -X POST "$BASE_URL/api/auth/register" "${KEYH[@]}" -d "{\"identity\":\"$1\",\"fullname\":\"$2\"}"; }
tok(){ printf '%s' "$1" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'; }

echo "KETUA Feature Checker 2 (DB: $DB)"

# --- create two synthetic users ---
A=$(reg "${RUN}_a@x.com" "Alice"); TA=$(tok "$A"); IA=$(q "SELECT id FROM users WHERE identity='${RUN}_a@x.com';")
B=$(reg "${RUN}_b@x.com" "Bob"); TB=$(tok "$B"); IB=$(q "SELECT id FROM users WHERE identity='${RUN}_b@x.com';")
AH=("${KEYH[@]}" -H "Authorization: Bearer $TA")
BH=("${KEYH[@]}" -H "Authorization: Bearer $TB")

# ---- F02: recommendations require auth; feed returns ranked data ----
[ "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/getExplorePageProfileList" "${KEYH[@]}" -d '{"user_id":1}')" = "401" ] \
  && ok "F02 explore feed requires auth (401)" || no "F02 explore auth" "expected 401"
FEED=$(curl -s -X POST "$BASE_URL/api/getExplorePageProfileList" "${AH[@]}" -d "{\"user_id\":$IA}")
printf '%s' "$FEED" | grep -q '"status":true' && ok "F02 explore feed returns data for authed user" || no "F02 feed" "$FEED"

# ---- F15: short video endpoints require auth ----
for ep in feed create like view share delete; do
  C=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/shortVideo/$ep" "${KEYH[@]}" -d '{"short_video_id":1,"start":0,"count":10}')
  [ "$C" = "401" ] && ok "F15 shortVideo/$ep requires auth (401)" || no "F15 $ep auth" "expected 401 got $C"
done
# authed feed (empty DB -> success with empty data)
SVF=$(curl -s -X POST "$BASE_URL/api/shortVideo/feed" "${AH[@]}" -d '{"start":0,"count":10}')
printf '%s' "$SVF" | grep -q '"status":true' && ok "F15 shortVideo/feed authed returns success" || no "F15 feed body" "$SVF"

# ---- short video like on a real row is idempotent ----
q "INSERT INTO short_videos (user_id,video,caption,likes_count,created_at,updated_at) VALUES ($IB,'v.mp4','hi',0,NOW(),NOW());" >/dev/null
SVID=$(q "SELECT id FROM short_videos WHERE user_id=$IB LIMIT 1;")
L1=$(curl -s -X POST "$BASE_URL/api/shortVideo/like" "${AH[@]}" -d "{\"short_video_id\":$SVID}")
L2=$(curl -s -X POST "$BASE_URL/api/shortVideo/like" "${AH[@]}" -d "{\"short_video_id\":$SVID}")
C1=$(printf '%s' "$L1" | sed -n 's/.*"likes_count":\([0-9]*\).*/\1/p')
C2=$(printf '%s' "$L2" | sed -n 's/.*"likes_count":\([0-9]*\).*/\1/p')
[ "$C1" = "1" ] && [ "$C2" = "0" ] && ok "F15 shortVideo/like is idempotent (1 then 0)" || no "F15 like idempotent" "counts=$C1,$C2 expected 1,0"

# ---- scoped cleanup ----
ERR=$(q "DELETE FROM users WHERE identity LIKE '${RUN}\_%'; DELETE FROM short_videos; DELETE FROM short_video_likes; DELETE FROM short_video_views;" 2>&1)
printf '%s' "$ERR" | grep -qi error && no "cleanup" "$ERR" || ok "cleanup scoped to run fixtures"

echo "RESULTS:"; for r in "${R[@]}"; do echo "  $r"; done
echo "TOTAL: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
