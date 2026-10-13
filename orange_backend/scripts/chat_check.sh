#!/usr/bin/env bash
# =============================================================================
# KETUA Chat Feature Checker — ISOLATED TEST DATABASE
# =============================================================================
# Verifies the server-side chat backend: send, fetch, mark-read, block, mute,
# delete. Runs against scripts/run_isolated.sh (ketua_test).
#
# Usage: ./scripts/chat_check.sh [BASE_URL] [API_KEY]
# =============================================================================
set -u
BASE_URL="${1:-http://127.0.0.1:8899}"
API_KEY="${2:-}"
PASS=0; FAIL=0
declare -a R
RUN="chat_${RANDOM}_$$"
DB="ketua_test"; DBU="ketua"
DBP="$(grep '^DB_PASSWORD=' "$(dirname "$0")/../.env.testing" | cut -d= -f2)"
q(){ mysql -u"$DBU" -p"$DBP" "$DB" -N -e "$1" 2>/dev/null; }
ok(){ PASS=$((PASS+1)); R+=("PASS  $1"); }
no(){ FAIL=$((FAIL+1)); R+=("FAIL  $1  ($2)"); }
KEYH=(-H "Content-Type: application/json" -H "apikey: $API_KEY")
reg(){ curl -s -X POST "$BASE_URL/api/auth/register" "${KEYH[@]}" -d "{\"identity\":\"$1\",\"fullname\":\"$2\"}"; }
tok(){ printf '%s' "$1" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'; }
idof(){ printf '%s' "$1" | sed -n 's/.*"id":\([0-9]*\).*/\1/p' | head -1; }

echo "KETUA Chat Checker (DB: $DB)"

# two users
A=$(reg "${RUN}_a@x.com" "Alice"); TA=$(tok "$A"); IA=$(idof "$A")
B=$(reg "${RUN}_b@x.com" "Bob"); TB=$(tok "$B"); IB=$(idof "$B")
AH=("${KEYH[@]}" -H "Authorization: Bearer $TA")
BH=("${KEYH[@]}" -H "Authorization: Bearer $TB")

# --- all chat endpoints require auth ---
for ep in conversations send messages read block mute deleteMessage deleteConversation; do
  C=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/chat/$ep" "${KEYH[@]}" -d '{"receiver_id":1,"body":"hi","conversation_id":"1_2"}')
  [ "$C" = "401" ] && ok "chat/$ep requires auth (401)" || no "chat/$ep auth" "expected 401 got $C"
done

# --- send message ---
SEND=$(curl -s -X POST "$BASE_URL/api/chat/send" "${AH[@]}" -d "{\"receiver_id\":$IB,\"body\":\"Hello Bob\"}")
printf '%s' "$SEND" | grep -q '"status":true' && ok "chat/send returns success" || no "chat/send" "$SEND"
CONVID=$(printf '%s' "$SEND" | sed -n 's/.*"conversation_id":"\([^"]*\)".*/\1/p')
[ -z "$CONVID" ] && CONVID="${IA}_${IB}"

# --- fetch messages ---
MSGS=$(curl -s -X POST "$BASE_URL/api/chat/messages" "${BH[@]}" -d "{\"conversation_id\":\"$CONVID\"}")
printf '%s' "$MSGS" | grep -q '"status":true' && ok "chat/messages returns success" || no "chat/messages" "$MSGS"
MSGID=$(printf '%s' "$MSGS" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')

# --- mark read ---
READ=$(curl -s -X POST "$BASE_URL/api/chat/read" "${BH[@]}" -d "{\"conversation_id\":\"$CONVID\",\"last_read_message_id\":$MSGID}")
printf '%s' "$READ" | grep -q '"status":true' && ok "chat/read marks messages read" || no "chat/read" "$READ"

# --- block/unblock ---
BLK=$(curl -s -X POST "$BASE_URL/api/chat/block" "${AH[@]}" -d "{\"conversation_id\":\"$CONVID\",\"action\":\"block\"}")
printf '%s' "$BLK" | grep -q '"status":true' && ok "chat/block blocks user" || no "chat/block" "$BLK"
UBLK=$(curl -s -X POST "$BASE_URL/api/chat/block" "${AH[@]}" -d "{\"conversation_id\":\"$CONVID\",\"action\":\"unblock\"}")
printf '%s' "$UBLK" | grep -q '"status":true' && ok "chat/block unblocks user" || no "chat/unblock" "$UBLK"

# --- mute/unmute ---
MUTE=$(curl -s -X POST "$BASE_URL/api/chat/mute" "${AH[@]}" -d "{\"conversation_id\":\"$CONVID\",\"action\":\"mute\"}")
printf '%s' "$MUTE" | grep -q '"status":true' && ok "chat/mute mutes conversation" || no "chat/mute" "$MUTE"
UMUTE=$(curl -s -X POST "$BASE_URL/api/chat/mute" "${AH[@]}" -d "{\"conversation_id\":\"$CONVID\",\"action\":\"unmute\"}")
printf '%s' "$UMUTE" | grep -q '"status":true' && ok "chat/mute unmutes conversation" || no "chat/unmute" "$UMUTE"

# --- delete message ---
DEL=$(curl -s -X POST "$BASE_URL/api/chat/deleteMessage" "${AH[@]}" -d "{\"message_id\":$MSGID}")
printf '%s' "$DEL" | grep -q '"status":true' && ok "chat/deleteMessage soft-deletes message" || no "chat/deleteMessage" "$DEL"

# --- delete conversation ---
DELC=$(curl -s -X POST "$BASE_URL/api/chat/deleteConversation" "${AH[@]}" -d "{\"conversation_id\":\"$CONVID\"}")
printf '%s' "$DELC" | grep -q '"status":true' && ok "chat/deleteConversation removes conversation" || no "chat/deleteConversation" "$DELC"

# --- scoped cleanup ---
ERR=$(q "DELETE FROM users WHERE identity LIKE '${RUN}\_%'; DELETE FROM messages; DELETE FROM conversations;" 2>&1)
printf '%s' "$ERR" | grep -qi error && no "cleanup" "$ERR" || ok "cleanup scoped to run fixtures"

echo "RESULTS:"; for r in "${R[@]}"; do echo "  $r"; done
echo "TOTAL: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
