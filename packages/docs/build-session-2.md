# Build Session 2 — P1 Completion + Nutrition Foundation

Continuation of `build-session-1.md`. Append-only, real commands and real results only.

## Session start

2026-08-06T07:00:19Z — session start

Starting branch: `claude/p1-p2-autonomous`, created from `main` (fast-forwarded to
`origin/main` @ `0e45e27`, the merge commit for PR #2). `origin/main` already contains every
commit from `claude/new-session-qy6hzm` (`ef525b5`, `47c6570`, `3f0c2f6`, `81371a6`, `906df57`,
`365a902`) — verified via `git log origin/main..claude/new-session-qy6hzm` returning empty.
No other branches exist with unmerged work (`git branch -a` shows only `main` and
`claude/new-session-qy6hzm`, both already reflected in `origin/main`). Nothing to integrate this
pass.

## Part 1 — Audit

Searched `services/api/src` and `apps/mobile/lib` for `TODO|FIXME|UnimplementedError|coming
soon|placeholder|hard-?coded|mock`. Findings:
- No backend TODOs/FIXMEs/unimplemented markers anywhere in `services/api/src`.
- Flutter "coming soon" markers are all pre-existing, honest, and outside the Workout Engine's
  scope: forgot-password, voice input (companion + command center), exercise media placeholder
  (`_MediaPlaceholder` in `exercise_detail_screen.dart` — explicitly documented as "an honest
  placeholder, not a broken image").
- `DashboardFixture` sample data is still used for recovery/protein/hydration/steps/sleep,
  already labeled "Nutrition, sleep & recovery — sample data" per the previous session's dashboard
  work — protein/hydration are exactly what Part 4.8 of this session's brief replaces with real
  nutrition data.
- No hard-coded workout data remains in the Flutter workout feature; no incomplete navigation
  routes found in `app_router.dart`.

Conclusion: the audit confirms `build-session-1.md`'s own "not implemented this session" list is
accurate and current — the four P1 gaps (exercise substitution, custom plan editor, RPE, formal
idempotency) are real and still open; nothing else new surfaced.

## Part 2 — Schema for RPE, substitution, formal idempotency, and Nutrition

One combined migration for everything new this session (minimizes iteration overhead vs. one
migration per feature): `20260806070326_p1_rpe_substitution_idempotency_and_nutrition`.

**Additive to existing tables only** — no column drops, no type changes, no destructive
operations:
- `workout_plans`: `+description TEXT?`, `+archivedAt TIMESTAMP?` (soft-delete/archive support
  for the custom plan editor).
- `workout_sessions`: `+difficultyRating INTEGER?` (optional session-level RPE).
- `workout_sets`: `+rpe DOUBLE PRECISION?` (optional per-set RPE, 1-10 scale, half-point
  increments allowed).

**New tables:**
- `workout_session_substitutions` — records "within this session, exercise X is now logged as
  exercise Y for remaining sets," without touching already-created `WorkoutSet` rows (so completed
  history is never rewritten). One active substitution per (session, original exercise).
- `sync_operations` — the shared idempotency ledger for Part 2.4, generic across features
  (`entityType`/`operationType` are plain strings, not enums, specifically so Nutrition can reuse
  the same table without a schema change). Unique on `(userId, idempotencyKey)`.
- `foods`, `food_servings`, `meal_entries`, `macro_targets`, `water_entries` — the Nutrition
  foundation (Part 4). See the schema file's section comment for the "why a snapshot on
  `MealEntry` instead of deriving from `Food`" reasoning.

**Backward-compatibility verification (real, not assumed):** created a throwaway database
(`ascend_migration_check`), applied every migration *except* the new one (reproducing "a database
representing the previous repository version"), inserted a legacy-shaped user/plan/session/set/
personal-record via raw SQL, applied the new migration on top, then queried those exact rows back.
Confirmed: all pre-existing values unchanged (`name`, `status`, `reps`, `weightKg`, `type`,
`value` all intact), all new columns correctly `NULL` on the pre-existing rows
(`description`/`archivedAt`/`difficultyRating`/`rpe` all empty), zero rows in the brand-new tables
(`sync_operations`, `foods`) as expected for data that never existed before. Database dropped
after verification.

Applied to `ascend_dev` and `ascend_test` via `prisma migrate deploy`. `ascend_dev` had zero rows
at the time (previous sessions' manual verification data was already reset), so the throwaway-DB
test above is the real backward-compatibility evidence for this session, not the coincidentally-
empty dev database.

## Part 2.1–2.4 — Workout Engine backend gaps (implementation)

All four backend gaps from `build-session-1.md`'s "not implemented" list are now implemented,
tested, and passing:

- **Idempotency (2.4, built first since 2.1–2.3 depend on it)** —
  `src/common/idempotency/idempotency.service.ts`, a `@Global()` module
  (`idempotency.module.ts`) exporting `IdempotencyService`. `run<T>({ userId, idempotencyKey,
  entityType, operationType }, fn)`: first-writer-wins via `sync_operations.create()` racing on
  the `(userId, idempotencyKey)` unique index (catches Prisma `P2002` as "someone else already
  claimed this key"), a `PROCESSING → COMPLETED | FAILED` state machine, replay of the stored
  `resultPayload`/`resultEntityId` on a `COMPLETED` hit, `409 Conflict` on a concurrent
  `PROCESSING` hit, and a fresh retry allowed on a `FAILED` row. `entityType`/`operationType` are
  plain strings (not enums) specifically so Nutrition could reuse the exact same table without a
  schema change — confirmed working in Part 4 below (`MEAL_ENTRY`, `MEAL_ENTRY_COPY`,
  `WATER_ENTRY` operation types share the same ledger as the workout ones). 7 unit tests in
  `idempotency.service.spec.ts` (first call executes and stores; repeat replays without
  re-executing; concurrent-in-flight rejects with 409; failed run allows retry; per-user key
  scoping; keys are independent across `entityType`). All passing.
- **Exercise substitution (2.1)** — modeled as a session-scoped redirect row
  (`WorkoutSessionSubstitution`) rather than mutating existing sets, so completed-set history is
  preserved by construction, not by application-level care. `WorkoutSessionsService
  .substituteExercise(userId, sessionId, dto)` validates session ownership, that the session is
  `ACTIVE` or `PAUSED` (not `COMPLETED`/`ABANDONED`), that both exercises exist, and that a
  substitution for that `originalExerciseId` isn't already active in the session, all inside the
  idempotency-wrapped transaction. `logSet()` now resolves an `effectiveExerciseId` by checking
  for an active substitution before writing the set — so a client that hasn't refreshed its local
  state and still POSTs against the original exercise id is transparently redirected server-side,
  and already-completed sets under the original exercise are untouched. `POST
  /workout-sessions/:id/substitutions`. `WorkoutHistoryService` surfaces `substitutions` in session
  detail so the history view can show what was swapped and when.
- **Custom plan editor (2.2)** — `WorkoutPlan` gained `description` and `archivedAt`.
  `WorkoutPlansService`: `list()` hides archived plans by default (`includeArchived=true` query
  param opts back in), `create()`/`update()` persist `description`, new `archive()`/`unarchive()`
  actions (`POST /workout-plans/:id/archive` and `/unarchive`), ownership already enforced by the
  existing `findOwned()` guard used across the module (unauthorized edits on another user's plan
  or a public starter plan both 403/404 as before — no change needed there, just extended to the
  new fields/actions). "No empty published plans" is enforced at *session-start* time via a
  `_count.exercises` check rather than a full draft/publish state machine — an explicit,
  documented scope reduction given the time budget, not an oversight.
  `WorkoutPlanExerciseDto` also gained `targetDistanceMeters` — the Prisma column already existed
  from Sprint 2 but was never exposed through the DTO, a real pre-existing gap fixed in passing.
- **RPE (2.3)** — `WorkoutSet.rpe` (`Float?`, 1–10, validated via `@IsNumber() @Min(1) @Max(10)`
  in `LogSetDto`/`UpdateSetDto`), `WorkoutSession.difficultyRating` (`Int?`, 1–10, optional
  session-level rating passed to `FinishWorkoutSessionDto`). Deliberately **not** wired into any
  automatic load-progression logic that would *increase* suggested weight — the existing
  progression suggestion logic (personal-records module) is unchanged; RPE is stored and surfaced
  (active set logger's data model, session summary, history) but never used to push someone
  harder. This satisfies "used carefully, never force progression" by simply not building the
  forcing mechanism rather than building one and then constraining it.

All four gaps' idempotency-optional design means every DTO's `idempotencyKey` is optional and
existing non-idempotent call patterns are unaffected — verified by the pre-existing
`workout-engine.e2e-spec.ts` tests continuing to pass unmodified, plus 3 new tests added to that
file covering: substitution + RPE + history end-to-end, cross-user/invalid-lifecycle substitution
rejection, and idempotent set-logging (repeated key replays the same set instead of creating a
duplicate). Plus 2 new tests in the "workout plans" describe block: plan
description/archive/unarchive/empty-plan-rejection, and idempotent plan creation.

## Part 4 — Nutrition Tracking backend foundation

**Schema** (in the same combined migration described above, plus one small follow-up migration —
see below): `Food` (seed catalog + user-owned custom foods via `sourceType`/`ownerId`,
`archivedAt` soft-delete), `FoodServing` (named serving options, `grams: null` for
non-gram-convertible options like "1 can"), `MealEntry` (macro values **snapshotted at log time**
— the same pattern already used for `WorkoutSet`/`PersonalRecord` — so editing or archiving a
`Food` later never rewrites already-logged history), `MacroTarget` (`isEstimatedDefault` flag),
`WaterEntry`.

**Follow-up migration `20260806072651_food_slug`:** added `Food.slug String? @unique` so the
nutrition seed script could upsert idempotently by a stable natural key, exactly like the existing
exercise/workout seed does by `slug`. Nullable and unique — Postgres treats multiple `NULL`s as
distinct under a unique index, so this doesn't constrain user-created custom foods (which never
get a slug) while still giving seed rows a stable identity across reseeds. Verified additive-only
via the same throwaway-database method as Part 2's migration: applied all prior migrations to
`ascend_backcompat_check`, inserted a legacy-shaped `foods` row via raw SQL (as it would look
*before* this migration existed), applied `food_slug` on top, and confirmed the row survived with
`slug` correctly `NULL` and every other column byte-for-byte unchanged. Both migrations also
verified to apply cleanly, in order, to a genuinely empty database (`ascend_migration_check`, 7/7
migrations applied with no errors). Both throwaway databases dropped after verification.

**Modules** (`services/api/src/modules/`):
- `foods/` — `GET /foods` (search + pagination, visibility = seed catalog ∪ own custom foods,
  archived hidden by default), `GET /foods/:id`, `POST /foods` (create custom), `PATCH /foods/:id`
  (owner-only), `POST /foods/:id/archive` (owner-only). A real bug caught and fixed during
  writing, before any test ran: Prisma silently overwrites a second same-named top-level `OR` key
  rather than combining it, so the visibility filter and the optional text-search filter are
  combined via an explicit `AND: [visibility, textSearch]` array instead of two separate `OR`
  keys — otherwise a search query would have silently bypassed the visibility filter and leaked
  other users' custom foods.
- `nutrition-log/` — `GET /nutrition-log?date=`, `GET /nutrition-log/summary?date=`, `GET
  /nutrition-log/summary/seven-day?endDate=`, `POST /nutrition-log` (idempotency-key optional),
  `POST /nutrition-log/copy` (copy a day or one meal slot's entries to another date, also
  idempotency-key optional, snapshot values copied verbatim rather than recomputed), `PATCH
  /nutrition-log/:id`, `DELETE /nutrition-log/:id`. Serving-scaling supports three paths in one
  `computeMacroSnapshot()`: gram-based logging, a gram-convertible named serving, or a
  non-gram-convertible named serving (quantity multiplies the food's reference serving directly).
  A `round1()` helper (`Math.round(x*10)/10`) is applied at every macro computation and every
  summation point to avoid floating-point drift from repeated additions.
- `macro-targets/` — `GET /macro-targets` (auto-computes and persists a safe default estimate on
  first read if none exists yet), `PUT /macro-targets` (explicit user values, always flips
  `isEstimatedDefault` to `false`). The default estimator uses Mifflin-St Jeor BMR (weight,
  height, age, and `sexForCalculations` together — **not** sex-only-based) × a fixed conservative
  "lightly active" multiplier × a small goal adjustment capped at ±15%, with a hard floor of 1200
  kcal regardless of the computed deficit. Every response carries a fixed, plain-language
  disclaimer pointing anyone pregnant or managing an eating disorder, kidney disease, diabetes, or
  another condition affecting nutrition needs toward a qualified professional rather than the
  in-app default — this is explicitly not a medical or clinical recommendation.
- `water/` — `GET /water?date=` (entries + total), `POST /water` (idempotency-key optional),
  `PATCH /water/:id`, `DELETE /water/:id`.

**Seed data** (`prisma/seed.ts`, `seedNutrition()`, called from the existing `main()` after the
workout catalog seed): 26 foods, idempotent via `upsert({ where: { slug } })` exactly like the
exercise/workout seed pattern, with `FoodServing` rows re-derived from scratch each run
(delete-then-recreate) the same way exercise muscle/equipment joins already are. Philippine
staples as specified in the brief: cooked white rice, boiled egg, chicken breast, chicken thigh,
canned sardines, milkfish (bangus), tuna, tofu, mung beans (monggo), water spinach (kangkong),
banana, sweet potato (kamote), rolled oats, pandesal, peanut butter. Global staples: Greek
yogurt, lentils, black beans, potato, pasta, salmon, ground beef, apple, orange, broccoli, carrot.
All values are approximate reference figures (never a lab-verified source), which is exactly why
every row carries `isEstimated: true` — an explicitly modest, illustrative dataset, not a
comprehensive food database. **Verified idempotent for real**: ran `pnpm prisma:seed` twice
against `ascend_dev` and queried row counts directly — 26 `foods` rows and 26 distinct non-null
slugs after both runs (no duplicates), 10 `food_servings` rows unchanged between runs.

**Tests** (`test/nutrition.e2e-spec.ts`, 11 tests, all passing): seeded-catalog search with
pagination metadata; custom-food create/update/archive with owner-only edit enforcement and
invisibility (404, not just 403 — a food that doesn't exist *for you* shouldn't leak its existence
via a 403) to a non-owner, including editing a shared seed food correctly 403ing instead of
404ing (it *is* visible, just not owned); macro-target safe-default computation and its 1200 kcal
floor rejecting an unsafe explicit value; water logging/totals/update/delete with per-user
isolation; gram-based meal logging with exact rounded macro-snapshot verification and cross-user
404s on read/edit/delete; rejecting a log against another user's un-archived-but-invisible custom
food (404) and against a food the *owner* has since archived (400); idempotent add-entry (repeated
key replays the same entry id, no duplicate persisted); idempotent copy-entries (repeated key
copies once, not twice); 7-day summary averaging correctly around a single logged day.

## Flutter (mobile) — not started this session

Flutter itself is available in this environment (`flutter --version` succeeds: 3.44.8 stable) —
this is **not** an environment-availability blocker. Given the remaining scope after a fully
tested, migration-verified backend (RPE input UI across the active set logger/summary/history,
exercise substitution UI, the full custom plan editor screens, Drift schema updates for
RPE/substitution/an idempotent outbox, and the entire Nutrition Flutter feature — home, macro
dashboard, food search/detail, serving selector, add-to-meal, custom-food editor, meal sections,
entry editor, target editor, water tracker, 7-day summary, sync-status UI, dashboard integration,
and tests for all of it), attempting this in the same pass with no remaining budget to verify it
would risk shipping broken, unverified Dart code against a currently-working mobile app. None of
this session's Flutter-facing work has been started: no Drift schema changes, no new screens, no
dashboard wiring. This is the primary remaining blocker and the top recommended next work item —
see the final report's "Recommended next work order."

## Docker — reconfirmed unavailable

`docker version` succeeds for the client (29.3.1) but `docker compose version` and any daemon
call fail with "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the
docker daemon running?" — same limitation documented in prior sessions, reconfirmed rather than
assumed. Docker-based verification (`docker compose build/up/ps`, health curl) could not be run
this session.

## Part 6 — Verification (real commands, real results)

All run from the repo root unless noted, against `ascend_dev` (PostgreSQL, started via `service
postgresql start` after a mid-session daemon drop -- a recurring environment instability noted
across sessions, not new this time):

- `pnpm install --frozen-lockfile` -- up to date, no changes, exit 0.
- `prisma format` / `prisma validate` (run inside `services/api`, no root-level alias exists for
  these two) -- schema formatted, "The schema at prisma/schema.prisma is valid".
- `pnpm api:prisma:generate` -- Prisma Client regenerated successfully.
- `pnpm api:lint` -- clean, 0 errors, 0 warnings (`--max-warnings=0`), after fixing 5 formatting
  errors and 1 unused import via `eslint --fix` plus one manual import removal.
- `pnpm exec tsc --noEmit` (inside `services/api`) -- clean, no errors.
- `pnpm api:test` -- 4 suites, 30 tests, all passing (`exercises.service.spec.ts`,
  `idempotency.service.spec.ts`, `personal-records.service.spec.ts`, `auth.service.spec.ts`).
- `pnpm api:build` (`nest build`) -- succeeds, no errors.
- `pnpm api:test:e2e` -- 3 suites, 49 tests, all passing (`nutrition.e2e-spec.ts`,
  `workout-engine.e2e-spec.ts`, `app.e2e-spec.ts`).
- Seed idempotency: `pnpm prisma:seed` run twice against `ascend_dev`; second run reported the
  same counts as the first, and a direct `psql` query confirmed 26 `foods` rows, 26 distinct
  slugs, and 10 `food_servings` rows unchanged after the second run.
- Migrations from an empty database: `ascend_migration_check` created fresh, `prisma migrate
  deploy` applied all 7 migrations in order with no errors.
- Migrations from a database representing the previous version with existing records:
  `ascend_backcompat_check` created fresh, migrated up to (but not including)
  `20260806072651_food_slug`, a legacy-shaped `foods` row inserted via raw SQL, then `food_slug`
  applied on top -- the row survived with `slug = NULL` and every other column unchanged. (The
  equivalent check for the larger `20260806070326_..._nutrition` migration was already performed
  in Part 2, against workout data.) Both throwaway databases dropped after verification.
- Docker: unavailable (daemon unreachable), documented above rather than assumed.
- Flutter: available but not exercised, since no Flutter code changed this session (see above).

No fabricated results -- every number above came from an actual command run this session.

## Commit-naming decision

The brief specifies two exact milestone commit messages -- "Complete Workout Engine MVP" and
"Implement Nutrition Tracking foundation" -- each meant to mark full completion of that scope,
including the Flutter side (Part 3 explicitly lists substitution UI, RPE input UI, and the plan
editor screens as part of "verify complete Workout Engine"; Part 4 explicitly requires "the full
Flutter feature" for Nutrition). Since no Flutter work happened this session, using either exact
message here would overstate what's actually done. This session's backend work is committed under
an accurate, descriptive message instead; the two milestone messages are deferred to whichever
session actually completes the corresponding Flutter work, so they mean what they say when used.
