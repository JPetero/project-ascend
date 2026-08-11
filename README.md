# Project Ascend

An AI-first fitness, nutrition, progress, social, and wellness app. This repository contains a
real, runnable monorepo with a NestJS backend and a Flutter mobile client.

- **Sprint 0 + Sprint 1** delivered the foundation and first vertical slice: register, onboard,
  pick a companion (Atlas or Nova), land on a personalized dashboard, and navigate the main app
  shell.
- **Sprint 2** delivered the **Workout Engine**: browse a seeded exercise library and curated
  workouts, start a workout plan, log sets (reps/weight/duration) with a rest timer, pause/resume/
  finish, all working fully offline with best-effort background sync, deterministic
  progressive-overload suggestions, automatic personal-record detection, and workout history. See
  [Workout Engine (Sprint 2)](packages/docs/architecture.md#workout-engine-sprint-2) for how it's
  built.

See [`packages/docs/architecture.md`](packages/docs/architecture.md) for how the system fits
together, [`packages/docs/security.md`](packages/docs/security.md) for current controls and
known gaps, [`packages/docs/wearables.md`](packages/docs/wearables.md) for the device-integration
strategy, and [`packages/docs/roadmap.md`](packages/docs/roadmap.md) for what's next.

> **Before implementing product behavior**, read the Project Ascend product documents in
> [`packages/docs/product/`](packages/docs/product/) (start with `founder-vision-bible.md`). They
> override unstated implementation assumptions but do not override security, law, platform policy,
> or verified technical constraints.

## Repository structure

```text
project-ascend/
├── apps/mobile/          Flutter app (Dart)
├── services/api/         NestJS backend (TypeScript)
├── packages/docs/        Architecture, security, wearables, roadmap docs
├── infrastructure/docker/  Dockerfiles
└── docker-compose.yml     PostgreSQL + API for local dev
```

## 1. Prerequisites

- **Node.js** 20+ (verified with Node 22)
- **pnpm** 9+ (`npm install -g pnpm`)
- **Docker** and **Docker Compose** (for PostgreSQL, and optionally the API)
- **Flutter 3.44.8 (stable)**, which bundles **Dart 3.12.2** — this is the exact version
  pinned in CI (`.github/workflows/mobile.yml`) and required by `apps/mobile/pubspec.yaml`'s
  `sdk: ^3.12.2` constraint. Install via https://docs.flutter.dev/get-started/install, then
  `flutter version 3.44.8` if you have a different version active. Using an older Flutter (e.g.
  3.24, which bundles Dart ~3.5) will fail to resolve dependencies against this SDK constraint.
- A configured Android emulator or iOS simulator (or a physical device) to run the mobile app

## 2. Clone the repository

```bash
git clone https://github.com/JPetero/project-ascend.git
cd project-ascend
```

## 3. Install dependencies

```bash
# Backend (installs only the API workspace and its dependencies)
pnpm install --filter @project-ascend/api...
```

```bash
# Mobile
cd apps/mobile
flutter pub get
cd ../..
```

## 4. Set environment variables

```bash
cp services/api/.env.example services/api/.env
```

The defaults in `.env.example` work out of the box with the `docker-compose.yml` PostgreSQL
service. For anything beyond local development, replace `JWT_ACCESS_SECRET` and
`JWT_REFRESH_SECRET` with strong random values (e.g. `openssl rand -base64 48`) — the API refuses
to start in `NODE_ENV=production` with the checked-in development secrets.

## 5. Start PostgreSQL

```bash
docker compose up -d postgres
```

This starts PostgreSQL on `localhost:5432` with the credentials from `docker-compose.yml`
(`ascend` / `ascend_dev_password`, database `ascend_dev`), matching `.env.example`.

Don't have Docker available? Point `DATABASE_URL` in `services/api/.env` at any PostgreSQL 14+
instance you have running locally instead.

## 6. Run the Prisma migration

```bash
cd services/api
pnpm prisma:migrate
cd ../..
```

This applies the committed migration in `services/api/prisma/migrations/` and regenerates the
Prisma client. Use `pnpm prisma:deploy` instead in CI/production (applies migrations without
prompting to create a new one).

Then seed the exercise/workout catalog (exercises, categories, muscle groups, equipment, and a
handful of curated workouts) — required for the Workout Engine's "Browse workouts" and exercise
library to show anything:

```bash
cd services/api
pnpm prisma:seed
cd ../..
```

This is idempotent (safe to re-run) and runs automatically in CI right after migrations.

## 7. Start the API

```bash
pnpm api:dev
```

The API listens on `http://localhost:3000` by default. Swagger/OpenAPI docs are served at
`http://localhost:3000/docs`. Confirm it's up:

```bash
curl http://localhost:3000/health
```

Alternatively, run the whole backend (PostgreSQL + API) in Docker:

```bash
docker compose up -d
```

## 8. Start the Flutter app

With the API running, launch an emulator/simulator or connect a device, then:

```bash
cd apps/mobile
flutter run --flavor dev --dart-define=ENVIRONMENT=dev
```

`--flavor` is required on Android as of S13 Part 16-27, which added `dev`/`staging`/`prod` product
flavors (see `apps/mobile/android/app/build.gradle.kts`) so all three can be installed side by
side on one device without overwriting each other. `--dart-define=ENVIRONMENT=...` is the Dart-side
counterpart — it drives the small "DEV"/"STAGING" corner banner (`AppConfig.environment`,
`EnvironmentBanner`) so a tester can tell at a glance which build they're running; a production
build shows no banner. Neither flag exists/matters on iOS, which has no flavors yet.

By default the app targets `http://10.0.2.2:3000` (the Android emulator's alias for your
machine's `localhost` — see the troubleshooting note below). To point at a different host, e.g.
an iOS simulator or a physical device on your network:

```bash
flutter run --flavor dev --dart-define=ENVIRONMENT=dev --dart-define=API_BASE_URL=http://localhost:3000       # iOS simulator
flutter run --flavor dev --dart-define=ENVIRONMENT=dev --dart-define=API_BASE_URL=http://192.168.1.23:3000    # physical device
```

`API_BASE_URL` has no built-in default for `staging`/`prod` — see `AppConfig`'s doc comment for
why a real host is never guessed at. A staging/prod build must always pass its real API host
explicitly, e.g. `flutter build apk --release --flavor staging --dart-define=ENVIRONMENT=staging
--dart-define=API_BASE_URL=https://staging-api.example.com`.

## 9. Running tests

```bash
# Backend unit tests
pnpm api:test

# Backend end-to-end tests (needs PostgreSQL reachable at DATABASE_URL,
# e.g. `docker compose up -d postgres` first)
pnpm api:test:e2e

# Backend lint
pnpm api:lint
```

```bash
# Mobile static analysis
cd apps/mobile && flutter analyze

# Mobile tests
cd apps/mobile && flutter test

# Mobile formatting check
cd apps/mobile && dart format --output=none --set-exit-if-changed .
```

## 10. Troubleshooting: Android emulator and `localhost`

The Android emulator runs in its own virtual network, so `localhost`/`127.0.0.1` inside the
emulator refers to the emulator itself, not your host machine. Use the special alias
**`10.0.2.2`** instead — this is already the mobile app's default (`AppConfig.apiBaseUrl` in
`apps/mobile/lib/core/config/app_config.dart`), so no extra configuration is needed when running
against a locally-hosted API.

If you're using a physical Android/iOS device instead of an emulator/simulator, it can't reach
`10.0.2.2` or `localhost` at all — pass your machine's LAN IP address via
`--dart-define=API_BASE_URL=http://<your-lan-ip>:3000` as shown above, and make sure the device
and your machine are on the same network with port 3000 reachable (check firewall rules).

iOS Simulator (unlike Android) shares the host's network namespace, so `http://localhost:3000`
works there without any special alias.

## Verified Build Results

The results below are from an actual production-readiness engineering audit pass (the most
recent verification; supersedes earlier numbers), run in a sandboxed Linux container. Every
command was executed for real; nothing here is inferred or assumed. Where a step could not be
completed, that is stated explicitly rather than marked done.

**Environment**

| | |
|---|---|
| OS | Ubuntu 24.04.4 LTS (`Linux 6.18.5-fc-v18`, x86_64) |
| Node.js | v22.22.2 |
| pnpm | 10.33.0 |
| Flutter | 3.44.8 (stable) |
| Dart | 3.12.2 |
| PostgreSQL | 16 (Docker service, per `docker-compose.yml`) |

**Backend**

| Check | Command | Result |
|---|---|---|
| Install deps (frozen lockfile) | `pnpm install --filter @project-ascend/api... --frozen-lockfile` | PASSED |
| Prisma client generation | `pnpm api:prisma:generate` | PASSED |
| Prisma schema validation/format | `prisma validate`, `prisma format` + `git diff --exit-code` | PASSED |
| Migrations applied to a live Postgres | `pnpm --filter @project-ascend/api prisma:deploy` (against `ascend_dev` and `ascend_test`) | PASSED |
| Lint | `pnpm api:lint` | PASSED, 0 errors/warnings |
| Unit tests | `pnpm api:test` | **PASSED — 8/8 tests** |
| E2E tests (real Postgres, real HTTP via Supertest) | `pnpm api:test:e2e` | **PASSED — 19/19 tests** |
| Build | `pnpm api:build` | PASSED |
| `GET /health` (DB-aware: fails if Postgres is unreachable) | `curl http://localhost:3100/health` against a directly-run instance of the built output (`node dist/main.js`) | PASSED — `{"data":{"status":"ok","timestamp":"..."},"meta":{},"error":null}` |
| Auth rate limiting | 12 rapid `POST /auth/login` attempts against the same directly-run instance | PASSED — first 9 returned `401`, the 10th–12th returned `429` |

The e2e suite exercises registration, login, refresh (including rotation and family-wide
revocation on reuse), profile, preferences, devices (including duplicate-connection upserting),
onboarding, and logout end-to-end against a real database.

**Docker**

`docker build` / `docker compose build` / `docker compose up` **could not be executed** in this
sandbox: outbound pulls of the `node:20-alpine` base image are blocked by the sandbox's egress
policy (`production.cloudfront.docker.com` returns `403 Forbidden`, reproduced again in this
pass with `dockerd` actually running — same failure signature as before). This is an environment
restriction, not a defect in the Dockerfile or compose config, and it was not worked around (no
alternate registries, no disabling of the policy).

To compensate, the logic the multi-stage `api.Dockerfile` performs was re-validated directly on
the host, outside Docker, against the current code:
- `pnpm --filter @project-ascend/api deploy --prod --legacy <dir>` was run to reproduce the
  `build` stage's self-contained output, with the generated Prisma client (`.prisma/client`)
  copied in exactly as the Dockerfile's `build` stage does.
- The deployed output was run directly (`node dist/main.js`) with production-shaped environment
  variables, and `/health`, `/auth/register`, `/auth/login`, and the tightened per-route rate
  limit were all confirmed to work against a real Postgres instance.
- `docker compose config --quiet` was run to confirm `docker-compose.yml` is still syntactically
  valid.

Because of this, the Docker health check and the "runs as non-root without pnpm at runtime"
property are believed correct by construction (the `runtime` stage never installs pnpm and the
`HEALTHCHECK` calls the same `/health` endpoint verified above) but were **not** verified inside
an actual container in this sandbox.

**Mobile**

| Check | Command | Result |
|---|---|---|
| `flutter --version` | — | `Flutter 3.44.8 • Dart 3.12.2` |
| Dependencies | `flutter pub get` | PASSED |
| Static analysis | `flutter analyze` | PASSED — "No issues found!" |
| Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED |
| Tests | `flutter test` | **PASSED — 19/19 tests** |

**Known limitations**

- Docker images were never literally built or run as containers in this sandbox (see above);
  the underlying `pnpm deploy` + Prisma-client packaging logic was validated by direct execution
  instead. Anyone with unrestricted Docker Hub access should run `docker compose build && docker
  compose up -d` to get a final container-level confirmation — the `docker-build` job in
  `.github/workflows/backend.yml` does this automatically on every push/PR.
- Concurrent refresh-token reuse (two simultaneous requests racing to rotate the same token) is
  proven via unit tests that mock the transaction boundary, plus reasoning about PostgreSQL's
  default READ COMMITTED isolation making the guarded `updateMany` a safe compare-and-swap — not
  via literal simultaneous real HTTP requests hitting a live server.
- No account lockout / exponential backoff exists beyond the per-route rate limit (see
  [`packages/docs/security.md`](packages/docs/security.md#known-gaps-before-production) for the
  full list of known gaps before a real production launch).

## Sprint 2 (Workout Engine) — Verified Build Results

Run for real in the same sandboxed Linux container immediately before the Sprint 2 commit, against
a locally-running PostgreSQL 16 instance (Docker's daemon was unavailable in this pass, same
restriction as the Sprint 0/1 audit above — see that section's "Docker" note).

**Backend**

| Check | Command | Result |
|---|---|---|
| Prisma schema validation/format | `prisma validate`, `prisma format` + `git diff --exit-code` | PASSED |
| Migrations applied | `pnpm --filter @project-ascend/api prisma:deploy` | PASSED |
| Catalog seed | `pnpm --filter @project-ascend/api prisma:seed` | PASSED — 5 categories, 8 muscle groups, 5 equipment types, 22 exercises, 4 workouts |
| Lint | `pnpm api:lint` | PASSED, 0 errors/warnings |
| Unit tests | `pnpm api:test` | **PASSED — 20/20 tests** (up from 8; Sprint 2 added exercise-progression and personal-record-detection specs) |
| E2E tests (real Postgres, real HTTP via Supertest) | `pnpm api:test:e2e` | **PASSED — 31/31 tests** (up from 19; Sprint 2 added `workout-engine.e2e-spec.ts`, covering the catalog, workout plans, and the full session lifecycle including pause/resume, set logging, and personal records) |
| Build | `pnpm api:build` | PASSED — `dist/main.js` at the correct path (re-verified after adding `prisma/seed.ts`, which shifted TypeScript's inferred `rootDir` until `tsconfig.build.json` excluded it) |

**Mobile**

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | PASSED — "No issues found!" |
| Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED |
| Tests | `flutter test` | **PASSED — 30/30 tests** (up from 19; Sprint 2 added the workout session controller's online/offline/retry-sync flow, the rest timer, Workout-tab navigation, and workout history rendering) |

Docker itself was not re-verified as a container build in this pass, for the same environment
reason as the Sprint 0/1 audit; `docker-build` in `.github/workflows/backend.yml` covers that on
every push/PR.

## Build Session 1 (P0) — Verified Build Results

Foundation-repair pass. Full log with per-item reasoning in
[`packages/docs/build-session-1.md`](packages/docs/build-session-1.md). Environment: same
sandboxed Linux container, Node 22, pnpm 9.15.9, PostgreSQL 16 (local, not Docker — the daemon is
unreachable in this sandbox; see below).

**Backend**

| Check | Command | Result |
|---|---|---|
| Migration created and applied | `prisma migrate diff` + `prisma migrate deploy` (non-interactive `migrate dev` isn't supported in this shell) | PASSED — `20260806024532_p0_refresh_token_reuse_and_device_key`, applied to both `ascend_dev` and `ascend_test` |
| Lint | `pnpm api:lint` | PASSED, 0 errors/warnings |
| Unit tests | `pnpm api:test` | **PASSED — 21/21 tests** (up from 20; +1 `logoutAll` test) |
| E2E tests | `pnpm api:test:e2e` | **PASSED — 33/33 tests** (up from 31; +1 multi-device `connectionKey` test, +1 `logout-all` test) |
| Build | `pnpm api:build` | PASSED |
| Deployed-output smoke test (Docker unavailable — see below) | `node dist/main.js` against real Postgres with production env vars | PASSED — `/health` returned `200`, `/auth/register` succeeded end-to-end, `Mapped {/auth/logout-all, POST} route` confirmed registered |

**Mobile**

| Check | Command | Result |
|---|---|---|
| `flutter --version` | — | `Flutter 3.44.8 • channel stable`, matches `pubspec.yaml`'s `sdk: ^3.12.2` and CI's pin exactly — no drift found |
| Static analysis | `flutter analyze` | PASSED — "No issues found!" |
| Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED |
| Tests | `flutter test` | **PASSED — 33/33 tests** (up from 30; +3 `splash_resilience_test.dart`: recoverable profile-fetch-failure state, sign-out from that state, session-expired handling) |

**Docker**

`docker compose up --build -d` could not be run: the Docker daemon is unreachable in this sandbox
(`Cannot connect to the Docker daemon at unix:///var/run/docker.sock`; `service docker start`
fails with `ulimit: error setting limit (Operation not permitted)`, a container-level privilege
restriction — confirmed on two attempts, one with an unsandboxed shell). This is unchanged from
the Sprint 0/1 and Sprint 2 audits above. `infrastructure/docker/api.Dockerfile` and
`docker-compose.yml` were inspected and already satisfy every P0.6 requirement (non-root runtime
user, healthcheck against `/health`, `migrate` stage running `prisma migrate deploy` — never
`migrate dev` — gating the `api` service via `service_completed_successfully`); compensating
verification was done by direct execution (see the Backend table above and
`build-session-1.md`'s P0.6 entry for full detail). `docker-build` in
`.github/workflows/backend.yml` builds both the `runtime` and `migrate` targets on every push/PR.

**What changed**

- `RefreshToken.reusedAt` (distinguishes family-revoked-by-reuse-detection from an ordinary
  rotation revoke) and `POST /auth/logout-all` ("sign out everywhere").
- `DeviceConnection.connectionKey` (`@@unique([userId, provider, connectionKey])`, default
  `"default"`) so a provider that supports multiple physical devices (e.g. two paired watches) can
  register more than one connection instead of silently upserting into a single row.
- `apps/mobile/test/core/splash_resilience_test.dart` — new coverage for the recoverable
  splash-error state and session-expired handling (both were already implemented in code; only
  the tests were missing).

Everything else audited under P0 (Flutter/Dart version pinning, onboarding's local-first
persistence, both CI workflows) was already correct from prior session work and required no
changes — see `build-session-1.md` for the item-by-item verification.

## Build Session 1 (P1) — Verified Build Results

Workout Engine MVP gap-closing pass (the vertical slice already existed from Sprint 2; this closed
the remaining gaps against a fuller spec). Full log in
[`packages/docs/build-session-1.md`](packages/docs/build-session-1.md), including the honest list
of what's still **not** done (exercise substitution UI, a from-scratch plan editor, RPE input, and
a formal idempotency-key column for offline sync — see that file's "Not implemented this session"
section).

**Backend**

| Check | Command | Result |
|---|---|---|
| Type check | `pnpm exec tsc --noEmit` | PASSED, 0 errors |
| Migration created and applied | `20260806025612_p1_measurement_type_and_distance_target` (adds `Exercise.measurementType`, `targetDistanceMeters` on prescribed exercises, `ESTIMATED_ONE_REP_MAX`/`BEST_PACE` personal-record types) | PASSED, applied to `ascend_dev` and `ascend_test` |
| Seed idempotency | `pnpm prisma:seed` run twice, then real DB row counts queried via `psql` (not the seed script's own log line) | PASSED — `exercises=49`, `workouts=13`, `workout_exercises=52`, `exercise_alternatives=38`, identical after both runs |
| Lint | `pnpm api:lint` | PASSED, 0 errors/warnings |
| Unit tests | `pnpm api:test` | **PASSED — 23/23 tests** (up from 21; +2 personal-record tests for estimated 1RM and best pace) |
| E2E tests | `pnpm api:test:e2e` | **PASSED — 33/33 tests** (unchanged count; existing coverage continues to pass against the expanded 49-exercise/13-workout catalog) |
| Build | `pnpm api:build` | PASSED |

**Mobile**

| Check | Command | Result |
|---|---|---|
| Dependencies | `flutter pub get` | PASSED (added `clock: ^1.1.1` as a direct dependency, for a fake-clock-testable rest timer) |
| Static analysis | `flutter analyze` | PASSED — "No issues found!" |
| Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED |
| Tests | `flutter test` | **PASSED — 45/45 tests** (up from 33; +7 `workout_streak_test.dart`, +5 net on dashboard tests, rest-timer fix re-verified against its existing 2 tests) |

**What changed**

- `Exercise.measurementType` (`REPS_WEIGHT`/`REPS_ONLY`/`DURATION`/`DISTANCE_DURATION`/
  `ASSISTED_WEIGHT`/`BODYWEIGHT`, filterable via `GET /exercises?measurementType=`) and
  `targetDistanceMeters` on prescribed exercises, closing a real data-model gap (walking/running
  entries had nowhere to prescribe a distance target).
- Seed catalog expanded from 22 to 49 exercises (added bodyweight regressions, more dumbbell/
  barbell/resistance-band movements, mobility stretches, and — previously entirely missing —
  walking/running entries) and from 4 to 13 workouts (added the 9 required starter plans as
  genuine additions, keeping the original 4 unchanged so existing e2e coverage keeps passing).
- Two new personal-record types: `ESTIMATED_ONE_REP_MAX` (Epley formula, capped to ≤12-rep sets,
  always labeled as an estimate) and `BEST_PACE` (m/s, from sets with both distance and duration).
- Rest timer rewritten to compute from wall-clock timestamps instead of an in-memory tick
  counter — catching and fixing two real off-by-one bugs (a lazy-`late`-field bug that shifted the
  whole countdown a full tick late, and a truncation-vs-rounding bug) by actually running its
  tests after each change, not just reading the diff.
- Dashboard now shows real workout status (active/resumable session, or the most recent real
  completed workout, or an honest empty state), a real streak (`computeWorkoutStreak()`, a pure
  function over completed-session dates), and a real most-recent-personal-record card — replacing
  the `DashboardFixture` sample data that previously stood in for all three. The remaining
  nutrition/sleep/recovery cards stay fixture-backed and are now more specifically labeled
  ("Nutrition, sleep & recovery — sample data") so they don't look like the newly-real sections
  next to them.

**Docker**: same unavailable-in-this-sandbox situation as P0 and the prior audits; no new Docker
verification was needed for P1 since `infrastructure/docker/api.Dockerfile` and
`docker-compose.yml` weren't touched this pass.

## Build Session 3 (Product Alignment and Nutrition) — Verified Build Results

Five-tab navigation migration (Workout, Meal Prep, Social, Assistant, Leaderboards) with a
pushed (non-tab) Dashboard, a Dashboard rebuilt on real data only (no more fabricated steps/
sleep/recovery), backend architecture for Terms acceptance / multi-provider auth identities /
coaching style / deload recommendations, a centralized free-premium capability model, and a
Meal Prep vertical slice (food search, custom foods, per-meal logging, water tracking) on top of
the existing Nutrition backend. Full log, including the honest "not done this session" list, in
[`packages/docs/build-session-3.md`](packages/docs/build-session-3.md).

**Backend**

| Check | Command | Result |
|---|---|---|
| Install | `pnpm install --frozen-lockfile` | PASSED |
| Schema format/validate | `npx prisma format` / `npx prisma validate` | PASSED |
| Migration created and applied | `20260806113251_product_alignment_scenarios` (adds `Preference.coachingStyle`/`toneIntensity`, `AuthIdentity`, `LegalDocument`/`LegalAcceptance`, `DeloadRecommendation`, plus a backfill of every existing user to an `EMAIL` `AuthIdentity` row) | PASSED — verified against both a fresh database and a throwaway database seeded with legacy-shaped rows (see `build-session-3.md`) |
| Seed idempotency | `pnpm prisma:seed` run twice | PASSED — `26 foods`, `2 legal documents`, identical both runs |
| Lint | `pnpm api:lint` | PASSED, 0 errors/warnings |
| Unit tests | `pnpm api:test` | **PASSED — 115/115 tests** (up from 78; new `auth-identities`, `legal`, `deload`, `entitlements` suites plus a `calculateConsecutiveActiveWeeks` addition to `progress.util`) |
| Build | `pnpm api:build` | PASSED |
| E2E tests | `pnpm api:test:e2e` | **PASSED — 49/49 tests** (unchanged — no e2e regressions from this session's additive-only changes) |

**Mobile**

| Check | Command | Result |
|---|---|---|
| Dependencies | `flutter pub get` | PASSED |
| Static analysis | `flutter analyze` | PASSED — "No issues found!" |
| Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED |
| Tests | `flutter test` | **PASSED — 104/104 tests** (up from 57; new `bmi_test`, `progress_util_test`, `workout_calendar_test`, `workout_summary_screen_test`, `capability_test`, and the `features/nutrition/` suite; `home_dashboard_test.dart` removed along with the screen it tested) |

**What changed**: see `build-session-3.md` for the full breakdown — navigation/dashboard
rebuild, Scenario 1/3/6/10 backend architecture, the free/premium capability model, and the Meal
Prep tab.

**Docker**: unavailable in this sandbox (`docker ps` — no daemon). Not exercised this session;
`docker-compose.yml` was not modified.

## Build Session 4 (Autonomous Implementation Marathon) — Verified Build Results

Deload recommendation UI, Nutrition production-readiness (saved meals, meal copying, a macro
target editor), a coaching-style- and companion-aware Atlas & Nova dialogue layer, the
Achievement Engine (idempotent award service, 10-item seeded catalog, Flutter screen), GPS Cardio
manual/summary logging with a privacy-flag model ready for future route recording, a shared
Flutter form-validators module, and a repository cleanup pass (dead code removed, two orphaned
widgets wired back in). Full log, including the honest "not done this session" list, in
[`packages/docs/build-session-4.md`](packages/docs/build-session-4.md).

**Backend**

| Check | Command | Result |
|---|---|---|
| Migration created and applied | `20260806140257_saved_meals_achievements_cardio` (adds `SavedMeal`/`SavedMealItem`, `Achievement`/`AchievementAward`, `CardioSession`, plus the `AchievementCategory`/`CardioActivityType` enums) | PASSED — verified against both a fresh database and a throwaway database seeded with legacy-shaped rows |
| Seed idempotency | `npx prisma db seed` re-run after adding the Cardio achievements | PASSED — achievement count went 8 → 10 correctly, pre-existing 8 unchanged |
| Lint | `pnpm api:lint` | PASSED, 0 errors/warnings |
| Unit tests | `pnpm api:test` | **PASSED — 153/153 tests** (up from 140; new `saved-meals`, `achievements`, `cardio` suites) |
| Build | `pnpm api:build` | PASSED |
| E2E tests | `pnpm api:test:e2e` | **PASSED — 54/54 tests** (up from 49; new `cardio.e2e-spec.ts`, plus achievement-award assertions added to the existing nutrition/workout-engine specs) |

**Mobile**

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | PASSED — "No issues found!" |
| Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED |
| Tests | `flutter test` | **PASSED — 168/168 tests** (up from 127; new `achievements/`, `cardio/`, `companion/` dialogue, and `form_validators`/`sync_status_indicator` suites) |

**What changed**: see `build-session-4.md` for the full breakdown across all 8 parts completed
this session (Workout gaps, Nutrition, Dashboard audit, Atlas & Nova, Achievements, GPS Cardio,
shared-platform strengthening, repository cleanup).

**Docker**: unavailable in this sandbox (`docker ps` — no daemon). Not exercised this session;
`docker-compose.yml` was not modified.
