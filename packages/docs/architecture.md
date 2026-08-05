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
  `devices`, `health`. Each module owns its controller, service, and DTOs; **controllers never
  touch Prisma directly** — they call a service, which is the only thing that talks to
  `PrismaService`.
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
mid-onboarding doesn't lose the user's answers. It is intentionally **not** a full sync engine.

Deliberately out of scope for this sprint, and planned for later:

- **Local-first writes** for workout/meal logs — write to Drift immediately, queue the server
  write.
- An **outbox table** of pending mutations, flushed when connectivity returns.
- **Idempotency keys** on outbox entries so a retried mutation can't double-apply server-side.
- **Server reconciliation** — last-write-wins is not good enough for anything beyond simple
  settings; logs need an explicit merge/conflict strategy.
- A **user-visible sync state** (already scaffolded as `SyncStatusRows`/`watchSyncStatus()`, just
  not wired to any UI yet) so users know when their data is up to date.

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
