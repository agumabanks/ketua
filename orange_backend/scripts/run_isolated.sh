#!/usr/bin/env bash
# =============================================================================
# KETUA Isolated Test Runner
# =============================================================================
# Boots a local PHP server bound to the ISOLATED ketua_test database so no
# checker can ever read or mutate production data. Guards:
#   - copies .env.testing over .env (backing up the live .env first),
#   - asserts DB_DATABASE == ketua_test before starting,
#   - restores the live .env on exit.
#
# Usage:  ./scripts/run_isolated.sh <port>
# Then in another shell run the checkers against http://127.0.0.1:<port>
# =============================================================================
set -eu
cd "$(dirname "$0")/.."
PORT="${1:-8899}"
LIVE_ENV_BAK=".env.live.bak"

restore() {
  if [ -f "$LIVE_ENV_BAK" ]; then mv "$LIVE_ENV_BAK" .env && echo "[run_isolated] restored live .env"; fi
}
trap restore EXIT INT TERM

# Safety: refuse if the testing env is missing or points anywhere but ketua_test.
TESTDB=$(grep '^DB_DATABASE=' .env.testing | cut -d= -f2)
if [ "$TESTDB" != "ketua_test" ]; then
  echo "[run_isolated] REFUSING: .env.testing DB_DATABASE is '$TESTDB', expected 'ketua_test'." >&2
  exit 2
fi

cp .env "$LIVE_ENV_BAK"
cp .env.testing .env
php artisan config:clear >/dev/null 2>&1

# Double-check the active env really targets the test DB before serving.
ACTIVE=$(grep '^DB_DATABASE=' .env | cut -d= -f2)
if [ "$ACTIVE" != "ketua_test" ]; then
  echo "[run_isolated] REFUSING: active DB is '$ACTIVE'." >&2; exit 2
fi

echo "[run_isolated] serving on 127.0.0.1:$PORT against DB '$ACTIVE' (production untouched)"
exec php artisan serve --host=127.0.0.1 --port="$PORT"
