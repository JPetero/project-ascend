# Build Session 3 — Product Alignment and Nutrition Build

Continuation of `build-session-2.md`. Append-only, real commands and real results only.

## Session start

Starting branch: `claude/product-alignment-nutrition`, created from `main` @ `75b6b8f`
("Workout Engine Production Ready" — the final commit of Session 2.5, already merged and
pushed). `git fetch --all --prune` confirmed no other unmerged branches existed. Working tree
was clean at session start; no uncommitted work to checkpoint.

Docker was unavailable in this sandbox (`docker ps` → "Cannot connect to the Docker daemon").
A local, non-containerized PostgreSQL 16 install was available at `localhost:5432` (started via
`service postgresql start`) and used for every migration/seed verification below instead.

## Part 1 — Product Bible documents

Created `packages/docs/product/`: `founder-vision-bible.md`, `user-scenario-bible.md`,
`atlas-nova-bible.md`, `design-bible.md`, `engineering-bible.md`, `wellness-ethics-bible.md`,
`parking-lot.md`, `free-premium-policy.md`. Added a pointer to these from `README.md` and
`CONTRIBUTING.md`. Committed as `ca689f2` ("Add Project Ascend product Bible documents").

These are the authoritative source for every product decision made in the rest of this session —
citations below (`user-scenario-bible.md Scenario N`, etc.) point back to them.

## Part 3/5/6 — Navigation, Dashboard, and Workout Engine scenario alignment

Commit `89d87f4` ("Align onboarding, dashboard, and Workout Engine with Founder scenarios").

**Navigation migration.** `RoutePaths`, `app_shell.dart`, and `app_router.dart` moved from the
old five-tab set (Home/Workout/Ascend/Community/Profile) to the authoritative order from
`design-bible.md`: Workout, Meal Prep, Social, Assistant, Leaderboards. Profile/Dashboard is a
pushed route (`context.push(RoutePaths.dashboard)`) reached via a new `ProfileIconAction` in each
tab's `AppBar`, not a sixth tab — this gives correct back-button/system-back/gesture behavior for
free (GoRouter's normal pushed-route stack) without any custom back-handling code. Post-onboarding
redirect target changed from the removed `home` path to `workout`, the new first tab.
`CommunityScreen` (which rendered fabricated "Community member" sample posts even under an honest
label) was deleted and replaced by a real `SocialScreen` — an honest coming-soon state with no
simulated content. A new `LeaderboardsScreen` (same honest coming-soon pattern) fills the fifth
tab.

**Dashboard rebuild.** `DashboardScreen` merges the old `HomeDashboardScreen` (workout data) and
`ProfileScreen` (preferences/sign-out) into the single Part 5 spec: profile header, subscription
status (via the new capability model, see Part 8), companion + coaching style card with an editor
sheet, weekly workout-progress ring, a month calendar marking trained days, streak, most recent
PR, a BMI card with the required disclaimer, real protein/hydration rings, honest
unavailable-with-reason states for leaderboard rank / friends / photos (each naming the feature
that will replace it), settings, account sign-in-provider summary, and sign-out.
`HomeDashboardScreen`, `ProfileScreen`, `DashboardFixture`, `DashboardRepository`, and the
`CachedDashboardFixtures` Drift table were deleted outright rather than left dead — that table
existed solely to serve fabricated sample steps/sleep/recovery numbers, which
`design-bible.md`'s "never show fabricated ... values in production mode" rule forbids. Removing
it required a Drift schema bump (`schemaVersion` 3 → 4) with a `DROP TABLE IF EXISTS
cached_dashboard_fixtures` migration step — verified by running the app database through both a
fresh `onCreate` and the `onUpgrade` path from version 3.

**Backend scenario architecture** (Scenarios 1, 3, 6, 10 — see `user-scenario-bible.md` for full
requirements): one combined forward-only migration,
`20260806113251_product_alignment_scenarios`:
- `Preference.coachingStyle` (`CoachingStyle` enum: GENTLE/BALANCED/DIRECT/TOUGH/ATHLETE, default
  BALANCED) and `Preference.toneIntensity` (1–5, default 3) — independent of `companion`, per
  Scenario 6's "no style is 'for' a companion or a gender" rule.
- `AuthIdentity` (Scenario 2/3): `provider` + `providerSubject` unique pair, `providerEmail`,
  timestamps. Every existing user is backfilled with an `EMAIL` row keyed on their own id, so the
  lookup path is uniform once Google/Apple linking goes live. `AuthIdentitiesService` +
  read-only `GET /auth-identities/me` shipped; a POST /link endpoint is deliberately **not**
  exposed — accepting a client-supplied `providerSubject` without verifying it against the
  provider's own token first would let a caller claim any identity, and that verification only
  makes sense once real Google/Apple credentials exist (see `parking-lot.md`).
- `LegalDocument` + `LegalAcceptance` (Scenario 1): versioned documents, per-user acceptance
  records with optional region code, idempotent re-acceptance. `prisma/seed.ts` seeds a
  **product-safe draft** Terms of Service and Privacy Policy — explicitly labeled "NOT FINAL
  LEGAL COPY, requires professional legal review" both in the seed source and in the document
  content itself — covering the six required safety points (educational-only scope, professional
  care guidance, inconsistency warnings, stop-on-symptoms, user responsibility, no blanket
  harm-disclaimer language).
- `DeloadRecommendation` (Scenario 10): `DeloadService` computes a suggestion from
  `calculateConsecutiveActiveWeeks` (≥6 consecutive trained weeks) combined with recent (14-day)
  average RPE ≥8, both deterministic and computed from real `WorkoutSession`/`WorkoutSet` data —
  no sleep/recovery signal is used, since no real wearable data source exists yet and inventing
  one would violate the fabrication rule. At most one new suggestion per 14-day window
  (anti-nagging); dismiss/postpone endpoints; never auto-applied.

**Scenario 9** (workout completion, folded into a follow-up commit `2303d9b` after this milestone
initially shipped): `WorkoutSummaryScreen` now shows the same weekly planned-session completion
ring as the Dashboard (`completed sessions this week ÷ planned sessions this week × 100` —
extracted into a shared `isThisWeek`/`calculateCompletionPercentage` pair in
`core/progress/progress_util.dart` so the two screens can never drift into two different
unexplained percentages), plus a Meal Prep intro card and a Dashboard shortcut.

## Part 8 — Free/premium capability model

Commit `2a5bd63` ("Add centralized free/premium capability model").

`PlanTier` / `AppCapability` / `CapabilityService` on the backend
(`services/api/src/common/entitlements/`), mirrored in Flutter
(`apps/mobile/lib/core/entitlements/`). No billing exists this session — every account resolves
to `PlanTier.FREE` — but the full Free/Premium capability list from `free-premium-policy.md` is
encoded now, so gating decisions have exactly one place to live once billing ships instead of
scattered `isPremium` checks accumulating first. Tests assert every Free-list capability resolves
available on both tiers and every Premium-list capability is gated on Free. The Dashboard's
subscription card reads the same `planTierProvider` instead of a hardcoded string, as a real (not
decorative) usage of the new model.

## Part 7 — Meal Prep and Nutrition Tracking foundation

Commit `3644e3d` ("Implement Meal Prep and Nutrition Tracking foundation").

The backend Nutrition foundation (`foods`, `nutrition-log`, `water`, `macro-targets` modules) was
already built and merged in a prior session. This session built the Flutter layer on top of it:
`Food`/`FoodServing`/`MealEntry`/`WaterEntry` domain models, `FoodRepository` /
`MealEntryRepository` / `WaterRepository`, and three screens — `MealPrepScreen` (today's
calorie/protein summary, an interactive water tracker with +250ml/+500ml quick-add, and
breakfast/lunch/dinner/snack sections each showing real logged entries with delete), a
`FoodSearchScreen` (debounced search across the seed catalog and the user's own custom foods,
serving/quantity picker, log), and `CustomFoodEditorScreen` (create a user-owned food). Every
mutation (`addEntry`, water log, copy) passes an `idempotencyKey` generated by the existing
`core/sync/generateIdempotencyKey` helper into the same backend idempotency ledger the Workout
Engine already uses — no second mechanism was built. Saved meals, meal plans, and AI-generated
recommendations remain an honest coming-soon card rather than fabricated placeholder content.

**Known, deliberate scope reduction:** meal/water logging in this session is online-first (calls
the API directly), not queued through the Drift-backed offline outbox the Workout Engine uses for
session/set logging. Building full offline parity was judged lower priority than shipping the
core logging flow within this session's time; it's recorded in `parking-lot.md` as the next
Nutrition follow-up rather than silently left undone.

## Migration verification (this session's combined migration)

`20260806113251_product_alignment_scenarios` was verified twice, per Part 9's requirement:

1. **Fresh database** (`ascend_dev`, already at the pre-session migration state): `prisma migrate
   deploy` applied cleanly; `prisma migrate status` confirmed "up to date" afterward.
2. **Legacy-shaped database**: a throwaway `ascend_migration_check` database was created, the
   first 7 pre-session migrations applied, then a `users` row and a `preferences` row were
   inserted via raw SQL using the *pre-migration* column set (no `coachingStyle`/`toneIntensity`).
   `prisma migrate deploy` was then run to apply this session's migration on top. Verified: the
   legacy `preferences` row got `coachingStyle = BALANCED`, `toneIntensity = 3` (the declared
   defaults), and the legacy `users` row got exactly one backfilled `auth_identities` row
   (`provider = EMAIL`, `providerSubject` = the user's own id, `providerEmail` = their email).
   The throwaway database was dropped afterward.

The Flutter-side Drift migration (`schemaVersion` 3 → 4, dropping `cached_dashboard_fixtures`)
uses the same `onUpgrade`/`onCreate` pattern as the app's existing migrations; a fresh install
runs `onCreate` (never sees the dropped table) and an existing install runs the `DROP TABLE IF
EXISTS` step, which is safe to run even if the table was already absent.

The nutrition seed (`prisma/seed.ts`) was run twice in a row; counts (26 foods, 2 legal documents)
were identical both times, confirming the `upsert`-based seed stays idempotent with the new
`seedLegalDocuments` addition.

## Verification results

**Backend** (`services/api`):
- `pnpm install --frozen-lockfile` — clean.
- `npx prisma format` / `npx prisma validate` — schema valid.
- `pnpm api:prisma:generate` — clean.
- `pnpm api:lint` — clean, zero warnings (`--max-warnings=0`).
- `pnpm api:test` — **115/115 unit tests passing** (13 suites), up from 78 at session start.
- `pnpm api:build` — clean (`nest build`).
- `pnpm api:test:e2e` — **49/49 e2e tests passing** (3 suites), unchanged — no e2e regressions
  from this session's additive-only schema/route changes.

**Mobile** (`apps/mobile`):
- `flutter pub get` — clean.
- `dart format --output=none --set-exit-if-changed .` — clean, zero files needing changes.
- `flutter analyze` — **No issues found.**
- `flutter test` — **104/104 tests passing**, up from 57 at session start (net of the deleted
  `home_dashboard_test.dart`, whose target screen no longer exists, and several new suites:
  `bmi_test`, `progress_util_test`, `workout_calendar_test`, `workout_summary_screen_test`,
  `capability_test`, and the `features/nutrition/` suite).

**Docker**: unavailable in this sandbox (`docker ps` fails — no daemon). Not exercised this
session; `docker-compose.yml` was not modified, so no new risk was introduced there.

## Remaining blockers / not done this session

Recorded in `packages/docs/product/parking-lot.md`:
- Live Google/Apple OAuth (architecture and `AuthIdentity` linking model exist; no provider
  credentials configured).
- Offline queueing for Nutrition writes (currently online-first; Workout Engine's outbox pattern
  is the template for closing this gap).
- Saved meals / meal plans / AI-generated meal recommendations.
- Wearables depth, Community/Social, Leaderboards, subscriptions/payment processing, scanner
  features, voice input — none started this session, per the explicit "do not begin" list in the
  session brief.
- A macro-target editor screen (`RoutePaths.macroTargetEditor` is reserved but unbuilt this
  session — the backend `PUT /macro-targets` endpoint and a new `ApiClient.put` method both
  exist and are ready for it).
