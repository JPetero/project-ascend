# Build Session 1 — Autonomous Build Log

Append-only. Each entry records what was actually done, commands actually run, and their real
output. Nothing in this file is aspirational — if a step wasn't executed, it says so explicitly.

---

## Session start

2026-08-06T02:41:25Z — session start, branch claude/new-session-qy6hzm at ef525b5

## P0.1 — Flutter SDK consistency: VERIFIED, no changes needed

`apps/mobile/pubspec.yaml` (`sdk: ^3.12.2`), `.github/workflows/mobile.yml`
(`flutter-version: "3.44.8"`, `channel: "stable"`), and `README.md` were already fully aligned
from prior session work. Confirmed against the actually-installed toolchain:

```
$ flutter --version
Flutter 3.44.8 • channel stable • https://github.com/flutter/flutter.git
```

Matches exactly. No drift found.

## P0.2 — Refresh-token family security: mostly pre-existing, closed two real gaps

Inspected `services/api/src/modules/auth/auth.service.ts` and its tests. The core security
property was already implemented correctly from prior session work:
- `RefreshToken.familyId` links every token descended from one login.
- Rotation runs inside `prisma.$transaction`, using a `revokedAt: null` guard on `updateMany` as
  a compare-and-swap — a concurrent request racing to rotate the same token affects 0 rows and is
  routed into the same reuse-handling path (`RefreshTokenReuseError` -> `handleRefreshTokenReuse`).
- Reuse of an already-rotated/revoked token revokes every active token in the family and records
  an `auth.refresh_token_reuse_detected` audit event.
- The client only ever sees a generic "Refresh token is invalid or expired." 401.
- `tokenHash` only; the raw secret is never stored (argon2 hash, verified with `argon2.verify`).

Two genuine gaps closed this session:
1. **`reusedAt` timestamp** — the spec asked for a "reuse-detection timestamp" distinct from the
   generic `revokedAt`. Added `RefreshToken.reusedAt DateTime?`, set only inside
   `handleRefreshTokenReuse`, never on an ordinary rotation revoke — an auditor can now tell
   "rotated normally" from "killed by reuse handling" directly from the row.
2. **`POST /auth/logout-all`** — no "sign out everywhere" endpoint existed. Added
   `AuthService.logoutAll(userId)` (revokes every active token across every family for the user,
   records an `auth.logout_all` audit event) and the authenticated controller route.

Not implemented, by deliberate choice: literal `parentTokenId`/`replacedByTokenId` relations. The
existing `familyId` + `revokedAt` design already gives every required security property (rotate
once, old token dead, reuse kills the whole lineage) without a parent/child chain, and rebuilding
that as a literal graph would add join complexity for no behavior change. Documented here per the
instruction to record reasonable engineering decisions rather than implement them silently.

Migration: `20260806024532_p0_refresh_token_reuse_and_device_key` (see P0.3 below — combined into
one migration since both touch this session's schema at once).

Tests added:
- `auth.service.spec.ts`: `logoutAll` unit test (revokes all active tokens for the user, distinct
  audit action from reuse handling). Updated the two existing reuse-path assertions to expect the
  new `reusedAt` field.
- `app.e2e-spec.ts`: `logs out of all sessions and revokes every active refresh token for the
  user` — logs in twice (two separate token families for the same user), calls `/auth/logout-all`
  with one session's access token, confirms both refresh tokens are rejected afterward.

Not added: a literal "two simultaneous real HTTP requests" concurrency test — the race is proven
by the existing unit test that mocks the transaction boundary losing the compare-and-swap
(`tx.refreshToken.updateMany` returning `count: 0`), plus the reasoning above about Postgres READ
COMMITTED making the guarded `updateMany` a safe CAS. Same standard as the earlier Sprint 0/1
audit in this repo.

## P0.3 — Device connection uniqueness: closed

Previous constraint was `@@unique([userId, provider])` — one connection per provider, full stop,
even though `externalAccountId` existed as an unused nullable field. This silently prevented ever
registering two physical devices from the same provider (e.g. two paired Garmin watches).

Added `DeviceConnection.connectionKey String @default("default")`, changed the constraint to
`@@unique([userId, provider, connectionKey])`, and added an index-backed composite key. Chose a
default-valued required column (not `externalAccountId` itself, which stays nullable/informational)
because Postgres treats `NULL` as distinct in unique constraints — a nullable uniqueness column
would not have prevented duplicates for the common case of no `externalAccountId` being supplied.
`CreateDeviceDto.connectionKey` is optional (`^[A-Za-z0-9._:-]+$`, max 200 chars); omitting it
preserves the original one-connection-per-provider upsert behavior for simulated/basic providers.

Tests added: `app.e2e-spec.ts` — "a distinct connectionKey registers a second physical device for
the same provider" (asserts a second row is created, not upserted, and both appear in `/devices`).

## Verification after P0.2 + P0.3

```
$ pnpm api:lint         -> PASSED, 0 errors/warnings
$ pnpm api:test         -> PASSED, 21/21 (was 20; +1 logoutAll unit test)
$ pnpm api:test:e2e     -> PASSED, 33/33 (was 31; +1 connectionKey, +1 logout-all)
$ pnpm api:build        -> PASSED
```

Migration applied and verified against both `ascend_dev` and `ascend_test` via `prisma migrate
deploy` (real local PostgreSQL 16, not Docker — see Docker note below).

## P0.4 — Splash and session resilience: VERIFIED pre-existing, added missing test coverage

Read `apps/mobile/lib/features/auth/presentation/providers/auth_controller.dart`,
`.../screens/splash_screen.dart`, and `core/routing/app_router.dart`'s `_redirect()`. All of the
required behaviors were already implemented from prior session work:
- `AuthController._bootstrap()` retries a profile-fetch network error up to 3 times with backoff,
  but never wipes a valid session on a transient failure — only a confirmed 401 or exhausted
  retries end the session.
- `SplashScreen` renders `_SplashError` (Try again / Sign out) when `profileControllerProvider`
  is `AsyncError`, instead of an unrecoverable spinner.
- `ApiClient`'s automatic refresh-and-retry-on-401 calls `onSessionExpired` on failure, which bumps
  `sessionExpiredNotifierProvider`; `AuthController` listens on that and calls
  `handleSessionExpired()`, clearing tokens + Drift cache and setting `unauthenticated`.
- `AuthRepository.logout()` clears local tokens in a `finally`-equivalent path regardless of
  whether the server-side `/auth/logout` call succeeds.
- Auth status is derived only from `AuthController`'s own state (token presence + `/auth/me`
  result), never from cached profile data, so a stale local profile cannot resurrect a session.
- `_redirect()` in `app_router.dart` was traced by hand for cycles: every branch either returns
  `null` (stay) or a fixed target gated by a condition that itself returns `null` once satisfied.
  No cycle exists, including for the Workout Engine's top-level routes added in Sprint 2.

Gap found: none of this had test coverage. Added `test/core/splash_resilience_test.dart` (3
tests): profile-fetch failure shows the recoverable error state (not an infinite spinner) and
"Try again" actually recovers once connectivity returns; "Sign out" from the error state clears
the session and returns to Welcome; and a simulated `sessionExpiredNotifierProvider` bump (the
real trigger path from a failed silent refresh) clears the authenticated session and returns to
Welcome. Required extending `FakeProfileRepository` with a `failFetch` toggle.

## P0.5 — Onboarding persistence: VERIFIED pre-existing, no changes needed

`OnboardingController` (`apps/mobile/lib/features/onboarding/presentation/providers/onboarding_controller.dart`)
already does exactly what the spec asks, structurally rather than via a debounce timer: every
field edit (`updateDraft`/`setCompanion`) writes to the local Drift draft immediately and *only*
that — no API call happens per keystroke. The API is only ever called from `goNext()`, i.e. on
page advance and at completion (last page sets `onboardingCompleted: true`). A failed `goNext()`
sync preserves the local draft and current page, surfaces `OnboardingState.syncError`
non-blockingly, and the same "Next" tap retries. Already covered by
`test/features/onboarding/onboarding_navigation_test.dart`. No debounce timer was added since the
existing design already satisfies "do not call the API for every minor interaction" without one.

## P0.6 — Docker and migrations: verified by direct execution; `docker compose up --build` itself unverified

`infrastructure/docker/api.Dockerfile` and `docker-compose.yml` were inspected and already
implement every required property from prior session work: multi-stage build (`build` ->
`migrate`/`runtime`), `runtime` stage contains only compiled `dist/`, production `node_modules`,
and the generated Prisma client (no pnpm, no dev deps), runs as a non-root `ascend` user, has a
`HEALTHCHECK` hitting `/health`, and `docker-compose.yml` sequences `postgres` (health-gated) ->
`migrate` (runs `prisma migrate deploy`, never `migrate dev`) -> `api` (depends on migrate's
`service_completed_successfully`).

**`docker compose up --build -d` itself could not be run**: the Docker daemon is unreachable in
this sandbox (`Cannot connect to the Docker daemon at unix:///var/run/docker.sock`), and
`service docker start` fails with `ulimit: error setting limit (Operation not permitted)` — a
container-level privilege restriction, confirmed on two attempts including with an unsandboxed
shell. This is an environment limitation, not a defect in the Dockerfile/compose files, and
matches the same restriction hit in the prior Sprint 0/1 audit recorded in the root README.

To compensate, the `build` stage's logic was reproduced directly, for real, outside Docker:
- `pnpm deploy --prod <dir> --filter @project-ascend/api` (the exact command the Dockerfile runs)
  against a real temp directory.
- The generated Prisma client copied in exactly as the Dockerfile's fix-up step does.
- The deployed output run directly with production-shaped env vars
  (`NODE_ENV=production`, real Postgres) via `node dist/main.js`.
- `GET /health` returned `{"data":{"status":"ok",...}}`.
- `POST /auth/register` succeeded end-to-end (hashed password, issued tokens, wrote a real row) —
  this also confirms the new `/auth/logout-all` route registered correctly
  (`Mapped {/auth/logout-all, POST} route` appeared in the Nest startup log).

Not verified in this pass: the actual multi-stage Docker build, the `HEALTHCHECK` directive
executing inside a container, and the non-root user constraint enforced by the container runtime
itself. `docker-build` in `.github/workflows/backend.yml` (unchanged, already present) covers all
three on every push/PR — the workflow builds both the `runtime` and `migrate` targets.

## P0.7 — CI verification: VERIFIED, no changes needed

Read `.github/workflows/backend.yml` and `.github/workflows/mobile.yml` in full.

Backend CI already has every required step: frozen-lockfile install, `prisma validate`, a
format-then-`git diff --exit-code` formatting check, `prisma generate`, `prisma migrate deploy`
against a real CI Postgres service container, catalog seed, lint, unit tests, e2e tests, build,
and a separate `docker-build` job that builds both the `runtime` and `migrate` Dockerfile targets.

Mobile CI already has: pinned `flutter-version: "3.44.8"` / `channel: "stable"`, `flutter pub get`,
`flutter analyze`, `dart format --output=none --set-exit-if-changed .`, `flutter test`.

Path filters on both workflows (`paths:` under `push`/`pull_request`) already scope correctly to
their respective trees; no shared files were added this session that would need a filter update.

## P0.8 — Documentation truthfulness

See the "Build Session 1 (P0) — Verified Build Results" section added to the root `README.md`,
generated from the actual command output captured in this log — not from memory or assumption.

---

# P1 — Workout Engine MVP (extending the already-substantial Sprint 2 implementation)

The Workout Engine already existed as a complete, tested vertical slice from prior session work
(catalog browsing, custom-from-catalog plans, full session lifecycle with offline-first logging,
deterministic progression suggestions, personal-record detection, history, 8 Flutter screens, 30
backend + 30 Flutter tests, all passing). This section's job was to close the specific gaps
between that implementation and this session's fuller P1 spec — not to rebuild it.

## P1.1 — Domain model: added `MeasurementType` and `targetDistanceMeters`

Two real gaps in the existing normalized schema:
1. **No `measurementType` on `Exercise`.** The data model could already store
   reps/weight/duration/distance on a `WorkoutSet`, but nothing declared which combination was
   *valid* for a given exercise, or told a client which input controls to show. Added
   `enum MeasurementType { REPS_WEIGHT, REPS_ONLY, DURATION, DISTANCE_DURATION, ASSISTED_WEIGHT,
   BODYWEIGHT }` and `Exercise.measurementType` (`@default(REPS_WEIGHT)`), plus a
   `measurementType` filter on `GET /exercises`. Deliberately no `CALORIES` option — there is no
   real calorie-estimation pipeline, and the P0 operating rules explicitly forbid faking health
   data.
2. **No distance target on prescribed exercises.** `WorkoutExercise`/`WorkoutPlanExercise` had
   `targetReps`/`targetDurationSeconds`/`targetWeightKg` but no `targetDistanceMeters`, so a
   walking/running entry in a plan had no way to prescribe a distance. Added
   `targetDistanceMeters Float?` to both models.

Migration: `20260806025612_p1_measurement_type_and_distance_target`, applied to both `ascend_dev`
and `ascend_test`. Also added `ESTIMATED_ONE_REP_MAX` and `BEST_PACE` to `PersonalRecordType` (see
P1.6 below) in the same migration.

`ExercisesService.serialize()` now includes `measurementType` in the API response; the
`Prisma migrate diff`/non-interactive workaround from P0.2/P0.3 was reused (this shell doesn't
support `prisma migrate dev`'s interactive prompt).

Not implemented: a separate `WorkoutSessionExercise` join table, or a
`WorkoutSyncOperation`/idempotency-key table. The existing design already gets the required
properties a different, already-working way — see P1.7 for why a formal idempotency-key table
wasn't added on top of the existing offline-sync design.

## P1.2 — Exercise safety model: already satisfied

Every field the spec lists (name, slug, description, difficulty, instructions, primary/secondary
muscles, equipment, safety guidance, common mistakes, alternatives, media placeholders) already
existed from Sprint 2. "Movement pattern" and "regression/progression options" beyond
`alternatives` were not added as separate fields — `alternatives` (bidirectional,
`ExerciseAlternative`) already models exactly this relationship, and several new seed exercises
are explicit regressions linked via that mechanism (e.g. `incline-push-up`/`knee-push-up` as
alternatives of `push-up`; `chair-squat` of `bodyweight-squat`; `wall-sit` of `plank`). No sex-based
exercise selection exists anywhere in the codebase — plan creation is driven by catalog choice,
goals/equipment/experience already collected in onboarding, never by `sexForCalculations` (which
exists solely for BMR/calorie-style calculations, unrelated to workout selection).

## P1.3 — Seed data: expanded from 22 to 49 exercises, 4 to 13 workouts

Added 27 new exercises to reach 49 total (`services/api/prisma/seed.ts`), covering every category
the spec requires that wasn't already present: bodyweight regressions and core work (11:
`incline-push-up`, `knee-push-up`, `wall-sit`, `glute-bridge`, `superman-hold`, `dead-bug`,
`bird-dog`, `step-up`, `chair-squat`, `side-plank`, `bicycle-crunch`), dumbbell (6), barbell (2),
resistance-band (3), mobility (2: `hip-flexor-stretch`, `ninety-ninety-hip-stretch`), and — the
categories that were entirely missing before — walking and running (3: `brisk-walk`, `easy-run`,
`interval-run`, all `DISTANCE_DURATION`). Added 14 new alternative pairs, several specifically
regression/progression relationships (push-up family, squat family).

Added the 9 required starter plans (`Beginner Full Body`, `Home Bodyweight`, `Dumbbell Full Body`,
`Upper/Lower Starter`, `Push/Pull/Legs Starter`, `Calisthenics Starter`, `Mobility and Recovery`,
`Beginner Walking Plan`, `Beginner Running Plan`) **as additions**, keeping the original 4 Sprint 2
plans (`Full Body Strength`, `Upper Body Push`, `Bodyweight HIIT Blast`, `Mobility & Recovery
Flow`) unchanged — `test/workout-engine.e2e-spec.ts` references `full-body-strength` by slug and
its exact exercise list, and the spec's "at least these starter plans" is a floor, not a
replacement list. `Upper/Lower Starter` and `Push/Pull/Legs Starter` are each one representative
session introducing that split style, not a full multi-day rotation — the data model represents
one `Workout` at a time, so a real multi-day program is out of scope here (documented in the seed
file and in `roadmap.md`).

**Idempotency verified for real, not assumed**: ran `pnpm prisma:seed` twice back-to-back, then
queried actual row counts directly via `psql` (not the seed script's own log output, which only
reflects source array lengths): `exercises=49`, `workouts=13`, `workout_exercises=52`,
`exercise_alternatives=38` — identical after both runs, confirming the upsert-based seed is
genuinely idempotent, not just log-idempotent.

## P1.4 — Backend modules and APIs: measurement-type filter added, rest already existed

`exercises`, `workouts`/`workout-plans`, `workout-sessions`, `personal-records`,
`workout-history` modules, DTOs, controllers, and ownership checks (404, not 403, on
cross-user access — see Sprint 2) already existed and already cover every required capability
except measurement-type filtering, added this session (`QueryExercisesDto.measurementType`,
`ExercisesService.list()`'s `where` clause). Transactions for session completion and PR detection
already existed (`WorkoutSessionsService.finish()` -> `endSession()` inside the session's own
flow, `PersonalRecordsService.detectAndRecord()` called right after).

## P1.5 — Progression suggestions: already satisfied

`ExercisesService.getProgressionSuggestion()`/`suggestNext()` already implements exactly the rules
the spec describes: conservative, deterministic, no AI, per-measurement-type rules (weight: small
guaranteed increment; duration: `max(+5s, +10%)`; distance: `+10%`; reps-only: `+1`), and every
suggestion's `rationale` string explicitly offers "repeat if not fully recovered" as an equally
valid choice — nothing is forced. No "user-reported effort" input exists yet (RPE/RIR) — the
existing rule set doesn't need it (it works from completed-vs-target reps already implicit in what
was logged), and adding an effort-rating field/UI was out of scope for the time available this
session; noted as a real gap below.

## P1.6 — Personal record detection: added estimated 1RM and pace

`PersonalRecordsService.computeCandidates()` already handled max weight/reps/duration/distance and
session volume. Added two more candidate types, both across `MeasurementType` boundaries the spec
calls out:
- **`ESTIMATED_ONE_REP_MAX`** — Epley formula (`weight * (1 + reps/30)`), computed only from sets
  of 12 reps or fewer (the formula's error grows sharply beyond that, to the point of being
  actively misleading rather than a useful estimate), clearly typed/labeled as an estimate via its
  enum name and `unit: 'kg'` — never presented as a measured max.
- **`BEST_PACE`** — meters/second, computed only from sets carrying both `distanceMeters` and a
  positive `durationSeconds` (a zero-duration set is excluded rather than dividing by zero).

Both guarded by the same "only upsert if strictly better" logic as the existing types, so they
share the "current-best, not append-only" design already in place. Unit tests added for both
(Epley computation + the 12-rep cap, and pace computation + zero-duration exclusion).

No cross-measurement-type comparisons are possible by construction — each `PersonalRecordType` is
only ever computed from sets carrying the specific fields it needs, so e.g. a `BEST_PACE` value
can never be compared against a `MAX_WEIGHT` value.

## Verification after P1.1–P1.6 (backend)

```
$ pnpm exec tsc --noEmit         -> PASSED, 0 errors
$ pnpm prisma:seed (x2, fresh)   -> PASSED both times; DB row counts identical after both runs
                                    (49 exercises / 13 workouts / 52 workout_exercises /
                                    38 exercise_alternatives) — confirmed via direct psql query,
                                    not just the seed script's own log line
$ pnpm api:lint                  -> PASSED, 0 errors/warnings
$ pnpm api:test                  -> PASSED, 23/23 tests (was 21; +2 personal-record tests)
$ pnpm api:test:e2e              -> PASSED, 33/33 tests (unchanged count — no new e2e tests added
                                    this pass; existing coverage continues to pass against the
                                    expanded catalog)
$ pnpm api:build                 -> PASSED
```

## P1.9 (partial) — Rest timer: fixed a real backgrounding/accuracy bug

The existing `RestTimer` decremented an in-memory `int` once per `Timer.periodic` tick — exactly
the pattern the spec calls out as insufficient ("calculate from timestamps rather than relying
only on an in-memory decrement"). Rewrote it to derive the displayed remaining time from
`clock.now().difference(_endAt)` on every tick, where `_endAt` is an absolute end timestamp set
once in `initState()`. This is correct across backgrounding: `Timer.periodic` doesn't fire while
the app is suspended, but the very next tick after resuming recomputes the correct remaining time
from the wall clock instead of continuing a now-stale countdown.

Two real bugs caught and fixed *during this rewrite*, before commit, by actually running the
existing widget tests rather than assuming the change was correct:
1. **Lazy-`late` off-by-one.** The first version set `_endAt` via a `late final` field
   initializer (`late final DateTime _endAt = clock.now().add(...)`). Dart's `late` fields
   initialize on first *read*, which turned out to be inside the first `_tick()` call — a full
   second after construction — silently shifting the entire countdown a tick late. Fixed by
   setting `_endAt` explicitly and eagerly in `initState()`.
2. **Truncation off-by-one.** Using `.difference(...).inSeconds` truncates toward zero, so a
   181ms-under-a-full-second remainder (ordinary scheduling jitter) would read as one second
   *lower* than it should and could end the rest a tick early. Fixed by computing from
   milliseconds and rounding up (`(remainingMs / 1000).ceil()`).
3. **`DateTime.now()` isn't fake-clock-aware in `flutter_test`.** Flutter's `tester.pump(duration)`
   only fake-advances `Timer`s and microtasks, not raw `DateTime.now()` calls, so widget tests
   using `pump()` to simulate elapsed seconds would never see the countdown move. Added
   `package:clock` as a direct dependency and switched to `clock.now()`, which *is* zone-aware and
   picks up Flutter's fake test clock automatically — the same integration point
   `package:fake_async` (which underlies `flutter_test`) is designed around.

All three were caught by actually running `flutter test test/features/workout/rest_timer_test.dart`
after each change, not assumed correct from reading the diff.

## P1.10 — Dashboard integration: replaced fixture-only workout/streak data with real data

`HomeDashboardScreen` previously rendered *only* `DashboardFixture` sample data for everything,
including "Today's Workout" (a hardcoded title) and "Streak" (a hardcoded number) — despite a
complete, working Workout Engine already existing to answer both questions for real. This was a
named P1 acceptance criterion ("dashboard uses real workout data").

Changes (`apps/mobile/lib/features/dashboard/presentation/screens/home_dashboard_screen.dart`):
- New `_WorkoutStatusCard`, driven entirely by `workoutSessionControllerProvider` and
  `workoutHistoryListProvider` (both pre-existing providers, no new backend calls needed): shows
  "Workout in progress"/"Workout paused" with a Resume action when a session is active (mirrors
  the same banner already used on the Workout tab), otherwise the most recently completed
  real workout with a relative date, otherwise an honest "No workouts yet" empty state — never
  fixture data.
- **Streak** now comes from a new pure function, `computeWorkoutStreak()`
  (`apps/mobile/lib/features/dashboard/domain/workout_streak.dart`): consecutive calendar days
  with a completed session, counted backward from today, staying "alive" through today even
  before today's workout is logged (so the streak doesn't flicker to 0 at midnight-minus-a-workout).
  Replaces `DashboardFixture.sample().streakDays` (a hardcoded `4`) in the UI.
- New "New personal record" card (only rendered when `personalRecordsProvider` has data) showing
  the most recently achieved record, linking to the Personal Records screen.
- The remaining fixture-backed cards (Recovery, Protein, Hydration, Steps, Sleep) are untouched
  functionally but their "Sample data" label was made more specific ("Nutrition, sleep & recovery
  — sample data") now that the workout/streak/PR sections sitting right next to them are real —
  leaving the old blanket label would have made the real sections look like sample data too.

New tests: `test/features/dashboard/workout_streak_test.dart` (7 cases covering the pure
streak function: zero/today/yesterday-still-alive/consecutive-run/gap-stops-the-count/
same-day-counted-once). `test/features/dashboard/home_dashboard_test.dart` was rewritten (1 test
-> 6 tests): last-real-workout display, honest empty state, streak sourced from real data (not
the fixture's `4`), personal-record card, and the active-session Resume state.

## Verification after P1.9 (rest timer) + P1.10 (dashboard)

```
$ flutter pub get                -> PASSED (added `clock: ^1.1.1` as a direct dependency)
$ flutter analyze                -> PASSED — "No issues found!"
$ dart format --set-exit-if-changed .  -> PASSED after applying formatting
$ flutter test                   -> PASSED, 45/45 tests (was 33; +2 rest-timer fix coverage
                                     already counted, +7 workout-streak unit tests, +5 net on
                                     dashboard tests [1 replaced by 6])
```

## Not implemented this session (real, honest gaps)

Time ran out before these could be done properly — listed here rather than silently skipped:
- **Exercise substitution during an active session** (P1's capability #10 / P1.9). The backend
  already supports logging a set against any valid exercise id, so this is purely a Flutter-side
  gap: the workout player has no UI to swap the current exercise for one of its `alternatives`
  mid-session. `Exercise.alternatives` (bidirectional) and 19 alternative pairs already exist in
  the catalog to support this once built.
- **Custom plan editor** (build a `WorkoutPlan` from scratch in the UI, not just "start from a
  catalog `Workout`"). The backend already accepts an explicit `exercises` array in
  `POST /workout-plans` (see `CreateWorkoutPlanDto`'s `@ValidateIf`), so this is also purely a
  Flutter UI gap.
- **User-reported effort (RPE/RIR) input**, feeding into progression suggestions as the spec
  mentions. The existing deterministic progression rules work without it; adding it would touch
  the `WorkoutSet` schema, the set-logging UI, and `suggestNext()`'s rule set together.
- **Idempotency keys formalized as a table/DTO field** for offline sync. The existing design
  already gets safe retries a different way (see `architecture.md`'s "Offline and synchronization
  strategy": local Drift is the source of truth, and the replay-or-push reconciliation at
  finish/retry is naturally idempotent per session since it always checks `serverId`/`set.isSynced`
  before pushing) — but there's no explicit `WorkoutSyncOperation` table or client-generated
  idempotency key on `POST /workout-sessions/:id/sets`, so a literal duplicate network request
  (not just a retry from the same client state) could in principle double-log a set. This is a
  real gap worth closing with a proper idempotency-key column if multi-device or genuinely
  unreliable networks become a priority.
- **P2 (Nutrition Tracking foundation)**: not started. All available time went to closing real P1
  gaps; per the operating rules, P2 should not begin while P1 gaps remain open, and several
  genuine ones are listed above.
