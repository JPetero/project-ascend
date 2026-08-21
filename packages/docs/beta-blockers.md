# Beta Blocker Tracker

S13 Part 16-27. A single, honest list of everything standing between this
codebase and a real beta release — consolidated from disclosed
limitations scattered across `build-session-*.md`, `qa/*.md`, and
in-code doc comments, so there's one place to check status instead of
grepping for "not exercised in this environment." Every row here is a
genuine gap, not a hedge — nothing is listed "just in case."

Update this file as items close. When every row is CLOSED, the app is
ready for a real *public* release; it is not there yet.

## Status vocabulary

- `OPEN` — genuinely blocking, not started.
- `IN PROGRESS` — mechanism exists, not yet exercised for real.
- `CLOSED` — verified working with real credentials/hardware/accounts.

## Stage vocabulary (S15 Part 26)

Every row below is also tagged with the earliest release stage it
actually blocks, per [beta/release-stages.md](beta/release-stages.md).
This matters: treating this file as one flat list made every row look
like it blocked *everything*, which is why "get Ascend onto a phone"
looked like it needed an Apple Developer account. It does not.

- **Stage A** — install-only Android smoke test.
- **Stage B** — connected Android internal beta (real backend, real HTTPS).
- **Stage C** — Google Play internal test track.
- **Stage D** — iOS TestFlight.
- **Stage E** — public release.

**Nothing in this file blocks Stage A.** Stage A is reachable today.

## Credentials & third-party accounts (Founder action — see `founder-setup-checklist.md`)

| # | Blocker | Status | Blocks from | Why it blocks |
|---|---|---|---|---|
| 1 | No real Android upload keystore | IN PROGRESS | **Stage C** | S13 Part 16-27 wired the signing mechanism (`android/key.properties`-driven); S14 Part 1 made the `prod` flavor hard-fail its release/bundle build rather than silently falling back to debug signing, so this gap can no longer produce a mislabeled "prod" artifact — but a real upload keystore still needs to be generated and provided (locally or via `ASCEND_KEYSTORE_BASE64`+friends in CI, see `founder-setup-checklist.md`) before any `prod` build succeeds at all. Stages A and B sideload an unsigned-for-store APK and are unaffected. |
| 2 | No Apple Developer Program membership | OPEN | **Stage D** | Blocks iOS TestFlight/App Store distribution entirely, and blocks real APNs push delivery (`UIBackgroundModes: remote-notification` in `Info.plist` has nothing to receive from without it) — see `build-session-11.md`. Irrelevant to the Android-only Stages A–C. |
| 3 | No Firebase project configured | OPEN | **Stage E** | `FCM_SERVICE_ACCOUNT_JSON`/`FCM_PROJECT_ID` unset — remote push notifications have never been exercised against a real device, only the local-notification/deep-link plumbing around them. `REMOTE_PUSH` stays off through Stage B by design; local notifications and in-app notification history work without it. |
| 4 | No Google/Apple OAuth clients | OPEN | **Stage E** | Social sign-in buttons render but fail honestly (`GoogleAuthProvider`/Apple equivalent throw "not configured" rather than pretending to work) — email/password is the only auth path that's been exercised end-to-end, and it is a fully functional one. `GOOGLE_SIGN_IN` stays off through Stage B by design. (Apple Sign In specifically becomes a **Stage D** requirement: Apple mandates it for any app offering third-party social login.) |
| 5 | No live AI provider key (Anthropic/OpenAI/Gemini) | OPEN | **Stage E** | Atlas/Nova companion chat and Research mode's grounded-synthesis path (S13 Part 10-12) have never made a real model call — every AI-dependent test in this repo runs against the honest "not configured" 503 path, not a live response. `LIVE_AI` stays off through Stage B; the free deterministic companion path works without it. |
| 6 | No Apple/Google IAP secrets | OPEN | **Stage E** | Purchase verification (`APPLE_IAP_SHARED_SECRET`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`) has never verified a real receipt — the paywall UI and entitlement-gating logic are tested, the actual store round-trip is not. `STORE_PURCHASES` is off for the entire initial beta regardless of whether these are configured. |
| 7 | No Brave Search API key | OPEN | **Stage E** | Research mode's retrieval pipeline has only ever run against the deterministic `NoopResearchProvider`, never real search results. `RESEARCH_MODE` stays off through Stage B. |

## Infrastructure & environments

| # | Blocker | Status | Blocks from | Why it blocks |
|---|---|---|---|---|
| 8 | No staging environment provisioned | OPEN | **Stage B** | `staging-deployment.md` (S13 Part 16-27, corrected in S15 Part 1) documents the real procedure, but no staging host/database/DNS/TLS certificate exists yet to follow it against. **This is the single blocker standing between the project and Stage B** — every code, CI, and config task Stage B needs is complete. See `beta/connected-beta-setup.md`. |
| 9 | No production environment provisioned | OPEN | **Stage C** | Same gap, one tier up — `GET /admin/release-readiness`'s `security.productionSafe` has never been checked against a real `ASCEND_ENV=production` deploy. Stage B uses staging, not production, so this does not block it. |
| 10 | Backup/restore not wired into a scheduled job | IN PROGRESS | **Stage E** | `backup-and-restore-runbook.md`: the underlying `pg_dump`/`pg_restore` commands were verified directly against local Postgres, but no cron/managed-snapshot schedule exists anywhere yet. Staging data is explicitly disposable (see `release/staging-data-policy.md`), so this does not block Stage B. |

## Hardware & manual QA (needs physical devices)

| # | Blocker | Status | Blocks from | Why it blocks |
|---|---|---|---|---|
| 11 | Full device/OS QA matrix never run | OPEN | **Stage E** | Every row in `qa/release-device-matrix.md` is `NOT_RUN` — this sandbox has no Android SDK, no Xcode, no physical or virtual device. Stages A and B are themselves the first real-device passes, and `beta/first-connected-beta-test-plan.md` is the Stage B subset of this matrix. |
| 12 | Vision camera pipeline never run on real hardware | OPEN | **Stage E** | `qa/vision-physical-device-checklist.md` — pose detection, rep counting, and the new front/rear camera switching/position guidance (S13 Part 13-15) are unit- and widget-tested with synthetic frames only, never against a live camera feed. `VISION_FORM_COACH` stays off through Stage B, so this blocks neither A nor B. |
| 13 | Android CI build artifact never exercised in a live GitHub Actions run | CLOSED | — | S14 Part 4 directly observed a real, finished GitHub Actions run (workflow run `31529452669` on `main`, commit `37ea48e1`) via `mcp__github__actions_list`/`get_job_logs` — `analyze-test` succeeded, `production-build` correctly skipped (no signing secrets configured), and `staging-or-dev-build` genuinely built and uploaded a real "development-sideload" APK. Two real bugs (core-library-desugaring, `minSdk` conflicting with the `health` plugin's manifest) and one real Backend CI bug (a pre-existing Prisma-format drift) were found and fixed only because this observation was real, not assumed. This closes the CI-artifact gap specifically; it does not close #11/#12 above, which still need an actual physical device. |

## Beta feature profile

`beta/beta-feature-profile.md` (S14 Part 34-35) defines exactly what
should be ON/conditional/OFF for the first internal beta and documents
the demo-data audit (conclusion: nothing to remove — `prisma/seed.ts` is
already reference-data-only). Not itself a blocker; referenced here so
it's discoverable alongside the rest of the beta-readiness docs.

## What the stage tags above actually mean for "when can I test this?"

Reading the `Blocks from` column top to bottom:

- **Stage A is blocked by nothing in this file.** An APK from the latest
  green `Mobile CI` run installs on any Android 8.0+ phone today.
- **Stage B is blocked by exactly one row — #8.** A staging host, a
  database, a domain, and a TLS certificate. Everything else in this
  file is Stage C or later. Once #8 closes, Ascend is a working,
  connected app on a real phone.
- Rows #1 and #9 gate Stage C; #2 gates Stage D; the rest gate Stage E.

This is the practical payoff of S15 Part 5's staging split: the distance
to a genuinely useful beta is one infrastructure task, not thirteen.

## Not a blocker (explicitly, so it isn't re-litigated)

- **Backend test coverage**: extensive (1000+ unit tests, 300+ e2e tests, all passing against a real Postgres instance) — this is the one layer that has been thoroughly, repeatedly verified in this sandbox.
- **Mobile test coverage**: extensive (800+ widget/unit tests) — same caveat as above; these exercise app logic, never real device APIs.
