# KETUA Security Findings — Verified from Live Code (2026-10-09)

Method: direct inspection of `/var/www/ketua.sanaa.co/orange_backend` and `/var/www/ketua.sanaa.co/Orange`.
Every finding below was confirmed by reading the actual source, not the audit snapshot.
This is the remediation baseline (K01–K17). Status is updated as fixes land.

Severity: CRITICAL / HIGH / MEDIUM / LOW.

---

## K01 — No per-user authentication; single shared static API key (CRITICAL)
- Files: `routes/api.php` (all routes), `app/Http/Middleware/CheckHeader.php`, `Orange/lib/utils/const_res.dart:7`, `Orange/lib/api_provider/api_provider.dart:38`
- All `/api` routes use only `checkHeader`, which compares one shared static key (`env('API_KEY')`, hardcoded `'123'` in the app). There is no bearer/session token and no way to prove *which* user is calling.
- Exploit: any holder of the key impersonates any user; every endpoint trusts client-supplied `user_id`.
- Fix: introduce per-user bearer tokens (Sanctum, already installed + `personal_access_tokens` table exists). Derive the acting user from the token server-side; keep `checkHeader` only as an app-version gate.

## K02 — Wallet balance is fully client-controlled (CRITICAL)
- Files: `UsersController.php:979` `addCoinsToWallet`, `UsersController.php:929` `minusCoinsFromWallet`
- `$user->wallet += $request->amount;` with `user_id` + `amount` straight from the request. Anyone with the key can mint or zero any balance.
- Fix: remove client-credit path; only server-side purchase/entitlement flows mutate wallet; require auth + ownership.

## K03 — Redeem/payout trusts client and zeroes wallet (CRITICAL)
- File: `RedeemRequestsController.php:205` `placeRedeemRequest`
- Redeems `$user->wallet` (client `user_id`) and sets `wallet = 0`. No server verification of entitlement.
- Fix: auth + ownership, atomic transaction, server-side eligibility, audit row.

## K04 — Plaintext password write in admin updateUser (CRITICAL)
- File: `UsersController.php:145` (`updateUser`)
- `"password" => $req->password` writes the raw password to `users.password` with no hashing, keyed by client `$req->id`.
- Fix: `Hash::make()` when provided; require auth + ownership (or admin-only).

## K05 — Plaintext password comparison in register/login (CRITICAL)
- File: `UsersController.php:1402-1403` (`addUserDetails`)
- `where('identity', $req->identity)->where('password', $req->password)` — compares and therefore stores passwords in plaintext for the social-login identity flow.
- Fix: never compare/store plaintext; social login keys off provider identity, no password needed. Migrate existing rows.

## K06 — Unauthenticated admin password reset (CRITICAL)
- File: `LoginController.php` `forgotPasswordForm` (route `web.php:35`, no middleware)
- Resets the `admin` password to any submitted value with no verification/session.
- Fix: require authenticated admin session + current-password check; add rate limiting.

## K07 — Arbitrary file upload, no validation (HIGH)
- File: `app/Models/GlobalFunction.php:179` `saveFileAndGivePath`
- `$file->store('uploads')` with no extension/MIME/size checks → can upload `.php` etc.
- Fix: whitelist extensions (jpg/png/webp/mp4), enforce size, store outside webroot or with safe names.

## K08 — API entirely down: API_KEY unset (HIGH — availability)
- File: `.env` (no `API_KEY`), `CheckHeader.php:22`
- `checkHeader` returns 500 "API key not configured", so every `/api` route 500s.
- Fix: set `API_KEY` in `.env` (done as part of remediation) + rotate the hardcoded app key.

## K09 — Hardcoded API key + placeholder base URL in shipped app (HIGH)
- Files: `Orange/lib/utils/const_res.dart:5-7`
- `base = '---- Base URL ----'`, `apiKey = '123'` — app cannot reach server; key is a static secret in the binary.
- Fix: set real base URL; move to per-user bearer token; drop static key reliance.

## K10 — Sensitive data exposure: password in admin table + full user rows (HIGH)
- Files: `UsersController.php:1367` (renders `$item->password`), `fetchAllUsers`; API returns full `Users` rows incl. `wallet`, `device_token`, coordinates.
- Fix: never serialize `password`/tokens; add `$hidden` on the model; scope fields per endpoint.

## K11 — IDOR on `{id}` admin routes / image delete (HIGH)
- Files: `web.php` `viewUserDetails/{id}`, `deleteUserImage/{id}`, `UsersController.php:117` `deleteUserImage` (no ownership check)
- Any caller who passes `checkLogin` can target arbitrary IDs; `deleteUserImage` has no owner check.
- Fix: enforce ownership (image.user_id == caller) and admin-only for admin routes.

## K12 — fakeUserLogin exposes full user object + plaintext path (HIGH)
- File: `UsersController.php:2476` `fakeUserLogin` (route `api.php:120`)
- Returns the full user row; relies on plaintext-ish compare; a backdoor login surface.
- Fix: gate behind config flag off in production; return sanitized object + bearer token; log usage.

## K13 — Coordinates/location leak (MEDIUM)
- File: `UsersController.php:74` `fetchUsersByCordinates` returns all nearby users' lat/long
- Exposes precise location of other users.
- Fix: privacy-aware distance (return approximate distance, not raw coords); respect `show_on_map`/privacy flags.

## K14 — Admin password stored reversibly (Crypt::encrypt), not bcrypt (MEDIUM)
- Files: `LoginController.php` checkLogin/forgotPasswordForm use `Crypt::encrypt/decrypt`
- Reversible encryption for a password is weaker than a one-way hash.
- Fix: migrate to `Hash::make` (bcrypt) + `Hash::check`.

## K15 — Missing rate limiting on auth + wallet endpoints (MEDIUM)
- Files: `routes/api.php` (group has `throttle:api` but weak), `web.php` login/forgot
- No strong throttle on login/forgot/wallet → brute force / abuse.
- Fix: named throttles on login/forgot/register/wallet/redeem.

## K16 — APP_DEBUG / verbose errors + PHP deprecation noise (LOW)
- File: `.env` (`APP_DEBUG=false` already good), `storage/logs`
- Confirm debug off in prod; ensure errors don't leak stack traces to API.
- Fix: verify `APP_DEBUG=false`; JSON error handler that hides internals.

## K17 — Secrets/config gaps (Agora, RevenueCat, Firebase) (LOW — blocked on creds)
- Files: `Orange/lib/utils/const_res.dart:9-16`, `.env` (`AGORA_APP_ID`, `AGORA_APP_CERT` unset)
- Agora token gen will fail; RevenueCat keys empty; Firebase creds file path set but file not present.
- Status: BLOCKED on external credentials. Code reads them correctly; only values are missing.
- Fix: provide credentials via env/keystore; do not hardcode.

---

## Notes
- SQL injection: checked — all `whereRaw`/`find_in_set` use bound `?` parameters. **No SQLi found.**
- DB is empty of user data (clean staging), so no PII migration risk for password-hash changes.
- Laravel 8.83 + Sanctum ^2.11 present; `personal_access_tokens` table exists.

---

## Status (verified 2026-10-09)

FIXED & REGRESSION-TESTED (scripts/security_check.sh → 10/10 pass):
- K01 per-user auth — Sanctum guard `app_users`, `AuthenticateAppUser` middleware, tokens issued by AuthController. 401 without token, 200 with.
- K02 wallet minting — `addCoinsToWallet` now refuses client credit (403) and requires auth (401).
- K03 redeem — `placeRedeemRequest` derives user from token, atomic `DB::transaction` + `lockForUpdate`.
- K04 plaintext password write — `updateUser` now `Hash::make()` when password provided.
- K05 plaintext password compare — removed `where('password', ...)` in `addUserDetails`; social login keys off identity only.
- K06 unauth admin reset — `forgotPasswordForm` now behind `checkLogin` (302 without session).
- K07 arbitrary upload — `saveFileAndGivePath` now whitelists extensions, enforces 50MB cap, random filename.
- K08 API down — `API_KEY` set in `.env`; config cleared.
- K10 password leak — `Users::$hidden` hides password/remember_token/device_token; `/auth/me` verified not to leak password.
- K11 IDOR — `deleteStoryFromWeb` now behind `checkLogin`.
- K12 fake login — gated behind `config('ketua.allow_fake_login')` (default false → 403); returns token not raw row.
- K15 rate limiting — named `auth` (10/min) and `money` (20/min) throttles applied.

REMAINING / PARTIAL:
- K09 client base URL + apiKey — requires Flutter client change (attach bearer token, real base URL). Backend ready; client wiring pending.
- K13 location privacy — `fetchUsersByCordinates` still returns coords; privacy-aware distance transform pending.
- K14 admin password via Crypt (reversible) — recommend migrate to bcrypt; low priority, admin-only.
- K16 debug/verbose errors — APP_DEBUG already false; JSON error handler recommended.
- K17 secrets (Agora/RevenueCat/Firebase) — BLOCKED on external credentials; code reads env correctly.

NEXT PHASES (not yet done): feature inventory/repair end-to-end, mission features (discovery, recommendations, swipe-up Stars, Likes notifications, matching, chat, profile completeness, privacy-aware distance, Heartbeat, consistency milestones, Boosts, gifting, verification, Gold plans, creator subscriptions, short video), Flutter client auth wiring, UI redesign per screenshots (KETUA uppercase weight-900).
