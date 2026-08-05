# Wearables & Health Data

Project Ascend's goal is **broad compatibility through operating-system health hubs and approved
vendor integrations** — not a claim that every smartwatch exposes a direct public API, because
that isn't true. Some devices sync through Apple Health or Android Health Connect with no
vendor-specific work needed on our side; others require a dedicated, vendor-approved integration.

## What exists in this sprint

Wearable connections are **simulated**. Tapping "connect" on a provider in the Wearables screen
(`apps/mobile/lib/features/wearables`) creates a `DeviceConnection` row via the real
`POST /devices` API with `status: CONNECTED` — the connection preference is genuinely persisted,
but no OAuth flow, HealthKit/Health Connect permission prompt, or real data sync happens yet.
This lets onboarding and the Profile screen's "manage devices" flow work end-to-end today, while
keeping the door open to swap in real adapters later without changing the API contract.

## Supported provider categories

All fifteen categories from the product spec are represented in
`apps/mobile/lib/features/wearables/domain/wearable_provider_catalog.dart`, each with an honest
one-line description of how it actually syncs:

| Category | Sync path |
|---|---|
| Apple Health / Apple Watch | Apple HealthKit |
| Android Health Connect | Android's Health Connect hub |
| Samsung Health | Health Connect on supported devices |
| Xiaomi / Mi Fitness | Xiaomi's officially available platform APIs |
| Huawei Health | Huawei's vendor API |
| Garmin | Garmin's vendor API |
| Fitbit | Fitbit's vendor API |
| Polar | Polar's vendor API |
| Suunto | Suunto's vendor API |
| COROS | COROS's vendor API |
| Amazfit / Zepp | Zepp's vendor API |
| Oura | Oura's vendor API |
| WHOOP | WHOOP's vendor API |
| Smart scales | Apple Health or Health Connect where supported |
| Heart-rate straps | Apple Health, Health Connect, or a paired app |

Xiaomi devices specifically are supported only through Xiaomi's own officially available
platform/vendor paths — not through any unofficial or reverse-engineered protocol.

## Backend model

`DeviceConnection` (Prisma model, `services/api/prisma/schema.prisma`) already has the shape a
real integration needs: `provider`, `displayName`, `status` (`CONNECTED` / `DISCONNECTED` /
`PENDING` / `ERROR`), `externalAccountId` (for the vendor's own account/device identifier),
`lastSyncedAt`, and a free-form `metadata` JSON column for provider-specific state (e.g., an
OAuth refresh token reference, a Health Connect permission set). CRUD is exposed at
`GET/POST/PATCH/DELETE /devices`, scoped to the authenticated user (`DevicesService` checks
ownership before any mutation).

## Planned architecture for real integrations

The following interfaces are the intended shape for real adapters (not yet implemented as
production code — this section documents the target design referenced in the roadmap):

- **`WearableProvider`** — an enum/registry entry identifying a specific integration (mirrors the
  `provider` string already stored on `DeviceConnection`).
- **`WearableAdapter`** — the per-provider implementation: initiates the OS permission prompt or
  vendor OAuth flow, and exposes a `sync(SyncCursor) -> WearableSyncResult` method.
- **`HealthMetric`** — an enum of normalized metric types (steps, heart rate, sleep, weight, etc.)
  that every adapter maps its provider-specific data into, so the rest of the app never needs to
  know which provider a sample came from.
- **`HealthSample`** — a normalized `{ metric, value, unit, recordedAt, sourceProvider }` record.
- **`SyncCursor`** — an opaque, per-adapter, per-metric bookmark so incremental syncs don't
  re-fetch the entire history every time.
- **`WearableSyncResult`** — `{ samplesAdded, samplesSkipped, nextCursor, errors }`.

This design needs to handle, from day one of real implementation:

- **Duplicate sample detection** — the same step count can arrive from both Apple Health and a
  paired app; adapters need a stable dedup key (provider + metric + timestamp, at minimum).
- **Source priority** — when two providers report the same metric for overlapping time ranges,
  a deterministic priority order decides which value wins.
- **User consent** — every adapter's first sync must be gated behind an explicit permission grant
  (the OS-level HealthKit/Health Connect prompt, or the vendor's own OAuth consent screen), and
  that consent must be revocable from the Profile screen without leaving orphaned data access.
- **Revocation** — disconnecting a device (`DELETE /devices/:id`, already implemented) must also
  invalidate any stored OAuth token/refresh credential for that connection once a real adapter
  exists — today there's no credential to invalidate since nothing is real yet.
- **Timezone handling** — samples must be normalized to UTC for storage with the originating
  timezone preserved, since "steps on Tuesday" means different things depending on where the user
  was.
- **Unit normalization** — weight, distance, and other unit-bearing metrics must be normalized to
  a single internal unit (independent of the user's display `unitSystem` preference, which is
  purely a presentation concern).

## What's explicitly not claimed

- No provider in the catalog is described as having a guaranteed public API — several
  (Garmin, Fitbit, Polar, etc.) require developer approval that isn't automatic.
- Nothing here claims that connecting a device today actually syncs real health data — the UI
  copy and this document are both explicit that Sprint 1 connections are simulated.
