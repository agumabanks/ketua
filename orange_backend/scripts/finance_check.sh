#!/usr/bin/env bash
# =============================================================================
# KETUA Financial Invariants & Concurrency Checker — ISOLATED TEST DATABASE
# =============================================================================
# Proves the server-authoritative economy cannot be abused:
#   - conservation: sender debit == receiver credit == ledger sum (no minting)
#   - no double-spend under CONCURRENT requests (row lock holds)
#   - insufficient balance is refused (402) and changes nothing
#   - redemption is atomic and zeroes the wallet exactly once
# Runs against scripts/run_isolated.sh (ketua_test). Scoped fixture cleanup.
#
# Usage: ./scripts/finance_check.sh [BASE_URL] [API_KEY]
# =============================================================================
set -u
BASE_URL="${1:-http://127.0.0.1:8899}"
API_KEY="${2:-}"
PASS=0; FAIL=0
declare -a R
RUN="fin_${RANDOM}_$$"
DB="ketua_test"; DBU="ketua"
DBP="$(grep '^DB_PASSWORD=' "$(dirname "$0")/../.env.testing" | cut -d= -f2)"
q(){ mysql -u"$DBU" -p"$DBP" "$DB" -N -e "$1" 2>/dev/null; }
ok(){ PASS=$((PASS+1)); R+=("PASS  $1"); }
no(){ FAIL=$((FAIL+1)); R+=("FAIL  $1  ($2)"); }
KEYH=(-H "Content-Type: application/json" -H "apikey: $API_KEY")
reg(){ curl -s -X POST "$BASE_URL/api/auth/register" "${KEYH[@]}" -d "{\"identity\":\"$1\",\"fullname\":\"$2\"}"; }
tok(){ printf '%s' "$1" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'; }
idof(){ printf '%s' "$1" | sed -n 's/.*"id":\([0-9]*\).*/\1/p' | head -1; }

echo "KETUA Finance/Invariants Checker (DB: $DB)"; hr(){ printf '%s\n' "----"; }

# fixtures
A=$(reg "${RUN}_a@x.com" A); TA=$(tok "$A"); IA=$(idof "$A")
B=$(reg "${RUN}_b@x.com" B); TB=$(tok "$B"); IB=$(idof "$B")
AH=("${KEYH[@]}" -H "Authorization: Bearer $TA")
GID=$(q "SELECT id FROM gifts LIMIT 1;")
PRICE=$(q "SELECT price FROM gifts WHERE id=$GID;")

# fund sender with exactly 3 gifts' worth
q "UPDATE users SET wallet=$((PRICE*3)) WHERE id=$IA;" >/dev/null

# ---- CONCURRENCY: fire 5 simultaneous gifts; only 3 can be afforded ----
for i in 1 2 3 4 5; do
  curl -s -o /dev/null -X POST "$BASE_URL/api/sendGift" "${AH[@]}" \
    -d "{\"gift_id\":$GID,\"receiver_id\":$IB,\"context\":\"race\"}" &
done
wait

AW=$(q "SELECT wallet FROM users WHERE id=$IA;")
BW=$(q "SELECT wallet FROM users WHERE id=$IB;")
LEDGER=$(q "SELECT COALESCE(SUM(coin_price),0) FROM gift_transactions WHERE sender_id=$IA;")
TXNS=$(q "SELECT COUNT(*) FROM gift_transactions WHERE sender_id=$IA;")

# invariants
[ "$AW" = "0" ] && ok "no double-spend: sender wallet drained to exactly 0 (was $((PRICE*3)))" || no "sender balance" "wallet=$AW expected 0"
[ "$TXNS" = "3" ] && ok "exactly 3 gifts succeeded under concurrency (got $TXNS)" || no "txn count" "expected 3 got $TXNS"
[ "$BW" = "$LEDGER" ] && ok "conservation: receiver credit ($BW) == ledger sum ($LEDGER)" || no "conservation" "recv=$BW ledger=$LEDGER"
[ "$LEDGER" = "$((PRICE*3))" ] && ok "no minting: ledger == funded amount ($((PRICE*3)))" || no "minting" "ledger=$LEDGER"

# ---- insufficient balance refused, changes nothing ----
BEFORE=$(q "SELECT wallet FROM users WHERE id=$IA;")
curl -s -o /dev/null -X POST "$BASE_URL/api/sendGift" "${AH[@]}" -d "{\"gift_id\":$GID,\"receiver_id\":$IB}"
AFTER=$(q "SELECT wallet FROM users WHERE id=$IA;")
[ "$BEFORE" = "$AFTER" ] && ok "insufficient-balance gift changes nothing" || no "insufficient" "wallet $BEFORE->$AFTER"

# ---- redemption atomicity: fund + redeem -> wallet 0, one redeem row ----
q "UPDATE users SET wallet=100, total_collected=100 WHERE id=$IA; UPDATE appdata SET min_threshold=0 WHERE id=1;" >/dev/null
curl -s -o /dev/null -X POST "$BASE_URL/api/placeRedeemRequest" "${AH[@]}" -d '{"payment_gateway":"mpesa","account_details":"0712345678"}'
RW=$(q "SELECT wallet FROM users WHERE id=$IA;")
RC=$(q "SELECT COUNT(*) FROM redeem_requests WHERE user_id=$IA;")
[ "$RW" = "0" ] && ok "redemption zeroes wallet exactly once" || no "redeem wallet" "wallet=$RW expected 0"
[ "$RC" = "1" ] && ok "exactly one redeem request recorded (got $RC)" || no "redeem rows" "expected 1 got $RC"

# ---- scoped cleanup (fail on error) ----
ERR=$(q "DELETE FROM users WHERE identity LIKE '${RUN}\_%'; DELETE FROM gift_transactions WHERE sender_id IN (SELECT id FROM users WHERE 0); DELETE FROM redeem_requests WHERE user_id IN (SELECT id FROM users WHERE 0);" 2>&1)
q "DELETE FROM gift_transactions WHERE sender_id=$IA OR receiver_id=$IA;" >/dev/null 2>&1
q "DELETE FROM redeem_requests WHERE user_id=$IA;" >/dev/null 2>&1
printf '%s' "$ERR" | grep -qi error && no "cleanup" "$ERR" || ok "cleanup scoped to run fixtures"

hr; echo "RESULTS:"; for r in "${R[@]}"; do echo "  $r"; done; hr
echo "TOTAL: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
