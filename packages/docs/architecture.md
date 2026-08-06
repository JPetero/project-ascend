# Architecture

Project Ascend is a **modular monolith**: one deployable backend service (`services/api`) with
clearly separated feature modules, paired with a feature-first Flutter client (`apps/mobile`).
This document explains the layering, why a monolith is the right choice for this stage, and how
to split it later if the product grows enough to justify that cost.

## Three layers

### 1. Experience layer (Flutter — `apps/mobile`)

Everything the user sees and touches: screens, the design system, navigation, and local state.
It never talks to PostgreSQL directly — all persistence goes through the backend's HTTP API, with
a local Drift cache for offline resilience and instant reads.

- `core/design_system` — tokens (color, spacing, radius, typography) and the reusable widget
  library (`AscendPrimaryButton`, `AscendCard`, etc.), so every screen looks and behaves
  consistently.
- `core/routing` — a single GoRouter instance with centralized redirect logic driven by auth and
  onboarding state.
- `core/networking` — a Dio-based `ApiClient` that attaches the access token, retries once after
  a silent refresh on 401, and normalizes errors into `AppException`.
- `core/storage` — `SecureTokenStorage` (tokens, via a pluggable `TokenStore` so it's testable
  without touching a platform channel), `LocalPreferences` (non-sensitive settings), and
  `AppDatabase` (Drift — the offline cache; see below).
- `features/*` — one directory per product area (`auth`, `onboarding`, `companion`, `dashboard`,
  `workout`, `community`, `profile`, `wearables`, `sharing`), each split into `data` (repositories
  talking to `ApiClient`), `domain` (plain models), and `presentation` (screens, widgets, Riverpod
  providers). No feature module reaches into another feature's internals directly — they compose
  through providers.

### 2. Intelligence layer (companion + local response service)

Atlas and Nova are two presentations of the same underlying assistant. Today that "intelligence"
is a fully local, deterministic `LocalCompanionResponseService`
(`lib/features/companion/data/local_companion_response_service.dart`) — no external AI call is
made yet. This keeps the companion UI (avatar states, quick actions, chat transcript) genuinely
testable and demonstrably working before a real AI gateway exists. See
[roadmap.md](roadmap.md) for the planned AI gateway module, which will slot in behind the same
`CompanionChatController` interface without touching the UI layer.

### 3. Data layer (NestJS — `services/api`)

- `src/modules/*` — one module per bounded concern: `auth`, `users`, `profiles`, `preferences`,
  `devices`, `health`, plus the Workout Engine modules added in Sprint 2 (`exercise-categories`,
  `muscle-groups`, `equipment-types`, `exercises`, `workouts`, `workout-plans`,
  `workout-sessions`, `personal-records`, `workout-history` — see
  [Workout Engine (Sprint 2)](#workout-engine-sprint-2) below). Each module owns its controller,
  service, and DTOs; **controllers never touch Prisma directly** — they call a service, which is
  the only thing that talks to `PrismaService`.
- `src/common` — cross-cutting concerns shared by every module: the `{ data, meta, error }`
  response envelope (interceptor + exception filter), the `@Public()`/`@CurrentUser()`
  decorators, and audit logging.
- `src/prisma` — the Prisma client wrapped in a Nest-lifecycle-aware `PrismaService`.
- `prisma/schema.prisma` — the single source of truth for the data model (see the schema itself
  for the portability note on `WorkoutSchedule.daysOfWeek`).

## Why a modular monolith, not microservices

At this stage — one team, one deployable, a handful of related domains (auth, profile,
preferences, devices) that mostly read and write the same few tables in the same transactions —
splitting into services would add real cost (network calls where a function call would do,
distributed transactions instead of a single Prisma transaction, separate deploy pipelines) for
no benefit anyone here needs yet. A monolith with clean module boundaries gets almost all of the
organizational benefit of microservices (you can still reason about one module without reading
the others) while keeping local development, testing, and refactoring cheap.

## How this splits later

The module boundaries in `src/modules/*` are already drawn where a future service boundary would
go. If a module's scale or team ownership eventually justifies extraction:

1. It already has its own DTOs, service, and controller — no business logic is entangled with
   another module's.
2. Give it its own Prisma client (or a shared read replica) and move its tables' migrations to
   the new service.
3. Replace the in-process service call with an HTTP or message-queue call, and update the
   `AuditEvent`/DTO contracts if they need to cross the new boundary.

The most likely first candidate is `devices` (wearable sync), since it's the module most likely
to need independent scaling once real wearable adapters and background sync jobs exist.

## Offline foundation (Drift)

`AppDatabase` (`apps/mobile/lib/core/storage/app_database.dart`) caches the profile, preferences,
and dashboard fixture, and preserves in-progress onboarding form state — all keyed so a restart
mid-onboarding doesn't lose the user's answers. Sprint 2 added `CachedWorkoutSessionRows`, a
singleton-row table holding the active (or most recently finished-but-unsynced) workout session
as JSON — see [Offline and synchronization strategy](#offline-and-synchronization-strategy) for
how it's used. `AppDatabase` is still intentionally **not** a general-purpose sync engine.

Deliberately out of scope so far, and planned for later:

- A general-purpose **outbox table** of pending mutations for features beyond workout logging
  (e.g. meal logs, once nutrition tracking exists), flushed when connectivity returns. Workout
  logging has its own narrower local-first mechanism (below) rather than this shared outbox,
  since it only ever needs to reconcile one active session at a time.
- **Idempotency keys** on outbox entries so a retried mutation can't double-apply server-side.
- **Cloud conflict resolution** — the workout sync strategy below explicitly has none (a session
  edited from two devices has no merge logic); a real multi-device story needs one.
- A **user-visible sync state** for features other than workouts (already scaffolded as
  `SyncStatusRows`/`watchSyncStatus()`, just not wired to any UI yet) so users know when their
  data is up to date.

## Workout Engine (Sprint 2)

The Workout Engine is split into a shared, read-only **catalog** and per-user **owned** data, so
curated content can be updated centrally without ever mutating what a user has already logged.

**Catalog (seeded, shared, read-only from the API's perspective)**

- `ExerciseCategory`, `MuscleGroup`, `EquipmentType` — small reference tables (name + slug) used
  to filter and tag exercises.
- `Exercise` — the library entry: name, description, difficulty, instructions, safety tips,
  common mistakes, an image/video URL placeholder (no real media pipeline yet — deliberately
  honest "coming soon" placeholders in the UI rather than fake content), plus its muscles
  (`ExerciseMuscle`, tagged `PRIMARY`/`SECONDARY` via `MuscleRole`), equipment
  (`ExerciseEquipment`), and alternatives (`ExerciseAlternative`, a self-referential many-to-many).
- `Workout` / `WorkoutExercise` — a curated, shared workout (e.g. "Full Body Strength") and its
  ordered, prescribed exercises (target sets/reps/weight/duration, rest seconds). This is what
  "Browse workouts" lists; it is never modified by a user directly.
- Seeded via `services/api/prisma/seed.ts` (`pnpm --filter @project-ascend/api prisma:seed`, run
  automatically in CI after migrations) — 22 exercises, 4 workouts, and their supporting reference
  data.

**User-owned data**

- `WorkoutPlan` / `WorkoutPlanExercise` — created by copying a catalog `Workout`'s exercises in
  (`POST /workout-plans` with a `workoutId`), then freely editable independently of the catalog
  original. A plan can also be built from scratch by passing an explicit `exercises` array instead
  of a `workoutId`.
- `WorkoutSession` — one lifecycle instance of "doing a workout": `status`
  (`IN_PROGRESS`/`PAUSED`/`COMPLETED`/`ABANDONED`), `startedAt`, `resumedAt` (start of the
  *current* active streak — needed so `activeDurationSeconds` accumulates correctly across
  multiple pause/resume cycles), `pausedAt`, `completedAt`, `activeDurationSeconds`. The backend
  enforces **one active session per user** (`ConflictException`/409 on a second `start()` while
  one is already `IN_PROGRESS` or `PAUSED`).
- `WorkoutSet` — one logged set within a session: `exerciseId`, `setNumber` (**server-assigned**,
  never client-specified, to avoid offline/client numbering conflicts), `reps`, `weightKg`,
  `durationSeconds`, `distanceMeters`, `isWarmup`.
- `PersonalRecord` — the user's **current best** per `(userId, exerciseId, type)` — a unique,
  upserted-in-place row, not an append-only history log. `type` is one of `MAX_WEIGHT`,
  `MAX_REPS`, `MAX_DURATION`, `MAX_DISTANCE`, `MAX_VOLUME` (`PersonalRecordType`).
  `achievedAt`/`workoutSessionId` let the specific session that set the record be traced without a
  separate history table.

**No `WorkoutHistory` table, by design.** History is a read-model computed on the fly by
`WorkoutHistoryService` over completed `WorkoutSession`/`WorkoutSet` rows (`GET /workout-history`,
`GET /workout-history/:id`), rather than a separately-maintained table — avoiding duplicating data
that already exists in `WorkoutSession`/`WorkoutSet`.

**Progression suggestions** (`GET /exercises/:id/progression`) are deterministic, not AI-driven:
based on the user's own last completed performance of that exercise, they suggest a small,
guaranteed increase — weight-based exercises get `+2.5kg` or `~2.5%` (rounded up), whichever is
larger, so the suggestion is always strictly higher than last time; duration-based exercises get
`max(+5s, +10%)`; distance-based get `+10%`; bodyweight/reps-only exercises get `+1 rep`. This
deliberately does **not** factor in "recovery" or readiness (e.g. "repeat previous weight if
recovery is reduced") — there is no real wearable/HRV data pipeline to base that on yet, and a
fabricated recovery signal would be worse than not showing one.

**Personal record detection** (`PersonalRecordsService.detectAndRecord`) runs automatically when a
session finishes: it groups the session's non-warmup sets by exercise, computes candidate values
per `PersonalRecordType` (volume is the sum of `reps × weightKg` across the session's weighted
sets for that exercise), and upserts a `PersonalRecord` only where the new value strictly beats
the existing one — returning just the newly-broken records so the mobile Summary screen can
celebrate them without re-deriving which ones are new.

**New API endpoints** (all under the existing `{ data, meta, error }` envelope and JWT auth):

| Area | Endpoints |
|---|---|
| Catalog | `GET /exercise-categories`, `GET /muscle-groups`, `GET /equipment-types` |
| Exercises | `GET /exercises` (filterable by category/muscle/equipment/difficulty/search), `GET /exercises/:id`, `GET /exercises/:id/progression` |
| Workouts (catalog) | `GET /workouts` (filterable by category/difficulty), `GET /workouts/:id` |
| Workout plans (user-owned) | `GET /workout-plans`, `GET /workout-plans/:id`, `POST /workout-plans`, `PATCH /workout-plans/:id`, `DELETE /workout-plans/:id` |
| Workout sessions | `POST /workout-sessions`, `GET /workout-sessions/active`, `GET /workout-sessions/:id`, `POST /workout-sessions/:id/pause`, `POST /workout-sessions/:id/resume`, `POST /workout-sessions/:id/finish`, `POST /workout-sessions/:id/abandon`, `POST /workout-sessions/:id/sets`, `PATCH /workout-sessions/:id/sets/:setId`, `DELETE /workout-sessions/:id/sets/:setId` |
| Personal records | `GET /personal-records` |
| Workout history | `GET /workout-history` (paginated), `GET /workout-history/:id` |

Full request/response shapes are in the generated OpenAPI docs at `/docs` once the API is running
(every controller/DTO is decorated with `@ApiTags`/`@ApiOperation`/class-validator decorators).

## Offline and synchronization strategy

Workout logging must work completely offline — this is the one area of the app with a real
local-first sync strategy today (see [Offline foundation](#offline-foundation-drift) for why it
isn't a general-purpose outbox). It's implemented in
`WorkoutSessionController` (`apps/mobile/lib/features/workout/presentation/providers/workout_session_controller.dart`)
and `WorkoutSessionState`/`LoggedSet`
(`apps/mobile/lib/features/workout/domain/workout_session.dart`):

1. **Drift is always the source of truth for the active session.** Every mutation
   (`start`/`logSet`/`pause`/`resume`/`finish`/`abandon`) updates local state and persists it to
   `CachedWorkoutSessionRows` *before* attempting any network call. The UI never blocks on the
   network, and killing the app mid-workout resumes cleanly from the cache on next launch (scoped
   to the signed-in user — a cached session belonging to a different account is discarded, never
   shown).
2. **Best-effort real-time sync.** After each local write, the controller tries the matching
   backend call (`WorkoutSessionRepository`). If it succeeds, the session/set is marked synced
   (`serverId` set). If it fails with `AppException.network()` (no connectivity), the failure is
   swallowed and the local state is left as the record of truth — nothing is lost, it's just not
   on the server yet.
3. **One reconciliation pass, at `finish()` or `retrySync()`.** This is the only place a session
   catches up all at once:
   - If the session never got a `serverId` (it was started while offline), the whole session is
     **replayed**: `start` → `logSet` for every not-yet-synced set → `finish`, in order.
   - If it already has a `serverId` (it was online at start, but some sets failed to push along
     the way, or the network dropped right at `finish`), only the not-yet-synced sets are pushed,
     then `finish` is called.
   - On success the local cache is cleared (the backend is now the record of truth) and the
     Summary screen renders the confirmed result, including any new personal records.
   - On failure the session is kept locally with `syncStatus: failed` and a user-facing retry
     action (the Summary screen's "Saved on this device only" banner, wired to
     `WorkoutSessionController.retrySync`).
4. **No cloud conflict resolution.** There is deliberately no merge logic for edits made to the
   same session from two devices — the product doesn't need it yet, and a fabricated merge
   strategy would be worse than the honest single-device assumption this makes today. If
   multi-device workout logging becomes a requirement, this is the layer that needs a real
   conflict-resolution design (see [Offline foundation](#offline-foundation-drift) for the
   broader gaps this shares with a future general-purpose outbox).

## Response envelope

Every API response — success or error — has the same shape:

```json
{ "data": {}, "meta": {}, "error": null }
```

```json
{ "data": null, "meta": {}, "error": { "code": "VALIDATION_ERROR", "message": "...", "details": {} } }
```

This is enforced globally by `ResponseEnvelopeInterceptor` (wraps success) and
`AllExceptionsFilter` (wraps errors, and never leaks a raw exception message or stack trace to
the client — see [security.md](security.md)).
