# Wearables & Health Data

Project Ascend's goal is **broad compatibility through operating-system health hubs and approved
vendor integrations** — not a claim that every smartwatch exposes a direct public API, because
that isn't true. Some devices sync through Apple Health or Android Health Connect with no
vendor-specific work needed on our side; others require a dedicated, vendor-approved integration.

## What exists today

**Android Health Connect and Apple HealthKit are real, not simulated**, as of Build Session 7
Part 3 — see `apps/mobile/lib/features/wearables/data/health_adapter.dart` and
`services/api/src/modules/health-metrics/`. The `ConnectedHealthScreen` (reachable from the
Wearables screen's "Connected Health" card) drives a genuine `package:health`-backed sync:
availability detection, an OS permission request, an incremental per-metric read, upload to the
backend's `/health-metrics/sync` endpoint, and per-metric last-synced status read back from
`/health-metrics/sync-status`. Disconnecting revokes the platform permission, clears the local
sync bookmark, and (via the existing `DELETE /devices/:id` flow) clears the backend's own sync
cursor for that provider.

This is architecturally complete and fully covered by unit/widget tests against a fake adapter
(no platform channel required), but the actual OS permission dialog, a real Health Connect/
HealthKit read, and the Android manifest / iOS `Info.plist` health-permission entries are
**unverified at runtime** — see `packages/docs/build-session-7.md`'s Part 3 section for exactly
what is and isn't confirmed working, and why.

Every other provider category below (Samsung Health beyond what Health Connect already covers,
Xiaomi's own APIs, Garmin, Fitbit, Polar, Suunto, COROS, Amazfit/Zepp, Oura, WHOOP) remains
**simulated**: tapping "connect" on one of those in the Wearables screen creates a
`DeviceConnection` row via the real `POST /devices` API with `status: CONNECTED` — the connection
preference is genuinely persisted, but no OAuth flow or real vendor data sync happens yet. This
lets onboarding and the Profile screen's "manage devices" flow work end-to-end today for every
category, while the two OS-hub integrations above are the first to have a real sync behind them.

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

Xiaomi devices specifically are supported only through whatever Xiaomi/Mi Fitness writes into
Android Health Connect — never through Xiaomi's own private or reverse-engineered APIs. The
Connected Health screen says this explicitly on Android rather than implying a direct Xiaomi
integration exists.

## Backend model

`DeviceConnection` (Prisma model, `services/api/prisma/schema.prisma`) already has the shape a
real integration needs: `provider`, `displayName`, `status` (`CONNECTED` / `DISCONNECTED` /
`PENDING` / `ERROR`), `externalAccountId` (for the vendor's own account/device identifier),
`lastSyncedAt`, and a free-form `metadata` JSON column for provider-specific state (e.g., an
OAuth refresh token reference, a Health Connect permission set). CRUD is exposed at
`GET/POST/PATCH/DELETE /devices`, scoped to the authenticated user (`DevicesService` checks
ownership before any mutation).

## Real architecture: Health Connect / HealthKit

For the two OS-hub providers, the design below is now implemented, not just planned:

- **`HealthAdapter`** (`apps/mobile/lib/features/wearables/data/health_adapter.dart`) — an
  abstract class implemented by `PlatformHealthAdapter` (the real `package:health`-backed
  adapter) and by a `FakeHealthAdapter` test double. Exposes `isAvailable()`,
  `checkPermissions()`/`requestPermissions()`/`revokePermissions()`, `supportedMetrics`/
  `unsupportedMetrics`, and `readSamples({metrics, since})`.
- **`HealthMetric`** (`domain/health_metric.dart`) — the normalized metric enum: steps, heart
  rate, resting heart rate, exercise sessions, active calories, distance, sleep, cycling distance.
- **`HealthSample`** (`domain/health_sample.dart`) — a normalized `{metric, value, recordedAt,
  sourceProvider, sourceId, sourceName}` record.
- **`HealthSyncCursor`** (backend, `services/api/prisma/schema.prisma`) — the server's own
  per-user/provider/metric bookmark of what's been stored, unique-constrained so a `disconnect`
  clears exactly the right rows. The Flutter app additionally keeps its own local bookmark
  (`CachedHealthSyncStatusRows`, Drift) of what it's already asked the platform for — the two are
  intentionally independent: one is "what the server has," the other is "what the client already
  fetched."
- **`HealthMetricSample`** (backend) — the stored sample, unique-constrained on
  `userId + metric + sourceProvider + recordedAt` so a repeated sync of the same underlying
  platform record is silently absorbed (`createMany({skipDuplicates: true})`) rather than
  duplicated.

The remaining thirteen vendor categories below still need this same shape built out per-vendor;
this design needs to handle, for each of them:

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
- For the thirteen still-simulated categories, nothing here claims that connecting a device today
  actually syncs real health data — the UI copy and this document are both explicit about that.
- For Health Connect and HealthKit, the sync pipeline (adapter, controller, backend module,
  storage, UI) is real and tested end-to-end against a fake platform adapter — but the actual OS
  permission prompt, a real platform data read, and the required Android manifest / iOS
  `Info.plist` health-permission entries are unverified at runtime in this environment (no
  Android SDK, no Xcode). See `packages/docs/build-session-7.md` Part 3 for the exact boundary
  between what's built and what's confirmed working on a device.
