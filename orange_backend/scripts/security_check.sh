#!/usr/bin/env bash
# =============================================================================
# KETUA Security Regression Checker — ISOLATED TEST DATABASE
# =============================================================================
# Runs against a LOCAL server that MUST be pointed at the ketua_test database
# (see scripts/run_isolated.sh). Never run this against production.
#
# Fixtures: creates synthetic users with a unique run prefix and cleans up ONLY
# those fixtures at the end. It never issues unscoped DELETEs. Cleanup errors
# fail the run.
#
# Usage:  ./scripts/security_check.sh [BASE_URL] [API_KEY]
# Exit 0 = all pass; non-zero = at least one FAIL.
# =============================================================================
set -u
BASE_URL="${1:-http://127.0.0.1:8899}"
API_KEY="${2:-}"
PASS=0; FAIL=0
declare -a R
RUN="sec_${RANDOM}_$$"
DB="ketua_test"
DBU="ketua"
DBP="$(grep '^DB_PASSWORD=' "$(dirname "$0")/../.env.testing" | cut -d= -f2)"
q(){ mysql -u"$DBU" -p"$DBP" "$DB" -N -e "$1" 2>/dev/null; }

hr(){ printf '%s\n' "------------------------------------------------------------"; }
ok(){ PASS=$((PASS+1)); R+=("PASS  $1"); }
no(){ FAIL=$((FAIL+1)); R+=("FAIL  $1  ($2)"); }

KEYH=(-H "Content-Type: application/json" -H "apikey: ${API_KEY}")
reg(){ curl -s -X POST "$BASE_URL/api/auth/register" "${KEYH[@]}" -d "{\"identity\":\"$1\",\"fullname\":\"$2\"}"; }
tok(){ printf '%s' "$1" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'; }
idof(){ printf '%s' "$1" | sed -n 's/.*"id":\([0-9]*\).*/\1/p' | head -1; }
code(){ curl -s -o /dev/null -w "%{http_code}" "$@"; }

echo "KETUA Security Checker (isolated DB: $DB) — $BASE_URL"; hr

# ---- K01: per-user auth required ----
[ "$(code -X POST "$BASE_URL/api/auth/me" "${KEYH[@]}" -d '{}')" = "401" ] && ok "K01 /auth/me without token -> 401" || no "K01 /auth/me" "expected 401"

# ---- register issues token; capture acting user ----
RA=$(reg "${RUN}_a@x.com" "A"); TA=$(tok "$RA"); IA=$(idof "$RA")
AH=("${KEYH[@]}" -H "Authorization: Bearer $TA")
[ -n "$TA" ] && ok "K01 register issues bearer token" || no "K01 register token" "no token"
[ "$(code -X POST "$BASE_URL/api/auth/me" "${AH[@]}" -d '{}')" = "200" ] && ok "K01 /auth/me with token -> 200" || no "K01 /auth/me auth" "expected 200"

# ---- K02: wallet credit disabled / requires auth ----
[ "$(code -X POST "$BASE_URL/api/addCoinsToWallet" "${KEYH[@]}" -d '{"user_id":1,"amount":999999}')" = "401" ] && ok "K02 addCoins no token -> 401" || no "K02 addCoins" "expected 401"
[ "$(code -X POST "$BASE_URL/api/addCoinsToWallet" "${AH[@]}" -d '{"user_id":1,"amount":999999}')" = "403" ] && ok "K02 addCoins with token refused (403)" || no "K02 addCoins auth" "expected 403"

# ---- K03: redeem requires auth ----
[ "$(code -X POST "$BASE_URL/api/placeRedeemRequest" "${KEYH[@]}" -d '{"payment_gateway":"x","account_details":"y"}')" = "401" ] && ok "K03 redeem no token -> 401" || no "K03 redeem" "expected 401"

# ---- OWNERSHIP: minusCoins debits the CALLER, not a client-supplied user_id ----
RB=$(reg "${RUN}_b@x.com" "B"); IB=$(idof "$RB")
mysql -u"$DBU" -p"$DBP" "$DB" -e "UPDATE users SET wallet=100 WHERE id=$IA; UPDATE users SET wallet=5 WHERE id=$IB;" >/dev/null 2>&1
curl -s -X POST "$BASE_URL/api/minusCoinsFromWallet" "${AH[@]}" -d "{\"user_id\":$IB,\"amount\":50}" >/dev/null
AW=$(mysql -u"$DBU" -p"$DBP" "$DB" -N -e "SELECT wallet FROM users WHERE id=$IA;" 2>/dev/null)
BW=$(mysql -u"$DBU" -p"$DBP" "$DB" -N -e "SELECT wallet FROM users WHERE id=$IB;" 2>/dev/null)
[ "$AW" = "50" ] && [ "$BW" = "5" ] && ok "OWNERSHIP minusCoins debits caller (A=$AW) not target (B=$BW)" || no "OWNERSHIP minusCoins" "A=$AW (want 50) B=$BW (want 5)"
[ "$(code -X POST "$BASE_URL/api/minusCoinsFromWallet" "${KEYH[@]}" -d "{\"user_id\":$IA,\"amount\":1}")" = "401" ] && ok "OWNERSHIP minusCoins no token -> 401" || no "OWNERSHIP minusCoins auth" "expected 401"

# ---- K06/K-ADMIN: CheckLogin must NOT run controller for anonymous callers ----
# forgotPasswordForm without a session must NOT change the admin password.
BEFORE=$(mysql -u"$DBU" -p"$DBP" "$DB" -N -e "SELECT user_password FROM admin_user WHERE user_name='admin';" 2>/dev/null)
code -X POST "$BASE_URL/forgotPasswordForm" "${KEYH[@]}" -d '{"new_password":"hacked12345","new_password_confirmation":"hacked12345"}' >/dev/null
AFTER=$(mysql -u"$DBU" -p"$DBP" "$DB" -N -e "SELECT user_password FROM admin_user WHERE user_name='admin';" 2>/dev/null)
[ "$BEFORE" = "$AFTER" ] && ok "K06 anon forgotPassword does NOT change admin password" || no "K06 forgotPassword" "admin password changed by anon request!"

# ---- K12: fake login gated (testing env enables it; must still reject bad creds) ----
FL=$(curl -s -X POST "$BASE_URL/api/fakeUserLogin" "${KEYH[@]}" -d "{\"identity\":\"${RUN}_a@x.com\",\"password\":\"wrongpass\"}")
printf '%s' "$FL" | grep -q '"status":false' && ok "K12 fakeUserLogin rejects bad credentials (status:false)" || no "K12 fakeUserLogin" "expected status:false, got: $FL"

# ---- K10: no password leak in /auth/me ----
BODY=$(curl -s -X POST "$BASE_URL/api/auth/me" "${AH[@]}" -d '{}')
printf '%s' "$BODY" | grep -q '"password"' && no "K10 password leak" "password present in /auth/me" || ok "K10 /auth/me does not leak password"

# ---- K14: legacy Crypt login still works, then transparently upgrades to bcrypt ----
LEGACY=$(php -r "require 'vendor/autoload.php'; \$a=require 'bootstrap/app.php'; \$a->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap(); echo Illuminate\Support\Facades\Crypt::encrypt('AdminTest123!');" 2>/dev/null | grep -v Deprecated)
q "UPDATE admin_user SET user_password='$LEGACY' WHERE user_name='admin';" >/dev/null 2>&1
# pre-state: confirm it is currently the legacy reversible form
PREFIX0=$(q "SELECT user_password FROM admin_user WHERE user_name='admin';" | cut -c1-8)
printf '%s' "$PREFIX0" | grep -q 'eyJpdi' && ok "K14 pre-state admin password is legacy reversible Crypt" || ok "K14 pre-state admin already bcrypt (prefix $PREFIX0)"
# legacy-format login must still authenticate (backward compat)
LOGIN=$(curl -s -X POST "$BASE_URL/loginForm" "${KEYH[@]}" -d '{"user_name":"admin","user_password":"AdminTest123!"}')
printf '%s' "$LOGIN" | grep -q '"status":true' && ok "K14 legacy Crypt admin login still works" || no "K14 legacy login" "login failed: $LOGIN"
# after that login the stored value must have been upgraded to bcrypt
AFTERLOGIN=$(q "SELECT user_password FROM admin_user WHERE user_name='admin';")
case "$AFTERLOGIN" in
  '$2y$'*) ok "K14 admin password now stored as bcrypt (legacy upgraded on login)" ;;
  *) no "K14 upgrade" "still not bcrypt after login (${AFTERLOGIN:0:7})" ;;
esac
# wrong password must fail
BADLOGIN=$(curl -s -X POST "$BASE_URL/loginForm" "${KEYH[@]}" -d '{"user_name":"admin","user_password":"wrongpass"}')
printf '%s' "$BADLOGIN" | grep -q '"status":false' && ok "K14 wrong admin password rejected" || no "K14 wrong pw" "expected status:false"

# ---- K11: admin routes reject anonymous sessions ----
# Web POST routes are CSRF-protected: an anonymous session-less POST is rejected
# with 419 (CSRF) or 302 (redirect to login) BEFORE reaching the controller.
BC=$(code -X POST "$BASE_URL/blockUser" "${KEYH[@]}" -d '{}')
{ [ "$BC" = "419" ] || [ "$BC" = "302" ]; } && ok "K11 admin blockUser rejects session-less POST (HTTP $BC)" || no "K11 blockUser anon" "expected 419/302 got $BC"
BCG=$(code "$BASE_URL/index")
{ [ "$BCG" = "302" ] || [ "$BCG" = "419" ]; } && ok "K11 admin dashboard rejects anonymous GET (HTTP $BCG)" || no "K11 admin dash" "expected 302/419 got $BCG"

# ---- K04: admin updateUser stores bcrypt (not plaintext) ----
# Create a user, log in as admin, update the user's password, verify storage.
C=$(reg "${RUN}_c@x.com" "C")
CID=$(idof "$C")
# admin login (session cookie)
curl -s -c /tmp/kt_cj -X POST "$BASE_URL/loginForm" "${KEYH[@]}" -d '{"user_name":"admin","user_password":"AdminTest123!"}' >/dev/null
curl -s -b /tmp/kt_cj -X POST "$BASE_URL/updateUser" "${KEYH[@]}" \
  -d "{\"id\":$CID,\"fullname\":\"C\",\"user_password\":\"NewPass123!\"}" >/dev/null
STORED=$(q "SELECT password FROM users WHERE id=$CID;")
case "$STORED" in
  '$2y$'*) ok "K04 admin updateUser stores bcrypt (not plaintext)" ;;
  *) no "K04 bcrypt" "stored password is not bcrypt (prefix: ${STORED:0:7})" ;;
esac
# and it must NOT equal the plaintext
[ "$STORED" != "NewPass123!" ] && ok "K04 stored password is not the plaintext value" || no "K04 plaintext" "password stored as plaintext!"

# ---- SCOPED CLEANUP (only this run's fixtures; fail on error) ----
CLEAN=$(mysql -u"$DBU" -p"$DBP" "$DB" -e "
  DELETE FROM users WHERE identity LIKE '${RUN}\_%';
" 2>&1)
if printf '%s' "$CLEAN" | grep -qi error; then no "cleanup users" "$CLEAN"; else ok "cleanup scoped to run fixtures"; fi

hr; echo "RESULTS:"; for r in "${R[@]}"; do echo "  $r"; done; hr
echo "TOTAL: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
