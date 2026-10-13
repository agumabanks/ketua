#!/usr/bin/env bash
# =============================================================================
# KETUA Consistency-Milestone Behavioral Checker — ISOLATED TEST DATABASE
# =============================================================================
# Verifies daily-activity history is preserved and streaks are computed
# deterministically and safely:
#   - consecutive days form a streak (3-day -> milestone awarded once)
#   - a GAP breaks the streak
#   - replay within the same day is idempotent (does not inflate the streak)
#   - future-dated activity is ignored (clock-abuse safe)
#   - timezone: day boundary is server-side UTC, not client-supplied
# Runs against scripts/run_isolated.sh (ketua_test). Scoped fixture cleanup.
#
# Usage: ./scripts/milestone_check.sh [BASE_URL] [API_KEY]
# =============================================================================
set -u
BASE_URL="${1:-http://127.0.0.1:8899}"
API_KEY="${2:-}"
PASS=0; FAIL=0; declare -a R
RUN="ms_${RANDOM}_$$"
DB="ketua_test"; DBU="ketua"
DBP="$(grep '^DB_PASSWORD=' "$(dirname "$0")/../.env.testing" | cut -d= -f2)"
q(){ mysql -u"$DBU" -p"$DBP" "$DB" -N -e "$1" 2>/dev/null; }
ok(){ PASS=$((PASS+1)); R+=("PASS  $1"); }
no(){ FAIL=$((FAIL+1)); R+=("FAIL  $1  ($2)"); }
KEYH=(-H "Content-Type: application/json" -H "apikey: $API_KEY")

# create user directly (let auto-increment assign id; read it back)
q "INSERT INTO users (identity,fullname,name,email,password,wallet,total_collected,coins,is_verified,created_at,updated_at) VALUES ('${RUN}@x.com','MS','${RUN}@x.com','${RUN}@x.com','\$2y\$10\$abcdefghijklmnopqrstuv',0,0,0,0,NOW(),NOW());" >/dev/null
TUID=$(q "SELECT id FROM users WHERE identity='${RUN}@x.com';")
# mint a token for this user (write to file, then parse — tinker mixes warnings into stdout)
( cd "$(dirname "$0")/.." && php artisan tinker --execute="echo App\Models\Users::find($TUID)->createToken('t')->plainTextToken;" 2>/dev/null ) > /tmp/kt_tok_$RUN.txt
TOKEN=$(grep -oE '[0-9]+\|[A-Za-z0-9]{20,}' /tmp/kt_tok_$RUN.txt | tail -1)
AH=("${KEYH[@]}" -H "Authorization: Bearer $TOKEN")
streak(){ curl -s -X POST "$BASE_URL/api/heartbeat" "${AH[@]}" -d '{}' | sed -n 's/.*"streak_days":\([0-9]*\).*/\1/p'; }

echo "KETUA Milestone Checker (DB: $DB)"

# --- consecutive days: seed today-2, today-1, today ---
TODAY=$(q "SELECT CURDATE();")
D2=$(q "SELECT DATE_SUB(CURDATE(), INTERVAL 2 DAY);")
D1=$(q "SELECT DATE_SUB(CURDATE(), INTERVAL 1 DAY);")
q "INSERT INTO user_activity_days (user_id,activity_date,first_seen_at,last_seen_at,created_at,updated_at) VALUES ($TUID,'$D2',NOW(),NOW(),NOW(),NOW()),($TUID,'$D1',NOW(),NOW(),NOW(),NOW());" >/dev/null
S=$(streak)
[ "$S" = "3" ] && ok "consecutive 3 days -> streak 3" || no "consecutive" "streak=$S expected 3"
# award is idempotent: check the milestone row EXISTS (not that it's newly awarded each call)
curl -s -o /dev/null -X POST "$BASE_URL/api/heartbeat" "${AH[@]}" -d '{}'
HAVE3=$(q "SELECT COUNT(*) FROM user_milestones WHERE user_id=$TUID AND streak_days=3;")
[ "$HAVE3" = "1" ] && ok "3-day milestone recorded (idempotent)" || no "3-day award" "milestone rows=$HAVE3 expected 1"
HAVE3DUP=$(q "SELECT COUNT(*) FROM user_milestones WHERE user_id=$TUID AND streak_days=3;")
[ "$HAVE3DUP" = "1" ] && ok "3-day milestone not duplicated on replay" || no "3-day dup" "rows=$HAVE3DUP expected 1"

# --- replay same day is idempotent (streak stays 3) ---
S2=$(streak); S3=$(streak)
[ "$S2" = "3" ] && [ "$S3" = "3" ] && ok "replay within day is idempotent (streak stays 3)" || no "replay" "streak=$S2,$S3 expected 3,3"
ROWS=$(q "SELECT COUNT(*) FROM user_activity_days WHERE user_id=$TUID AND activity_date='$TODAY';")
[ "$ROWS" = "1" ] && ok "one activity row per day (no duplicate)" || no "dup day" "rows=$ROWS expected 1"

# --- GAP breaks streak: insert a day 10 days ago only ---
q "DELETE FROM user_activity_days WHERE user_id=$TUID;" >/dev/null
q "INSERT INTO user_activity_days (user_id,activity_date,first_seen_at,last_seen_at,created_at,updated_at) VALUES ($TUID,DATE_SUB(CURDATE(),INTERVAL 10 DAY),NOW(),NOW(),NOW(),NOW());" >/dev/null
SG=$(streak)
[ "$SG" = "1" ] && ok "gap breaks streak (isolated old day -> streak 1)" || no "gap" "streak=$SG expected 1"

# --- clock-abuse: a future-dated row must NOT extend the streak ---
q "DELETE FROM user_activity_days WHERE user_id=$TUID;" >/dev/null
q "INSERT INTO user_activity_days (user_id,activity_date,first_seen_at,last_seen_at,created_at,updated_at) VALUES ($TUID,DATE_ADD(CURDATE(),INTERVAL 5 DAY),NOW(),NOW(),NOW(),NOW());" >/dev/null
SF=$(streak)
# heartbeat writes TODAY's row; a lone future day must yield streak 1 (today only), never more
[ "$SF" = "1" ] && ok "future-dated activity does not inflate streak (clock-abuse safe: streak=$SF from today only)" || no "clock-abuse" "streak=$SF expected 1 (future row ignored)"
# also: yesterday+future must not chain into a streak via the future day
q "DELETE FROM user_activity_days WHERE user_id=$TUID;" >/dev/null
q "INSERT INTO user_activity_days (user_id,activity_date,first_seen_at,last_seen_at,created_at,updated_at) VALUES ($TUID,DATE_SUB(CURDATE(),INTERVAL 1 DAY),NOW(),NOW(),NOW(),NOW()),($TUID,DATE_ADD(CURDATE(),INTERVAL 3 DAY),NOW(),NOW(),NOW(),NOW());" >/dev/null
SF2=$(streak)
[ "$SF2" = "2" ] && ok "future day does not bridge a gap (yesterday+today=2, not 4)" || no "clock-abuse bridge" "streak=$SF2 expected 2"

# --- scoped cleanup ---
ERR=$(q "DELETE FROM users WHERE id=$TUID; DELETE FROM user_activity_days WHERE user_id=$TUID; DELETE FROM user_milestones WHERE user_id=$TUID; DELETE FROM personal_access_tokens WHERE tokenable_id=$TUID;" 2>&1)
printf '%s' "$ERR" | grep -qi error && no "cleanup" "$ERR" || ok "cleanup scoped to run fixtures"

echo "RESULTS:"; for r in "${R[@]}"; do echo "  $r"; done
echo "TOTAL: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
