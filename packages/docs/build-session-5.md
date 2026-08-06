# Build Session 5 — Core Data and Wearable Foundation

Continues directly from `main` at commit `4bbd260` (Build Session 4). Branch:
`claude/new-session-qy6hzm`. Nothing from Session 4 was regenerated or
replaced — every change here is additive on top of it.

This document is written incrementally as each subsystem in the session's
priority order is completed and committed. See the top of each section for
its own commit hash once merged.

---

## Part 1 — Offline-first Nutrition

### Design decision: local-first, not Workout's network-first-with-fallback

Workout's existing offline pattern (`WorkoutPlanEditorService`) is
"try the network call now; only fall back to the outbox on a
`NETWORK_ERROR`." That's a valid pattern, but it isn't literally
*local-first* — a plan created offline never appears in "My Plans" until
it syncs (a documented scope cut from Session 2.5).

The Session 5 directive is explicit that Nutrition must "write to Drift
first; update UI immediately; enqueue a sync operation" — so Nutrition's
mutations always do, in order: (1) write to the local Drift cache, (2)
update in-memory state immediately (an entry appears in the list the
instant you tap "Log it," online or offline), (3) call
`SyncEngine.enqueue(...)`. Because `SyncEngine.enqueue` already attempts an
immediate `drain()` internally, this single code path gives the "syncs
right away when online" feel without a separate "are we online" branch —
online and offline are the same code path, just different outcomes for
step 3.

The one exception is `MealEntryController.copyEntries` (copying a day's
meals), which genuinely can't be computed offline — the source day's
entries may not be cached locally, and the backend's `/nutrition-log/copy`
endpoint recomputes the copy server-side. That one mutation intentionally
keeps Workout's network-first-with-fallback shape, with an honest "queued,
not confirmed" message when offline. Logging a *saved* meal
(`SavedMealController.logMeal`) is the other partial exception: the
resulting entries' calories are a server-side computation this app never
fabricates client-side (see `wellness-ethics-bible.md`'s "no fabricated
values" rule), so a queued log doesn't materialize placeholder entries —
they appear once the sync actually lands.

### Reused, not rebuilt: the shared outbox

Every Nutrition mutation goes through the exact same `apps/mobile/lib/core/sync/`
(`OutboxStore`, `SyncEngine`, `OutboxEntryRows`, `FunctionSyncHandler`,
`SyncStatusIndicator`) that Workout already uses — nothing in `core/sync/`
was changed. Handlers are registered per Nutrition entity type
(`nutrition.meal_entry.create/update/delete/copy`,
`nutrition.water_entry.create/update/delete`,
`nutrition.saved_meal.create/update/delete/log`,
`nutrition.food.create/update/archive`,
`nutrition.macro_target.upsert`), following the exact registration pattern
`WorkoutPlanEditorService` and `WorkoutSessionController` already
established. The `SyncStatusIndicator` widget (already generic, already
built) is dropped directly into `MealPrepScreen` — no new indicator
widget needed.

Every sync handler wraps its repository call in `try { ... } on
AppException catch (e) { throw SyncFailure(...) }`, converting the
repository's error shape into the one `SyncEngine` understands.

### Drift schema (version 4 → 5, forward-only)

New tables (`apps/mobile/lib/core/storage/tables/nutrition_tables.dart`):
`CachedFoods`, `CachedFoodServings`, `CachedMealEntries`,
`CachedSavedMeals`, `CachedWaterEntries`, `CachedMacroTargets`. All six are
purely additive `createTable` migrations under `if (from < 5)` — no
existing table touched, no data at risk for any user already on schema 4.

Row shape follows the same "local id is permanent, `serverId` tracks the
backend's id separately" pattern used everywhere:
- `id` is the row's local primary key forever — generated once (via
  `generateIdempotencyKey`) and never changed. It doubles as the outbox
  entry's id for that row's create, so a retry (or an app restart before
  the first attempt lands) can never create two server-side rows.
- `serverId` is null until the create syncs, then holds the backend's id.
- `syncStatus` is one of `'synced' | 'pendingCreate' | 'pendingUpdate' |
  'pendingDelete'`.
- `'pendingDelete'` is the tombstone: every read query
  (`watchMealEntries`, `watchWaterEntries`, `watchSavedMeals`) filters it
  out, so a delete is invisible immediately even before the network
  confirms it. The row is only actually removed from Drift once the
  delete's outbox entry completes.

**Meal-entry macro snapshot, computed offline**: `CachedFoods` and
`CachedFoodServings` exist specifically so a food's per-serving macros are
available client-side. `nutrition_macro_math.dart`'s
`computeMacroSnapshot()` mirrors
`NutritionLogService.computeMacroSnapshot()`'s exact multiplier logic
(server-side, in TypeScript) so a meal entry logged offline shows real
calories immediately — not a placeholder — using the same math the server
will later confirm.

**A real Drift gotcha hit and fixed while building this**: calling
`.watch().first` for a one-shot read on a query that already has an
active, separate `.watch().listen(...)` subscription elsewhere stalls
indefinitely rather than resolving with the current snapshot (confirmed by
direct reproduction — a widget test's `_refreshFromServer()` call never
returned). Every one-shot read in `AppDatabase` (`readMealEntriesOnce`,
`readWaterEntriesOnce`, `readSavedMealsOnce`, `readCachedFoodsOnce`,
`readMacroTargetOnce`) is a plain `SimpleSelectStatement.get()` built from
a shared private query builder, never `.watch().first`.

### Local-to-server ID reconciliation

`AppDatabase.reconcileFoodId(localId, serverId)` is the concrete mechanism
the directive's "local-to-server ID reconciliation" test requirement
covers: when a custom food created offline finally syncs, its local id is
followed through to (a) the `CachedFoods` row itself, (b) any
`CachedMealEntries.foodId` pointing at it, and (c) any `CachedSavedMeals`
item (stored as JSON) referencing it — so a food created offline and
immediately logged offline never leaves a dangling reference to an id the
backend has never heard of.

### Cross-user isolation

Every new cache table carries `userId`, and all reads/writes are scoped by
it — the same defense-in-depth precedent `WorkoutSessionController._restore()`
already applies to the cached workout session (checking `session.userId ==
_userId` even though `clearAll()` on sign-out should have already cleared
it). `AppDatabase.clearAll()` (already called on sign-out) was extended to
wipe all six new tables, so logging out with pending Nutrition operations
discards them the same way a pending workout sync is discarded today. The
generic `OutboxEntryRows` table itself was deliberately left unchanged (no
`userId` column added) — it's wiped wholesale by the same `clearAll()`
call, and adding per-row user scoping to the shared, Workout-owned outbox
schema was out of scope for "extend, don't rebuild."

### Backend changes (all additive, no Prisma migration required)

- `CreateFoodDto` / `FoodsService.createCustom` and `CreateSavedMealDto` /
  `SavedMealsService.create` gained an optional `idempotencyKey`, wrapped
  in the existing shared `IdempotencyService` — the same ledger Workout,
  Nutrition's meal-log/copy, Cardio, and Water already use. No second
  idempotency mechanism.
- `SavedMealsService` gained `update()` (`PATCH /saved-meals/:id`,
  replacing the name and/or full item list) — the one true gap: the
  directive requires "saved-meal ... editing" and no update endpoint
  existed at all before this session.
- `MealEntryRepository.updateEntry` / `WaterRepository.updateEntry` /
  `SavedMealRepository.update` / `FoodRepository.updateCustom` /
  `FoodRepository.archiveCustom` were added on the Flutter side to reach
  endpoints (`PATCH /nutrition-log/:id`, `PATCH /water/:id`, `PATCH
  /foods/:id`, `POST /foods/:id/archive`) that already existed on the
  backend but weren't exposed to the app yet.

### Tests

**Backend** (Jest): 3 new unit tests in `saved-meals.service.spec.ts`
(idempotent create, update replaces name/items, update rejects a
non-owner) plus 2 new e2e assertions in `nutrition.e2e-spec.ts` (a full
saved-meals lifecycle — create, idempotent-key replay, list, update,
cross-user 403s, log, delete — and a custom-food idempotent-create
replay).

**Flutter**: `test/features/nutrition/nutrition_offline_sync_test.dart`
covers the directive's exact required list, each directly against
`MealEntryController`/`WaterController`/`CustomFoodController` +
`AppDatabase` + `SyncEngine` (no widget pumping needed — faster and more
deterministic than driving it through the UI):
- offline meal creation (writes to Drift, appears in state, before any
  network attempt)
- offline water logging (logs locally, then a manual retry lands it once
  "back online")
- restart before sync (writes to a real on-disk sqlite file via
  `NativeDatabase(File(...))`, closes the database, reopens a second
  `AppDatabase`/`SyncEngine`/`WaterController` against the same file —
  the pending row and its outbox entry both survive, and a fresh
  controller's handler registration can still resume and complete the
  sync)
- timeout then retry (a failed attempt backs off; a manual retry while
  still offline fails again without duplicating; connectivity returns and
  the next retry succeeds)
- duplicate batch delivery (draining an already-`completed` outbox entry
  a second and third time never re-invokes its handler — verified via the
  repository's own call count)
- delete while offline (deleting a never-synced entry removes it locally
  and discards its outbox entry outright — zero network calls)
- logout with pending operations (`AppDatabase.clearAll()` wipes both the
  outbox and the cached rows)
- switching accounts (two controllers for two different `userId`s sharing
  one `AppDatabase` never see each other's rows)
- local-to-server ID reconciliation (two tests: an end-to-end offline
  food-create → sync → meal-entry-log flow, and a direct test of
  `reconcileFoodId` rewriting an already-cached meal entry's `foodId`)

### Commands run and results

Backend (from repo root):
```
pnpm install --frozen-lockfile        # up to date
npx prisma format && npx prisma validate   # both clean; api:prisma:format /
                                            # api:prisma:validate are not
                                            # defined package.json scripts in
                                            # this repo (only
                                            # api:prisma:generate/migrate
                                            # are) — ran the equivalent
                                            # Prisma CLI commands directly
pnpm api:prisma:generate               # OK
pnpm api:lint                          # clean (0 errors after eslint --fix
                                        # resolved 6 prettier formatting
                                        # issues in the new files)
pnpm api:test                          # 16 suites, 156 tests passed (was
                                        # 153 at the end of Session 4)
pnpm api:build                         # OK
pnpm api:test:e2e                      # 4 suites, 56 tests passed (was 54)
```

Flutter (from `apps/mobile`):
```
flutter pub get                                    # OK
dart run build_runner build                        # regenerated
                                                     # app_database.g.dart
                                                     # for schema v5
dart format --output=none --set-exit-if-changed .   # clean
flutter analyze                                     # no issues
flutter test                                        # 178 tests passed
                                                      # (was 168 at the end
                                                      # of Session 4; +10
                                                      # new offline-sync
                                                      # tests)
```

Android/iOS platform compilation was not attempted for this part — no
platform-specific code was touched (pure Dart/Drift + TypeScript), so
there's nothing new to gate on it. See the Platform Limitations section at
the end of this document for the environment's actual platform-tooling
availability, checked once for the whole session.

### Known scope decisions / honest limitations

- Meal copying and saved-meal logging are documented exceptions to
  "local-first" for the reasons above (can't compute the server-authoritative
  result offline without either duplicating backend logic or fabricating
  numbers) — see their doc comments in `meal_entry_controller.dart` and
  `saved_meal_controller.dart`.
- There is no dedicated "edit a logged meal entry" or "edit a water entry"
  screen in the UI yet (there wasn't one before this session either) —
  `MealEntryController.updateEntry` / `WaterController.updateEntry` exist
  and are exercised by tests, ready for a future screen, but aren't wired
  to a button yet. This matches the existing UI's scope, not a regression.
- `OutboxEntryRows` (the shared, Workout-owned outbox table) was not given
  a `userId` column — cross-user isolation for it relies on the existing
  `clearAll()`-on-sign-out behavior rather than per-row filtering. If a
  future "switch accounts without signing out" flow is ever added, this
  would need revisiting.
