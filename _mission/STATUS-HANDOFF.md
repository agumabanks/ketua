# KETUA Mission — Status & Handoff (updated 2026-10-09)

Scope attempted: security remediation (K01–K17), feature repair, mission features,
UI redesign. This document records what is DONE and VERIFIED vs. what remains,
and precisely what is BLOCKED.

## Environment (verified)
- Backend: Laravel 8.83.29 at /var/www/ketua.sanaa.co/orange_backend, MySQL db `ketua` (empty of user data = clean staging-safe).
- Flutter: /var/www/ketua.sanaa.co/Orange (328 dart files). Host flutter 3.35 (Dart 3.9) CANNOT resolve deps; use /opt/flutter-3.47 (Dart 3.10+) — flutter_local_notifications 21 requires it.
- Deployment: nginx vhost ketua.sanaa.co -> orange_backend/public. API was fully DOWN before this work (API_KEY unset -> all /api 500). Now UP.
- Backups (recoverable): /var/www/ketua_backups/20261009_040745/ (code tar, flutter tar, ketua_db.sql, .env.bak).

## ===== PHASE 1: SECURITY (K01–K17) — DONE & VERIFIED =====
Regression checker: orange_backend/scripts/security_check.sh — **10/10 PASS**.
Verified live (register->token->protected calls) AND on production (getSettingData 200 with key, 401 without).

FIXED:
- K01 per-user auth: Sanctum guard `app_users` + `AuthenticateAppUser` middleware + AuthController issuing bearer tokens. Protected: updateProfile, fetchUsersByCordinates, addCoinsToWallet, minusCoinsFromWallet, placeRedeemRequest, fetchMyRedeemRequests, auth/me, auth/logout.
- K02 wallet minting: addCoinsToWallet refuses client credit (403) + requires auth (401).
- K03 redeem: derives user from token; atomic DB::transaction + lockForUpdate.
- K04 plaintext password write: updateUser now Hash::make().
- K05 plaintext password compare: removed where('password',...) in addUserDetails; social login keys off identity only.
- K06 unauth admin reset: forgotPasswordForm now behind checkLogin (302 w/o session).
- K07 arbitrary upload: saveFileAndGivePath whitelists extensions, 50MB cap, random filename.
- K08 API down: API_KEY set in .env; config cleared. PROD API RESTORED.
- K10 password leak: Users::$hidden hides password/remember_token/device_token; /auth/me verified no password.
- K11 IDOR: deleteStoryFromWeb behind checkLogin; updateProfile image-delete scoped to owner.
- K12 fake login: gated by config ketua.allow_fake_login (default false -> 403); returns token not raw row.
- K13 location privacy: fetchUsersByCordinates requires auth, strips raw coords, returns rounded approx distance.
- K15 rate limiting: named `auth` (10/min) + `money` (20/min) throttles.
- Bonus: updateProfile no longer lets a user self-set is_verified (mission rule: payment/login never grants verified badge).

REMAINING (security):
- K09 client base URL + bearer wiring — DONE in Flutter (see Phase 2). Backend + client aligned.
- K14 admin password via Crypt (reversible) — recommend migrate to bcrypt; admin-only, low priority. NOT done.
- K16 verbose errors — APP_DEBUG already false; optional JSON error handler. NOT done.
- K17 secrets (Agora/RevenueCat/Firebase creds) — BLOCKED on external credentials. Code reads env correctly; only values missing.

## ===== PHASE 2: FLUTTER CLIENT AUTH (K09) — DONE & VERIFIED =====
Checker: Orange/scripts/flutter_check.sh — **ALL PASS** (0 analyzer errors, auth wiring present).
- ApiProvider: authHeaders() attaches `Authorization: Bearer <token>` to ALL requests; token persisted from register/login.
- SessionManager: setAuthToken/getAuthToken/isAuthenticated/clearSession.
- UserModel: added `token` field + parse.
- const_res.dart: real base URL https://ketua.sanaa.co/ ; apiKey synced to server API_KEY.
- Fixed genuine compile error: AppRes.isHttp was referenced but undefined (added).
- Removed polluting nested duplicate `Orange/flutter/` from analysis (.gitignore + analysis_options exclude). Tree analyzes 0 errors (6 pre-existing info lints remain).

## ===== PHASE 3: FEATURE REPAIR + MISSION FEATURES — DONE (server) =====
Checker: orange_backend/scripts/feature_check.sh — PASS. Built server-authoritative,
token-auth endpoints (all derive user from bearer token; no client user_id):

GIFTING (GiftController + gift_transactions ledger):
- POST /api/sendGift  — atomic wallet debit(sender)+credit(receiver), catalog-priced,
  immutable ledger row, receiver notification. Verified: 0-balance→402, funded→exact
  transfer (sender 100→90, receiver 0→10 +total_collected), ledger row, no-token→401.
- GET  /api/myGifts   — sent/received history.

MATCHING + SWIPE-UP STARS (MatchController + like_profiles.star):
- POST /api/match/like      — token-auth like, mutual-match detection. Verified matched:false→true.
- POST /api/match/star      — premium super-like, coin-gated (appdata.star_price), atomic debit.
  Verified: 0-balance→402, 100-balance price25→wallet75, no-token→401.
- POST /api/match/dislike, /api/match/myMatches — mutual matches list.

BOOSTS / HEARTBEAT / MILESTONES / COMPLETENESS (FeatureController):
- POST /api/boost         — paid 30-min visibility window (appdata.boost_price), extends active boost. Verified.
- POST /api/boost/status  — active boost + expiry. Verified.
- POST /api/heartbeat     — presence ping + 3/5-day consistency milestone evaluation (idempotent). Verified.
- POST /api/profile/completeness — 0-100 score + missing items. Verified (fixed a latent
  Users-model bug: `interests` relation method shadowed the `interests` column, causing a
  memory-exhaustion fatal; now reads via getOriginal()).

VERIFICATION SEPARATION (mission rule enforced):
- applyForVerification now derives user from token; is_verified=1 means PENDING (set here),
  =2 means VERIFIED (set ONLY by admin). updateProfile no longer allows self-setting is_verified.
  Payment/login/registration never grant the verified badge.

MIGRATIONS ADDED (all idempotent, applied):
- 2026_10_09_010000_add_new_user_free_coins_to_appdata (fixes registration crash)
- 2026_10_09_020000_create_gift_transactions_table
- 2026_10_09_030000_add_star_to_like_profiles
- 2026_10_09_040000_add_economy_settings_to_appdata (star_price, boost_price, milestone_days)
- 2026_10_09_050000_create_boost_heartbeat_milestone_tables

## ===== PHASE 2b: FLUTTER CLIENT FEATURE WIRING — DONE =====
- ApiProvider: added starProfile/matchLike/myMatches/sendGift/activateBoost/heartbeat/
  profileCompleteness (all via authHeaders() bearer token). urls.dart: added the endpoint constants.
- explore_screen_view_model: added onStarTap() (swipe-up Star) that calls /api/match/star,
  refreshes wallet from server response, shows match/star snackbar, opens diamond shop on
  insufficient coins. flutter_check.sh still ALL PASS (0 analyzer errors).

## ===== PHASE 1b: OWNERSHIP HARDENING (round 2) — DONE & VERIFIED =====
A systematic scan found many mutating endpoints still trusted client-supplied user_id.
Fixed to derive the acting user from the bearer token (client user_id ignored):
- minusCoinsFromWallet — debits ONLY the caller's wallet (verified: A's token + user_id=B,
  amount=50 → A 100→50, B unchanged; no-token→401). Closes cross-user wallet draining.
- deleteMyAccount — self-delete only (was: could delete ANY account). auth required.
- updateUserBlockList, logOutUser (also revokes the token), increaseStreamCountOfUser,
  updateLiveStatus, onOffVideoCalls, onOffAnonymous, onOffShowMeOnMap, onOffNotification.
All 9 now behind auth.app_users. Re-verified: security 10/10, feature 6/6, prod 200/401.
Remaining client-user_id readers are READ-only or admin-only (fetch* lists, search,
getRandomProfile, admin blockUser/unblockUser/allowLive under checkLogin) — acceptable;
admin endpoints are session-protected.

## ===== PHASE 4: UI REDESIGN (best-practice defaults) — DONE & VERIFIED =====
Mission attachments (design screenshots) never arrived, so I applied the redesign to the
stated best-practice requirements: dark surfaces, immersive/rounded controls, floating
navigation, and KETUA in UPPERCASE with a REAL font weight of 900. Checker:
Orange/scripts/design_check.sh — 9/9 PASS. Tree still analyzes 0 errors.
- lib/utils/color_res.dart: added dark surface tokens (bgDark/surfaceDark/surfaceDark2/
  borderDark/textPrimaryDark/textSecondaryDark) + KETUA accent gradient + gold.
- lib/utils/ketua_theme.dart (NEW): KetuaTheme.dark — full dark ThemeData (dark scaffold,
  rounded cards/sheets/dialogs/inputs, StadiumBorder buttons), and brandWordmark() that
  renders "KETUA" UPPERCASE with fontFamily gilroy_heavy + FontWeight.w900 (true 900).
- lib/common/ketua_wordmark.dart (NEW): reusable ShaderMask gradient wordmark widget.
- lib/main.dart: theme/darkTheme = KetuaTheme.dark, themeMode = dark.
- lib/utils/app_res.dart: appName 'Orange' -> 'KETUA'.
- lib/screen/splash_screen: renders the KETUA weight-900 gradient wordmark + tagline.
- lib/screen/dashboard: floating navigation bar — rounded (r=28), dark surface, border,
  drop shadow, inset 16px, animated selected pill (replaces the flat bar + top border).
NOTE: only the foundation surfaces are re-skinned; individual inner screens still use the
old per-screen colors. The theme + tokens + reusable wordmark make re-skinning the rest
mechanical. If the design screenshots arrive, I'll match exact hex/shapes per screen.

## ===== PHASE 5: GOLD PLANS / SUBSCRIPTIONS (server-authoritative) — DONE & VERIFIED =====
Checker: feature_check.sh subscription checks PASS. Built even without RevenueCat keys —
activates the moment keys + webhook secret are set.
- Migration 2026_10_09_060000_create_subscriptions_table + Subscription model.
- SubscriptionController:
  - GET /api/subscription/status (auth): returns caller's entitlement (active/plan/expires).
    Verified: no-sub -> active:false; no-token -> 401.
  - POST /api/webhooks/revenuecat: provider-authorized by REVENUECAT_WEBHOOK_SECRET
    (Bearer), idempotent on (provider, provider_txn_id). Verified: wrong secret -> 401;
    correct secret -> 200 grants gold; replay -> no duplicate row; status flips to active.
- Payment/subscription NEVER sets is_verified (mission rule preserved).

## ===== PHASE 4b: SCREEN-LEVEL DARK RETHEME — DONE =====
Extended the dark theme to high-traffic surfaces (foundation + these compile 0 errors):
- subscription_sheet (plan selection): SubscriptionBG white->bgDark, accent blobs ->
  ketuaAccent/ketuaAccent2, feature card -> surfaceDark + borderDark, plan cards ->
  surfaceDark fill + ketuaAccent selected border, close btn -> surfaceDark2, icons/text ->
  dark tokens. This is the "clear plan selection" surface.
- Verified already-dark (no change needed): create_story_screen + story_view_screen use
  black immersive backgrounds with white media controls; explore_screen inherits theme.
- profile_screen: white refs are text/icons over photos (correct to keep); scaffold
  inherits dark theme.
design_check.sh still 9/9; flutter analyze 0 errors.

## ===== STILL BLOCKED / NOT DONE =====
- K17 remaining credentials: Agora app id/cert (LIVE STREAMING token minting),
  RevenueCat android/apple SDK keys + real webhook secret (client purchase flow; server
  entitlement machinery is DONE), Firebase googleCredentials.json (push notifications).
  Code reads all from env; only values missing. Live streaming + client IAP purchase UI +
  push cannot be exercised end-to-end without them.
- Short video / reels, creator subscription PAYOUTS: no existing substrate; need spec.
- Chat is Firestore-based client-side (works; out of scope).
- Physical-device Android/iPhone testing: cannot run on this host.

## ===== BLOCKERS (need from user) =====
1. Mission attachments: HERMES-KETUA-MISSION.md, ketua-security-audit-2026-10-09.md, composer-audit.json,
   IMG_3744–3756.jpeg -> upload to /var/www/ketua.sanaa.co/_mission/.
2. External credentials (K17): Agora app id/cert, RevenueCat android+apple keys, Firebase googleCredentials.json.

## ===== HOW TO RERUN ALL CHECKERS =====
Backend security (start local server first):
  cd /var/www/ketua.sanaa.co/orange_backend
  php artisan serve --host=127.0.0.1 --port=8899 &
  bash scripts/security_check.sh http://127.0.0.1:8899 "$(grep ^API_KEY= .env | cut -d= -f2)"
Flutter:
  cd /var/www/ketua.sanaa.co/Orange
  bash scripts/flutter_check.sh

## ===== MIGRATIONS =====
- 2026_10_09_010000_add_new_user_free_coins_to_appdata.php (applied). Idempotent.
Rollback: php artisan migrate:rollback --step=1 (drops the column). Code backup above restores everything.

## ===== NOT DONE / HUMAN ACTIONS =====
- Provide attachments + credentials (above).
- Production deploy authorization (NOT requested/granted — changes are live-in-place already since user chose work-in-place; API restored on prod as a side effect of K08).
- Android/iPhone physical-device testing of the Flutter app (cannot run here).
- K14 bcrypt migration for admin password; K16 JSON error handler (optional hardening).
