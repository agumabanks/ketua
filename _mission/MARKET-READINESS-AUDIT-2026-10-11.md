# KETUA market-readiness audit — 11 October 2026

**Decision: continue controlled device testing; do not launch paid public production yet.** The withdrawal implementation and targeted checks pass, but provider, inventory, policy and release requirements remain. This is an engineering readiness review, not security or compliance certification.

## Implemented and deployed in this round

- Earner application, admin approval/suspension, earnings summary and withdrawal request screens. Earnings are reserved atomically; rejected requests release the reservation. Payout details are encrypted and available only through the protected admin workflow. Approval and paid transitions have an audit history; recording payment requires a unique external reference. This records an externally performed payout—it does not send mobile money automatically.
- Gifts can earn cash using an **admin-configured creator share**. Paid-content sales have a separate admin share. Both rates remain unset and withdrawals disabled until admin makes those commercial decisions. A seven-day hold and explicit release protect the available balance.
- Only verified funded coin purchases create cash provenance. Sharing preserves funding; gifting consumes it once. Test/free coins and re-gifting cannot manufacture creator cash. Other coin spending consumes funding too. Frozen/refunded funding and banned/test accounts are excluded from release/payment.
- Disabled legacy client wallet adjustments, fabricated livestream earnings, arbitrary notification sending and public story deletion. Bound community comments, posts, likes, follows and saved profiles to the authenticated account. Private account lookup now returns the caller, regardless of submitted email. Public nested actors/profile lists use restricted fields; random discovery respects reciprocal blocks, adult age and premium incognito.
- Added persistent gift/earning/booking notifications, corrected gift recipient and comment-post links, secured token registration and cleared push tokens at logout. Fixed duplicate background alerts. Restored-session notification initialization and notification-open routing passed the final OPPO check: one background alert and tapping it opens the Updates page.
- Polished Earn, earnings, wallet and Explore/place screen padding, keyboard dismissal, earnings status wording and monetary formatting. Plans keep their action footer outside the scrolling benefit list. UGX/USD wallet displays now format major amounts rather than showing USD cents as dollars.

## Financial test account

The currently signed-in account (user 40) received **1,000 explicitly non-cash QA coins**, through an idempotent credit record. Native checks sent a 10-coin Rose and shared 20 coins with Amani • QA; **970 remain**. No cash balance, real payment, payout or verified badge was fabricated. The account is marked QA for financial safety; remove that designation only after discarding/reconciling its test value before any real earning use.

## Verification and evidence

Tests use the isolated `ketua_test` database and synthetic accounts, except the bounded production probes and explicitly authorized device test transactions. Successful fixture tests do not prove a real provider settlement or business fulfillment.

| Area | Passed | Coverage |
|---|---:|---|
| Earnings withdrawals | 23 | Approval gate, ownership, encryption, reservation, rejection, source freeze, paid-reference audit |
| Funded gifts | 14 | Provenance, net share, test/free exclusion, loop prevention, other spending |
| Withdrawal concurrency | 2 | Four workers: same-key retries and competing requests reserve once |
| Market guards | 13 | Unsafe legacy routes, auth/admin gates and financial restrictions |
| Community ownership | 11 | Forged actors, foreign deletion, post notification target, private account lookup, restricted follow response |
| Places/reservations | 22 | Listing approval, availability/quote, owner and customer access |
| Premium commerce | 38 | Price/entitlement, settlement validation, replay/refund restrictions |
| Premium concurrency | 2 | Four-worker financial operations |
| Chat/phone | 25 | Phone-first routing, message/gift retry, notification recipient |
| Social catalog | 21 | Discovery/content/catalog behavior |
| Native readiness | 20 | Config and app/backend integration guards |
| Media/profile editor/catalog admin | 12 / 19 / 6 | Restricted media, photo limits/editing, admin changes |
| Production probe | 13 | Real account auth/readers, empty inventory, unsafe operation rejection, secure settings |
| Flutter tests | 40 | UI and client behavior regression suite |

Firebase identity checks cover valid signatures and wrong project/issuer, expiry, future timestamps, invalid subject and tampering. PHP syntax checks passed. Flutter has zero analyzer errors, with **166 warning/info findings** remaining. The current Composer audit reports no advisories or abandoned packages; all three new production migrations are applied. Old static security checker scores are not used as launch evidence; some expectations predate the new disabled legacy operations.

Evidence is in `evidence/market-audit/` and the `market-*.png/.xml` files under `evidence/premium-commerce/`. Backend source/database rollback snapshots are in `/var/backups/ketua/codex-20261011-market/` on sanaa-vps. Local, reviewed server and production Flutter source are synchronized after final verification.

## Launch gates still open

1. **Configure commercial prices and rates:** production has Free/Gold/Pro, UGX/USD and six gifts, but zero enabled coin packs. Admin must set coin prices, creator shares and reviewed plan prices. Do not silently invent an exchange rate or cash conversion for legacy coin balances.
2. **Complete real payment operations:** verify an authorized Pesapal reload, settlement, duplicate callback, refund/reversal and reconciliation; establish manual payout verification and refund-after-payout handling. No real cash transaction was performed in this audit. Review digital-goods payment routes for the actual distribution and region: [Google Play Payments](https://support.google.com/googleplay/android-developer/answer/9858738) and [Apple payment guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase). Pesapal integration alone does not establish store acceptance.
3. **Publish real inventory and fulfillment:** production currently has zero approved published venues/stays, zero real upcoming events and zero published paid content. Synthetic booking tests cannot prove venue availability, ticket admission, cancellations or refunds. Earner applications/listing moderation need staffed operations.
4. **Review and publish legal pages:** zero active legal pages. Existing review drafts must receive real operator/contact, retention, processor and refund details. Do not publish placeholder promises. Safety/reporting/moderation and support must have operational owners.
5. **Configure live and store providers:** Agora/live availability is disabled; RevenueCat production webhook configuration is absent. Live broadcasts, store purchase/restore/renewal/expiry and creator subscriptions are not certified end to end.
6. **Phone ownership/recovery:** phone-first password authentication works, but phone numbers remain unverified; no Firebase SMS is used as requested. Ownership verification and recovery require a chosen backend-controlled verification method before claiming verified phone accounts.
7. **Produce a reproducible release:** current OPPO artifact is a profile test build compiled from the latest Dart code and packaged into the previously tested native shell. Clean Gradle dependency resolution, release signing/versioning, native Maps configuration and production ad setup remain. Its native manifest is **2.0.5 / code 15**; the Dart display defines are 2.0.6 / 2016. Earlier notes calling 2016 the native version are corrected here. This artifact must not be uploaded as a store release.
8. **Broaden device and UX verification:** no physical iPhone/APNs/store build was tested in this round. Complete larger text, low-memory, offline/reconnect, background/deep-link and sustained swipe performance checks. New module strings still need full French/Swahili translation. Zero analyzer errors or no observed overflow is not proof of flawless spacing on every screen.

Use [OWASP MASVS](https://mas.owasp.org/MASVS/) as a continuing mobile review checklist; these targeted regressions are not an independent penetration test. Money-loss protections now cover the specific exploitable paths and replay conditions identified here; remaining provider reconciliation and fulfillment gates must be closed before paid launch.

## Module coverage and remaining limits

| Module | What was checked | Still needed before public release |
|---|---|---|
| Authentication | Current Google-backed session, token isolation, signed Firebase identity regressions, phone-password flow guards | Fresh native Google and phone onboarding/recovery matrix across devices; phone ownership verification |
| Swipe, profiles, plans | Native navigation and plan scrolling, public profile fields, premium privacy/limits, editor regressions | Sustained release performance and large-text/offline tests; real paid entitlements |
| Chat, gifts, coins | Native Rose and coin transfer with persisted delivered messages, retry/ownership tests | Real funded reload-to-gift chain, extended media and multi-device delivery/reconnect testing |
| Explore stays/dating/spa | Approved-listing, quotes, reservations and owner access fixtures; native discovery | Real published places, availability/calendar and business acceptance/fulfillment |
| Events and paid content | Ticket/content commerce fixtures and production discovery readers | Real inventory, paid admission/content delivery, refund operational tests |
| Earnings | Withdrawal fixtures/concurrency and native empty-balance application page | Admin rates, approved real earners, externally verified payout and reconciliation |
| Notifications | Protected readers/token registration, persistent gift/booking/earning events, Android background alert | Killed-process and iOS/APNs/device preference matrix |
| Admin | Admin route guards, price/catalog/listing/earning controls and immutable payout history | Full browser workflow walkthrough, staffed moderation and operational procedures |

Existing synthetic account profile location is not evidence of an accurate fresh GPS reading. Real location permission, denied/approximate permission and fresh distance rendering must be included in the final device matrix.

Native OPPO spacing review covered Profile → Plans, Earn → Earnings, and the complete Gold benefit list. The last benefits, controls and Restore action remain reachable above the separate purchase footer. Process-scoped logs during this review recorded zero fatal/unhandled exceptions or RenderFlex overflows. This is bounded evidence from one screen size, not a claim about every page/device.

Final profile APK SHA256: `77db036988f577e12d1fd1898f7c05170fc5f515004527cc80077e30489e29c3`. It is the device-test artifact described above, not a release package.

Final installation succeeded without clearing the account. Native background notification delivery and tapping into the Personal updates list passed; the final test APK hash was checked locally against the signed server artifact. No real financial payment was made.
