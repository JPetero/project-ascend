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
| 1 | No real Android upload keystore | IN PROGRESS | S13 Part 16-27 wired the signing mechanism (`android/key.properties`-driven); S14 Part 1 made the `prod` flavor hard-fail its release/bundle build rather than silently falling back to debug signing, so this gap can no longer produce a mislabeled "prod" artifact — but a real upload keystore still needs to be generated and provided (locally or via `ASCEND_KEYSTORE_BASE64`+friends in CI, see `founder-setup-checklist.md`) before any `prod` build succeeds at all. |
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
| 13 | Android CI build artifact never exercised in a live GitHub Actions run | IN PROGRESS | S14 Part 3 redesigned `.github/workflows/mobile.yml` into three honestly-labeled jobs (`analyze-test`, `staging-or-dev-build`, guarded `production-build`) following standard, documented `flutter build`/Gradle patterns, but real execution status depends on whether this session could observe an actual run — see `build-session-14.md`'s CI section for the exact outcome, `VERIFIED` or `NOT_RUN`/`BLOCKED`. |

## Beta feature profile

`beta/beta-feature-profile.md` (S14 Part 34-35) defines exactly what
should be ON/conditional/OFF for the first internal beta and documents
the demo-data audit (conclusion: nothing to remove — `prisma/seed.ts` is
already reference-data-only). Not itself a blocker; referenced here so
it's discoverable alongside the rest of the beta-readiness docs.

## Not a blocker (explicitly, so it isn't re-litigated)

- **Backend test coverage**: extensive (1000+ unit tests, 300+ e2e tests, all passing against a real Postgres instance) — this is the one layer that has been thoroughly, repeatedly verified in this sandbox.
- **Mobile test coverage**: extensive (800+ widget/unit tests) — same caveat as above; these exercise app logic, never real device APIs.
