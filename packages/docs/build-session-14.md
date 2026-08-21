# Build Session 14 — First Real Beta Candidate, Release Correctness, Device QA Preparation, Operational Hardening

Starting HEAD: `9326055` (Merge Session 13 final: build-session-13.md
structured report) on `main`. Work branch: `claude/session-14-first-beta`.

Status vocabulary used throughout, matching every prior session's
convention: **IMPLEMENTED** (code written), **VERIFIED** (implemented and
confirmed via an automated test or a directly-observed real system, not
assumed), **PARTIAL** (some but not all of a Part is done), **BLOCKED**
(cannot proceed without an external credential/device/service this
environment doesn't have), **NOT_RUN** (a check that exists but was
never executed).

## Summary

Every Part below was individually: implemented → tested (backend
unit+e2e, mobile analyze+format+test, admin lint+test+build where
touched) → committed → pushed to the feature branch → merged `--no-ff`
into `main` → **re-verified in full on the merged `main`** → pushed to
`main` → fast-forwarded back onto the feature branch. No step was
skipped for any merged part; the merge history on `main` (17 individual
merge commits, `9326055..eda120a`) is the audit trail.

The defining constraint of this session, stated explicitly in the
governing directive, was **never fabricate verification**. Two Parts
exist specifically because of that constraint and are worth calling out
before the part-by-part log: Part 4 (below) is a live GitHub Actions
observation, not a YAML read-through, and it found three real bugs no
static review would have caught. Part 12 found and fixed a real
production bug — a fabricated fallback domain baked into password-reset
emails — by reading the actual code path rather than trusting its own
doc comments.

## Part 1/2/3/5 — Android release signing safety, mobile API URL validation, honest CI redesign, sideload doc

**Status: IMPLEMENTED, VERIFIED** (commit `645b576`, merged in `a831d9c`).

Four release-correctness fixes landed together as one P0 commit:

- `android/app/build.gradle.kts`: `assembleProdRelease`/`bundleProdRelease`
  now hard-fail when no real release signing is configured (via
  `key.properties` or `ASCEND_KEYSTORE_PATH`/`PASSWORD`/`ALIAS`/
  `KEY_PASSWORD` env vars), instead of silently falling back to debug
  signing. `dev`/`staging` keep the debug-signing fallback, which is
  correct for local/internal-test builds.
- `AppConfigValidation` (mobile): rejects a `staging`/`prod` build with a
  missing, non-`https`, or local-only (`localhost`/`127.0.0.1`/`10.0.2.2`)
  `API_BASE_URL`. `main()` checks this before touching the network or
  storage and shows a blocking `ConfigurationErrorApp` instead of quietly
  starting against an unsafe host.
- `.github/workflows/mobile.yml`: replaced a single mislabeled
  "ascend-prod-release-apk" job (debug-signed, no real production API
  URL) with three honestly-labeled jobs — `analyze-test`,
  `staging-or-dev-build` (a real staging build when
  `STAGING_API_BASE_URL` is configured, otherwise an explicitly-labeled
  dev-flavor sideload build), and a guarded `production-build` that only
  runs on `main` once real signing + `PROD_API_BASE_URL` secrets exist.
- New `packages/docs/beta/android-sideload-beta.md` — Founder-friendly
  steps to get a build from GitHub Actions onto a real phone.

## Part 4 — Real GitHub Actions verification (live, not assumed)

**Status: VERIFIED** — the one Part in this session confirmed by directly
observing external system state, not by reading a workflow file.

Used `mcp__github__actions_list`/`actions_get`/`get_job_logs` across
several real, finished workflow runs on `main` and found three genuine
bugs no local sandbox check could have caught (this environment has no
Android SDK and no live CI runner):

1. **`checkDevReleaseAarMetadata` failure** — `flutter_local_notifications`
   requires core library desugaring, not enabled by default. Fixed with
   `compileOptions.isCoreLibraryDesugaringEnabled = true` paired with
   `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`
   (commit `7050907`) — confirmed via a real run that one without the
   other still fails.
2. **Manifest merge failure** — `uses-sdk:minSdkVersion 24 cannot be
   smaller than version 26 declared in library [:health]`. The `health`
   plugin (Health Connect/HealthKit) declares its own manifest
   `minSdkVersion 26`; the app's `minSdk` was overridden from Flutter's
   lower template default to `26` explicitly (commit `da0c1a9`) —
   `qa/release-device-matrix.md` had already anticipated this exact
   value, now confirmed correct.
3. **Backend CI "Check Prisma schema formatting" failing on multiple
   consecutive commits** — a long-standing, pre-existing whitespace/
   column-alignment drift in `schema.prisma`, unrelated to this
   session's own changes, discovered by reading real failed job logs.
   Fixed by running `npx prisma format` and committing the resulting
   76-line whitespace-only diff (commit `d3f4141`, verified whitespace-
   only via a normalize-and-collapse diff check).

Also fixed along the way: an invalid job-level `secrets:` reference that
was rejecting the whole workflow file outright (commit `cb3a11b`), and
guarded `production-build`'s cleanup step on secret presence so it
doesn't fail when the job is legitimately skipped (commit `a237a38`).

**Final confirmation**: workflow run `31529452669` on `main`, commit
`37ea48e1` — `analyze-test` succeeded, `production-build` correctly
skipped (no signing secrets configured, not a failure), and
`staging-or-dev-build` genuinely built and uploaded a real
"development-sideload" APK artifact. `beta-blockers.md` row 13 (Android
CI build artifact never exercised in a live GitHub Actions run) is now
**CLOSED** on the strength of this observation.

## Part 6 — Split `/livez` and `/readyz` health endpoints

**Status: IMPLEMENTED, VERIFIED** (commit `9792555`, merged in `9b74c8a`).

`/livez` (process alive, no database check) and `/readyz` (database-
aware) are now distinct endpoints — a Kubernetes-style liveness probe
that conflates the two causes restart storms during a transient database
blip. `/health` remains as an alias of `/readyz` for anything already
pointed at it. `infrastructure/docker/api.Dockerfile`'s `HEALTHCHECK`
uses `/readyz` deliberately (a single container with no separate
readiness gate genuinely wants Docker to restart it if the database
becomes unreachable).

## Part 8 — Dedicated opt-in `reEngagementReminders` preference

**Status: IMPLEMENTED, VERIFIED** (commit `b30acbe`, merged in `84e32a2`;
migration `20260811185814_add_re_engagement_reminders_preference`).

Retention win-back notifications previously piggybacked on the general
`socialNotifications` preference — a user who wanted friend/community
notifications but not marketing-style win-back nudges had no way to
separate the two. Added a dedicated, explicitly opt-**in**
`reEngagementReminders` column and wired it through the
notification-preferences API and mobile UI.

*(S15 Part 6 — corrected a typo in this paragraph, which previously read
"defaulted-`true`". The column's actual default is `false`, as an
opt-in preference must be: see `schema.prisma`'s
`reEngagementReminders Boolean @default(false)`, migration
`20260811185814_add_re_engagement_reminders_preference`, and the
`notifications.e2e-spec.ts` assertion that a fresh user reads back
`false`. Only the sentence was wrong — the schema and behavior were
always correct, and nothing about them was changed.)*

## Part 9 — Retention job single-execution safety + query scaling

**Status: IMPLEMENTED, VERIFIED** (commit `73f6da7`, merged in `44c5782`;
migration `20260811191717_retention_job_lock_and_refresh_token_index`).

Build Session 13's disclosed gap — "a real production deployment needs
to confirm exactly one instance of the API process runs the schedule…
once horizontal scaling is in play" — is now closed. New shared
`SchedulerLockService` (`services/api/src/common/scheduling/`)
implements a lease-based cross-instance lock via a `ScheduledJobLock`
table and an atomic `INSERT … ON CONFLICT … WHERE lockedUntil < now`
claim — deliberately not a session-pinned Postgres advisory lock, since
that would need every acquire/release pair to share one specific pooled
connection, which Prisma's pooled query interface doesn't guarantee.
`RetentionService` now delegates to it via `runExclusive('retention-win-back', …)`
instead of its own inline lock. Also added `@@index([userId, createdAt])`
on `RefreshToken`, the column the retention job's `groupBy` scans.

## Part 10-11 — Media cleanup + expired security-token cleanup jobs

**Status: IMPLEMENTED, VERIFIED** (commit `0133be8`, merged in `a458b26`).

Two new scheduled jobs, both dryRun-capable and both using the new
`SchedulerLockService`:

- `MediaCleanupService` — four independent categories: abandoned
  uploads (24h grace), orphaned media with zero `MediaUsage` rows (48h
  grace — relies on `MediaService.attachUsage` being the one place every
  consumer records "this asset is in use," confirmed by tracing every
  call site), deleted-tombstone rows past their retention window (30
  days — storage is already gone by then), and account-deletion media
  (30 days). `purgeAsset` deletes storage then hard-deletes the row;
  Prisma cascades handle the rest.
- `SecurityTokenCleanupService` — prunes expired
  `PasswordResetToken`/`EmailVerificationToken` (7-day grace),
  `RefreshToken` (30-day grace — confirmed safe regardless of
  `revokedAt`/`reusedAt` since `AuthService.refresh` checks expiry before
  reaching reuse-detection logic), and stale `PushDeviceToken` (90-day
  grace based on `lastSeenAt`).

## Part 7 — Release Readiness V3

**Status: IMPLEMENTED, VERIFIED** (commit `e4c72df`, merged in `f11d27c`).

Additive `items: ReadinessItem[]` array alongside the unchanged legacy
`security`/`integrations`/`migrations`/`featureFlags` fields. New
`ReadinessStatus` enum (`READY, CODE_READY, CONFIG_REQUIRED,
CREDENTIALS_REQUIRED, STORE_SETUP_REQUIRED, DEVICE_QA_REQUIRED, BLOCKED,
DISABLED, ERROR`) covers 19 items — signing, API URLs, every third-party
integration (flag-gated via the feature-flag registry), Play
Billing/StoreKit (capped at `STORE_SETUP_REQUIRED`, never `READY`, since
manual sandbox QA can't be confirmed from a backend service), and Vision/
Health Connect/HealthKit device QA (hardcoded `DEVICE_QA_REQUIRED`, never
inferred from a test pass). The admin `ReleaseReadinessPage` renders
these grouped by category with a status-symbol legend, additive above
the pre-existing sections.

## Part 34-35 — Beta feature profile + demo-data audit

**Status: IMPLEMENTED, VERIFIED** (commit `0bb0be2`, merged in `7414c9f`).

New `services/api/prisma/seed-beta-feature-flags.ts` — a standalone
script (outside Nest DI, like `seed.ts`) that upserts explicit
`FeatureFlag` overrides for the first internal Android beta:
`GOOGLE_SIGN_IN`, `REMOTE_PUSH`, `VISION_FORM_COACH`, `LIVE_AI`,
`RESEARCH_MODE` off until their dependency is configured; `STORE_PURCHASES`
and `ASCEND_PROMOTE` off for the entire initial beta regardless of
configuration. Refuses to run against `NODE_ENV=production`; never edits
the registry file, only ever the database `DATABASE_URL` points at.
Manually verified against the local dev database (production guard
throws correctly; upserts all 7 rows; cleaned up afterward with zero
pollution to the e2e suite). `packages/docs/beta/beta-feature-profile.md`
documents the full ON/conditional/OFF table plus the demo-data audit
conclusion: `prisma/seed.ts` creates zero `User`/`CommunityPost`/
`DirectMessage` rows anywhere — nothing to remove.

## Part 19 — Vision release diagnostics screen

**Status: IMPLEMENTED, VERIFIED** (commit `28311c9`, merged in `b28ac51`).

A QA tool, not a user-facing feature — reachable via a bug-report icon
in the app bar of any Vision mode with live camera analysis. Surfaces
device/build identity (`package_info_plus`/`device_info_plus`, both
promoted from transitive to direct deps) and camera hardware, plus a
one-tap self-test that opens the real camera, captures one frame, and
runs it through the real on-device ML Kit pose detector — the single
most useful release-readiness signal Vision has, since a passing unit/
widget suite says nothing about whether ML Kit's model actually loads on
a given device. Required adding an optional `error` field to
`PoseDetectorResult` so the self-test can tell "nobody in frame" apart
from "the detector itself failed"; every existing caller
(`LiveVisionSessionController`) ignores the new field, so rep-counting
behavior is unchanged. Every platform touchpoint is injected behind an
interface (mirroring `PoseDetectorAdapter`'s existing seam), so the
controller is fully unit-testable against fakes. Links from
`qa/vision-physical-device-checklist.md`.

## Part 28-29 — Admin deployment security + Docker hardening

**Status: IMPLEMENTED, VERIFIED** (commit `17b9c8f`, merged in `63b9ea8`).

Closes a gap Build Session 13's own report disclosed and carried
forward: *"The admin app has no deployment or security-header story at
all."* It does now:

- `apiConfigValidation.ts` mirrors the mobile app's `AppConfigValidation`
  (Part 2) — a production `vite build` refuses to render the real app if
  `VITE_API_BASE_URL` is unset, non-`https`, or points at `localhost`,
  showing `ConfigurationErrorScreen` instead. CI's build step now passes
  a placeholder so the pipeline keeps working (not a real deployment
  target).
- `infrastructure/docker/admin.Dockerfile` + `nginx-admin.conf` — a
  multi-stage build (Vite build → `nginxinc/nginx-unprivileged` runtime,
  matching `api.Dockerfile`'s non-root pattern) with `X-Frame-Options`,
  `X-Content-Type-Options`, `Referrer-Policy`, `X-Robots-Tag`,
  `Permissions-Policy`, and a `Content-Security-Policy`.
- `robots.txt` + `<meta name="robots">` — never crawled/indexed.
- Root `.dockerignore` — every Dockerfile builds with the repo root as
  context; without this it included `.git`, every workspace's
  `node_modules`, and any local `.env` file.
- `docker-compose.yml`'s `api`/`migrate` services gained
  `cap_drop: ["ALL"]`/`no-new-privileges:true` — safe specifically
  because both are non-root Node processes needing zero Linux
  capabilities. Deliberately **not** applied to `postgres`/`pgadmin`,
  whose entrypoints need real capabilities on first boot, with no Docker
  daemon in this sandbox to verify a change there is safe.
- `packages/docs/admin-deployment.md` documents all of the above,
  states plainly that none of it was build-verified with a real
  `docker build` (no privileged Docker daemon available here), and
  covers the network-level access restriction (VPN/IP allowlist/SSO) an
  admin panel needs beyond RBAC.

## Part 12 — Strengthen backend production config validation

**Status: IMPLEMENTED, VERIFIED** (commit `8a3ce2c`, merged in `8b0b2b8`).

`validateEnv` already refused to boot in production with dev JWT secrets
or a wildcard `CORS_ORIGIN` (Build Session 10). Closed real gaps that
check didn't cover:

- JWT secrets under 32 characters now hard-fail production boot — the
  `dev_`-prefix check only caught the specific placeholder values
  `docker-compose.yml`/`.env.example` ship, not every weak secret an
  operator could type in their place.
- Identical access/refresh secrets now hard-fail production boot — a
  leaked access-token secret must never also compromise refresh tokens.
- `DATABASE_URL` pointed at `localhost`/`127.0.0.1`/`0.0.0.0` now
  hard-fails production boot, mirroring mobile's `AppConfigValidation`
  unsafe-hosts check.
- **`APP_PUBLIC_URL`** — `configuration.ts` used to default this to a
  fabricated `https://app.projectascend.com` domain that isn't real
  infrastructure. An operator who forgot to set it would silently ship
  password-reset/email-verification links pointing at a domain nobody
  owns — exactly the "pretend it works" failure mode this session avoids
  elsewhere. Now defaults to `''`; `validateEnv` hard-requires a real,
  `https`, non-local value in production.

**Mobile side (Part 13)** was investigated for an equivalent gap and
found already substantively complete via Part 2:
`AppConfigValidation` validates `API_BASE_URL` for staging/prod,
`main.dart` runs it before any network/storage code executes, and a grep
for hardcoded `https://` literals across `apps/mobile/lib` found no call
site that bypasses `ApiClient`/`AppConfig.apiBaseUrl`. Nothing further
added rather than manufacturing busywork.

## Repository-doc polish

**Status: IMPLEMENTED** (commit `3f43af9`).

`beta-blockers.md` row 13 and `qa/release-device-matrix.md` row 1 still
reflected pre-Part-4 uncertainty about whether the Android CI build had
actually run live. Updated both to cite the real, directly-observed
GitHub Actions run once Part 4 confirmed it, rather than leaving a
stale "depends on whether this session could observe a run" hedge in
place after it had already been observed.

An exhaustive TODO/FIXME/skipped-test/eslint-disable sweep across
`services/api/src`, `apps/mobile/lib`, and `apps/admin/src` this session
found nothing — the codebase came into this session already clean from
prior audit passes (Build Session 12 Part 27-32's TODO audit, this
session's own new code held to the same standard).

## Migrations (this session, chronological)

1. `20260811185814_add_re_engagement_reminders_preference` (Part 8)
2. `20260811191717_retention_job_lock_and_refresh_token_index` (Part 9)

## New dependencies

- `package_info_plus: ^9.0.1`, `device_info_plus: ^12.4.0` (mobile, Part
  19) — both already present as transitive dependencies of existing
  plugins; promoted to direct since `core/diagnostics` now imports them
  directly.

No new backend or admin dependencies this session.

## Test results (final, on merged `main`, commit `eda120a`)

- Backend unit: **1191 passed**, 82 suites (1138 at session start — +53).
- Backend e2e: **375 passed**, 41 suites (371 at session start — +4).
- Backend lint (`eslint --max-warnings=0`): clean.
- Backend build (`nest build`): clean.
- Mobile `flutter analyze`: clean, 0 issues.
- Mobile `dart format --set-exit-if-changed`: clean, 0 files changed.
- Mobile `flutter test`: **916 passed** (889 at session start — +27).
- Admin `tsc --noEmit`: clean.
- Admin `eslint`: clean (one pre-existing
  `react-refresh/only-export-components` warning in `AuthContext.tsx`,
  unchanged from Build Session 13, unrelated to this session — not a
  regression).
- Admin `vitest`: **50 passed**, 14 files (39 at session start — +11).
- Admin `tsc --noEmit && vite build`: clean.

Every number above was observed directly from command output during
this session's final verification pass, run against the actual merged
`main` commit — not carried forward from an earlier, now-stale run.

## Android CI build status

**VERIFIED via a real, directly-observed GitHub Actions run** — see Part
4 above. This is the first session where that sentence is true rather
than aspirational: `staging-or-dev-build` genuinely produced and
uploaded a real APK artifact from a live `mobile.yml` run
(`analyze-test`/`production-build` also both behaved correctly), not
inferred from reading the workflow YAML.

## Docker build status

**NOT_RUN.** No privileged Docker daemon is available in this sandbox
(`docker version` connects to the client but not a running daemon; no
`podman`/`buildah`/`nerdctl` alternative exists either). Both
`infrastructure/docker/api.Dockerfile` (pre-existing) and the new
`admin.Dockerfile` follow standard, well-established multi-stage
patterns, but neither has been confirmed with a real `docker build` in
this environment. `admin-deployment.md` says so explicitly.

## Physical-device tests

**NOT_RUN**, unchanged from every prior session. `qa/release-device-matrix.md`
and `qa/vision-physical-device-checklist.md` still have every hardware
row honestly `NOT_RUN` — this sandbox has no Android SDK, no Xcode, no
physical or virtual device. Part 19's new diagnostics self-test exists
specifically to make that eventual physical-device pass faster and more
informative once real hardware is available; it does not substitute
for it.

## External credentials still required

Unchanged from Build Session 13's list — none of this session's work
closed these gaps, and none of it depended on them. See
`founder-setup-checklist.md` (now 21 numbered items, up from 20 — Part
12 added a row for `APP_PUBLIC_URL`) for the exact env var, where to get
it, and which Release Readiness field turns green once it's done:

- A real Android upload keystore (signing mechanism now hard-fails
  without one, per Part 1 — it just can no longer silently produce a
  mislabeled artifact).
- A real Firebase project, Apple Developer Program team + APNs key, an
  Android SDK/Xcode/physical device.
- `BRAVE_SEARCH_API_KEY`, Google/Apple OAuth clients, a live AI provider
  key, Apple/Google IAP secrets.
- A staging/production environment actually provisioned (`staging-deployment.md`
  documents the procedure; nothing to run it against yet).
- A privileged Docker daemon, to actually build and run
  `admin.Dockerfile`/`api.Dockerfile` and verify the hardening in Part
  28-29 works as designed.

## Remaining beta/launch blockers

Carried forward, updated for what this session actually closed:

1. No live push delivery, Vision-on-camera, Android/iOS release build on
   real hardware, or any device-matrix row has ever been verified on
   physical hardware — unchanged from every prior session's disclosure.
   Part 19's diagnostics screen and Part 4's real CI verification narrow
   what's left to verify once hardware exists, but don't substitute for
   it.
2. Camera-assisted sport score suggestions remain deliberately deferred
   — unchanged from Build Session 12/13, no pose/ball-tracking
   infrastructure exists.
3. ~~The admin app has no deployment or security-header story at all~~
   — **closed this session, Part 28-29.**
4. No automated backup schedule is wired up anywhere (the runbook
   documents the procedure; scheduling it against a real production
   database remains deployment-specific) — unchanged.
5. `RetentionService`'s scheduled job now has cross-instance locking
   (Part 9), closing the specific gap Build Session 13 flagged, but the
   query shape has still not been load-tested at real user-base scale.
6. Docker images (both `api.Dockerfile` and the new `admin.Dockerfile`)
   have never been confirmed with a real `docker build` — this sandbox
   has no privileged Docker daemon. New this session, disclosed
   explicitly rather than assumed away.

None of the above are new regressions from this session's work — all are
either pre-existing, explicitly scoped out, or newly *disclosed* (not
introduced) by this session's own verification passes, and are carried
forward honestly rather than hidden.
