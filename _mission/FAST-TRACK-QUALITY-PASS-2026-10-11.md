# KETUA immediate quality pass — 11 October 2026

This work pulls engineering improvements forward from the 90-day priorities. The dates in that document are product priorities, not a requirement to wait before improving the app. Market leadership cannot be certified from a test suite; dependable journeys and genuine supply remain essential.

## Implemented in this pass

- Personal updates restore an encrypted, account-scoped snapshot, then refresh. Refresh failures preserve existing messages, clear the busy state and offer retry. Platform tab revisits reuse loaded results. Empty lists can be refreshed.
- Notification and Explore requests discard late responses after an account change. Event snapshots separate Party tonight from the full category, and exclude past events from discovery.
- Places and event browsing restore saved results without treating them as current inventory. Tickets, balances, purchases and availability still come from the server. Saved and previous-results states are labelled.
- Opening a listing fetches current public venue metadata alongside current availability. Private owner fields are excluded. Requests are disabled on availability failure; removed or sold-out selections are cleared after refresh.
- Reservation cancellation requires confirmation. Successful reservation and wallet retries clear old errors. The wallet displays a checking state rather than a false zero before loading.
- Notification empty states explain what belongs in each tab in English, French and Swahili. Wallet instructions and the amount field have a verified 24dp gap.
- Explore cards adapt to narrow screens and large text; venue detail spacing, creator-content price formatting and safe-area scrolling are improved.

## Acceptance evidence

49 Flutter tests pass, including offline notification preservation/retry, account-switch isolation, tab reuse and Explore at 320dp with 200% text. The analyzer has zero errors; 198 warning/information findings remain and are not represented as a clean certification.

The repeatable backend checker passes 132 assertions across production guards, bookings, withdrawals, funded gift earnings, premium allowances and native readiness. This includes 24 isolated booking checks, including updated public metadata, nonconsecutive-stay rejection, ownership, capacity, duplicate request handling and expired holds. PHP syntax passes. The 13 production guard checks pass after the availability response change.

Final OPPO verification covered the two-column Explore layout, AirStay detail spacing, notification empty state, wallet instruction/amount spacing, branded profile/plans entry and fresh Google sign-in. The daily streak disappeared after its display window. No real payment was initiated during these visual checks. The normal Gradle Android profile pipeline and ARM64 split build now pass with the standard dependency repositories. Earlier failures involved a temporary offline dependency setup. Hard-coded Android versions were replaced with Flutter version properties; the source version is 2.0.7+2017. The ARM64 split package reports versionName 2.0.7 and versionCode 4017 because the ABI split adds its code offset. Its development signing certificate matches the existing installed app. This remains a profile test artifact; clean release CI, release signing and iPhone coverage are still required.

## Current launch gates

The production probe finds zero approved published places, upcoming real events, published paid content, enabled coin packs or active legal pages. Six gifts and Free/Gold/Pro exist; UGX/USD are supported. Live and RevenueCat availability remain disabled. These are honest availability gates, not claims that empty modules are market-ready.

Admin must review/publish legal drafts, approve genuine listings and event fulfillment, configure coin pricing and creator shares, and supply supported payment/store/live configuration where enabled. Verified real payments, reversals, settlement/reconciliation and payout execution still require provider acceptance. A clean store release and physical iPhone coverage remain engineering/release work.

The previously provisioned QA account retains 970 non-cash test coins. Fresh Google sign-in restored the existing Kasanyu Tom QA profile, whose wallet correctly shows zero coins and UGX 0; these are separate accounts. Google accounts are resolved by verified Firebase subject, not by the placeholder email field. No additional cash, paid backing, payout or real booking was fabricated in this pass.

## Coin clarity

The proposed 1 paid coin = UGX 1 rule has not silently repriced existing balances or gifts. Admin-controlled packs and gift values remain unchanged. A consistent future UGX pack rule, reviewed existing-value conversion and clear paid/promotional balance separation are required before advertising parity. Creator cash remains the configured share of eligible paid value, not the entire wallet balance. USD conversion cannot be invented.

## Reusable checker

`backend/scripts/fasttrack_quality_check.sh` runs the six isolated backend suites and stops on failure. Set `KETUA_PHP` to the PHP 8.2 executable on the test host. Each suite refuses any database other than `ketua_test`; fixtures roll back. The Flutter suite is `flutter test --no-pub` in the reviewed app checkout. These are bounded regression checks, not substitutes for release/device/provider acceptance.

## Operations measurement

The shared VPS filesystem is 93% used with about 28 GB free. No unrelated files were deleted. Capacity monitoring and headroom for public media growth should be included in launch operations.

## Shareable Android test build

[Download KETUA 2.0.7 ARM64 APK](https://ketua.sanaa.co/downloads/ketua-2.0.7-c5429206b847828d43a0dfea/KETUA-2.0.7-android-arm64.apk)

Size: 173,244,537 bytes (about 173 MB). Package: `com.sanyu.ketua`; native version 2.0.7 / 4017. This is a development-signed profile build for direct installation on compatible ARM64 Android devices (Android 7/API 24 or later), not a signed store release. Installing over a differently signed build may fail; preserve user data before any uninstall.

SHA-256: `38484ec6312cd52bd09377cd5379797f0210439a1bc949a07089776397a5d1d5`. HTTPS responds 200 with the correct file size and supports ranged downloads. A complete public download was hashed and matches the installed artifact. The URL intentionally exposes only this APK; no credentials, QA manifests or source were published.
