# Beta Blocker Tracker

S13 Part 16-27. A single, honest list of everything standing between this
codebase and a real beta release — consolidated from disclosed
limitations scattered across `build-session-*.md`, `qa/*.md`, and
in-code doc comments, so there's one place to check status instead of
grepping for "not exercised in this environment." Every row here is a
genuine gap, not a hedge — nothing is listed "just in case."

Update this file as items close. When every row is CLOSED, the app is
ready for a real beta candidate build; it is not there yet.

## Status vocabulary

- `OPEN` — genuinely blocking, not started.
- `IN PROGRESS` — mechanism exists, not yet exercised for real.
- `CLOSED` — verified working with real credentials/hardware/accounts.

## Credentials & third-party accounts (Founder action — see `founder-setup-checklist.md`)

| # | Blocker | Status | Why it blocks beta |
|---|---|---|---|
| 1 | No real Android upload keystore | IN PROGRESS | S13 Part 16-27 wired the signing mechanism (`android/key.properties`-driven), but every build today — including the CI artifact — still falls back to debug signing. A debug-signed build cannot be uploaded to the Play Store. |
| 2 | No Apple Developer Program membership | OPEN | Blocks iOS TestFlight/App Store distribution entirely, and blocks real APNs push delivery (`UIBackgroundModes: remote-notification` in `Info.plist` has nothing to receive from without it) — see `build-session-11.md`. |
| 3 | No Firebase project configured | OPEN | `FCM_SERVICE_ACCOUNT_JSON`/`FCM_PROJECT_ID` unset — remote push notifications have never been exercised against a real device, only the local-notification/deep-link plumbing around them. |
| 4 | No Google/Apple OAuth clients | OPEN | Social sign-in buttons render but fail honestly (`GoogleAuthProvider`/Apple equivalent throw "not configured" rather than pretending to work) — email/password is the only auth path that's been exercised end-to-end. |
| 5 | No live AI provider key (Anthropic/OpenAI/Gemini) | OPEN | Atlas/Nova companion chat and Research mode's grounded-synthesis path (S13 Part 10-12) have never made a real model call — every AI-dependent test in this repo runs against the honest "not configured" 503 path, not a live response. |
| 6 | No Apple/Google IAP secrets | OPEN | Purchase verification (`APPLE_IAP_SHARED_SECRET`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`) has never verified a real receipt — the paywall UI and entitlement-gating logic are tested, the actual store round-trip is not. |
| 7 | No Brave Search API key | OPEN | Research mode's retrieval pipeline has only ever run against the deterministic `NoopResearchProvider`, never real search results. |

## Infrastructure & environments

| # | Blocker | Status | Why it blocks beta |
|---|---|---|---|
| 8 | No staging environment provisioned | OPEN | `staging-deployment.md` (S13 Part 16-27) documents the real procedure, but no staging host/database/DNS exists yet to follow it against. |
| 9 | No production environment provisioned | OPEN | Same gap, one tier up — `GET /admin/release-readiness`'s `security.productionSafe` has never been checked against a real `NODE_ENV=production` deploy. |
| 10 | Backup/restore not wired into a scheduled job | IN PROGRESS | `backup-and-restore-runbook.md`: the underlying `pg_dump`/`pg_restore` commands were verified directly against local Postgres, but no cron/managed-snapshot schedule exists anywhere yet. |

## Hardware & manual QA (needs physical devices)

| # | Blocker | Status | Why it blocks beta |
|---|---|---|---|
| 11 | Full device/OS QA matrix never run | OPEN | Every row in `qa/release-device-matrix.md` is `NOT_RUN` — this sandbox has no Android SDK, no Xcode, no physical or virtual device. |
| 12 | Vision camera pipeline never run on real hardware | OPEN | `qa/vision-physical-device-checklist.md` — pose detection, rep counting, and the new front/rear camera switching/position guidance (S13 Part 13-15) are unit- and widget-tested with synthetic frames only, never against a live camera feed. |
| 13 | Android CI build artifact never exercised in a live GitHub Actions run | IN PROGRESS | The `.github/workflows/mobile.yml` `android-build` job (S13 Part 16-27) follows the standard, documented `flutter build apk` pattern, but this session has no way to trigger and observe an actual Actions run — first real push to `main`/a PR will be the first live signal. |

## Not a blocker (explicitly, so it isn't re-litigated)

- **Backend test coverage**: extensive (1000+ unit tests, 300+ e2e tests, all passing against a real Postgres instance) — this is the one layer that has been thoroughly, repeatedly verified in this sandbox.
- **Mobile test coverage**: extensive (800+ widget/unit tests) — same caveat as above; these exercise app logic, never real device APIs.
