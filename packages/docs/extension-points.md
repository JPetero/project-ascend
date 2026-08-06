# Extension points for Nutrition (and future Sleep / wearables) domains

This documents the shared infrastructure added to support Nutrition and
future domains (Sleep, wearables) without duplicating what Workout already
built. Nutrition's backend (Food/MealEntry/MacroTarget/WaterEntry, full
CRUD) already exists — see `build-session-2.md`. What follows describes the
*abstract, reusable* seams a domain plugs into, not a rebuild of Nutrition
itself, which stays intentionally out of scope for the Flutter UI in this
session per the brief ("Do NOT build Nutrition").

## Sync — `services/api/src/common/idempotency/`, `apps/mobile/lib/core/sync/`

**Backend**: `IdempotencyService.run({ userId, idempotencyKey, entityType,
operationType }, fn)` against the shared `SyncOperation` table.
`entityType`/`operationType` are plain strings — a domain doesn't register
anywhere, it just calls `run()` with its own values (Nutrition already does:
`MEAL_ENTRY`, `MEAL_ENTRY_COPY`, `WATER_ENTRY`).

**Flutter**: `SyncEngine.registerHandler(entityType, SyncHandler)` plus
`enqueue()`. A future Nutrition offline-write feature (e.g. logging a meal
while offline) would:
1. Implement a `SyncHandler` that calls the Nutrition repository method,
   passing the outbox entry's id through as `idempotencyKey`.
2. Register it once (see `WorkoutSessionController`'s constructor or
   `WorkoutPlanEditorService` for the pattern).
3. Call `syncEngine.enqueue(...)` from wherever the mutation happens.

No changes to `core/sync/` itself are needed — it has no Workout-specific
code in it today; verify that stays true as new handlers are added.

## History — `services/api/src/common/history/history-entry.interface.ts`

`HistoryEntry { id, domain, occurredAt, title, summary }` plus
`mergeHistoryTimelines(...entryLists)`. Each domain keeps its own read
model (Workout's `WorkoutHistoryService` reads live from `WorkoutSession`;
Nutrition would read from `MealEntry`/`WaterEntry`) and maps its own rows
to `HistoryEntry` at the boundary. A future "activity feed" endpoint or
dashboard section merges pre-fetched, already-paginated lists from each
domain — it does not query across domains at the database level, and there
is deliberately no shared `History` table (see `workout-history.service.ts`'s
own note on why).

## Progress — `services/api/src/common/progress/progress.util.ts`

Pure functions: `calculateStreak(dates)`, `calculateCompletionPercentage`,
`groupByWeek`/`groupByMonth`, `evaluateAchievements(rules, context)`. A
Nutrition "days logged" streak or a weekly macro-adherence summary calls
these directly with `MealEntry`/`WaterEntry` dates — no Nutrition-specific
logic needs to live in `common/progress/`. `AchievementRule<TContext>` is
generic on purpose: no achievement catalog exists yet for any domain, so
Nutrition can define its own rule set against this same shape when it's
ready, rather than both domains growing separate achievement systems.

## Units — `services/api/src/common/units/units.util.ts`

Metric/imperial conversions and display formatters (weight, distance,
water volume, energy/calories, time) — already exactly what Nutrition
needs for a future imperial-preference display of logged food/water
without changing how it's stored (always metric/kcal, matching the
existing `MealEntry`/`FoodServing` schema).

## Validation — `services/api/src/common/validation/common-validators.ts`

`IsBoundedNumber`/`IsBoundedInt` (collapses the `@IsNumber() @Min() @Max()`
trio), `IsRatingScale` (a 1–10 scale — reusable for a future meal
satisfaction or mood rating, not just workout RPE), `IsNotFarFutureDate`
(reusable for any "logged as of now" timestamp, including a meal entry's
`date`).

## Pagination — `services/api/src/common/pagination/pagination-query.dto.ts`

`PaginationQueryDto` (page/limit/search/sortBy/sortOrder) plus
`paginationArgs`/`paginationMeta` helpers. Nutrition's existing
`QueryFoodsDto` predates this and has its own page/limit fields; a new
Nutrition list endpoint (e.g. a future custom-food browser) should extend
`PaginationQueryDto` instead of re-declaring the same four fields.

## Dashboard cards — `apps/mobile/lib/features/dashboard/`

There is no formal "dashboard card registry" — `HomeDashboardScreen` reads
several domains' providers directly (`workoutHistoryListProvider`,
`personalRecordsProvider`, and now `nutritionDashboardSummaryProvider`) and
lays out one card per data source, each with its own loading/error/empty
handling. This is deliberately *not* abstracted into a plugin interface
yet — with three data sources the direct-provider approach is simpler and
more debuggable than an indirection layer would be. If a fourth or fifth
domain (Sleep, wearables) needs a dashboard card, and the screen's provider
list starts feeling unwieldy, that's the signal to introduce a
`DashboardCardContributor` abstraction — not before, per YAGNI.

## Macros / meal / water — already concrete, not abstract

The brief asks for these interfaces to stay "abstract." In this codebase
they're already concrete (`Food`, `FoodServing`, `MealEntry`, `MacroTarget`,
`WaterEntry` Prisma models; `FoodsService`, `NutritionLogService`,
`MacroTargetsService`, `WaterService`), built in the prior session — see
`build-session-2.md` for the full list of endpoints. That predates this
session's "don't build Nutrition" instruction and is a working
implementation, not a placeholder, so it was left as-is rather than
reworked into interfaces purely to match a description written before it
existed. What *is* new and abstract in this session is everything above:
the shared Sync/History/Progress/Units/Validation/Pagination layer those
concrete services can (and increasingly do — see the workout streak
endpoint) build on, and which a fully-scoped Nutrition Flutter feature or a
future Sleep/wearables domain will use the same way.
