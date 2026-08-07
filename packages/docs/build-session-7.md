# Build Session 7 — Major Product Expansion

Continues directly from `main` at commit `72d07b2` (which already contained
Build Session 5's offline-first Nutrition and achievement unlock
celebrations, merged via PR #3). Branch: `claude/major-product-expansion`.
Nothing from prior sessions was regenerated or replaced — every change here
is additive on top of that history.

This document is written incrementally as each part in the session's
priority order is completed and committed. See the top of each section for
its own commit hash once merged.

---

## Part 0 — Git safety

`git status`/`git branch --show-current`/`git remote -v`/`git fetch --all
--prune`/`git log --oneline --decorate --graph -30`/`git diff --stat` were
run first, per the directive. Findings:
- The previous session's branch (`claude/new-session-qy6hzm`) had already
  been merged into `main` via PR #3 (`72d07b2`) before this session began —
  confirmed by `git log --oneline -3 origin/main` showing the merge commit
  directly above `Add achievement unlock celebrations` and
  `Complete offline-first Nutrition`.
- Per this session's own merged-PR-handling instructions, the designated
  branch was restarted from the latest `main` rather than stacked on top of
  already-merged history: `git checkout -B claude/major-product-expansion
  origin/main`.
- No destructive git commands were used (no `reset --hard`, `clean -fd`, or
  `push --force`).

---

## Part 1 — Founder features 21–27

Commit: `Add Founder features 21-27`

### What this part is

A second Founder addendum — Scenarios 21–27 in
`user-scenario-bible.md` — covering: six-destination navigation (Train,
Fuel, Community, Ascend AI, Rankings, plus Vision as a Premium sixth),
Community Reels, Ascend Promote, Trainer Groups, sports scoring, expanded
cardio activity types, the Nutrition Library, Support access, companion
tone boundaries, and centralized pricing. Unlike the Scenarios 11–20
addendum (which deferred everything), most of these areas get real
construction across this same session's later parts — Part 1 itself is
the documentation and capability-model alignment done first, so every
part that follows has an authoritative spec to build against.

### Docs updated

`user-scenario-bible.md` (new Scenarios 21–27 section + a navigation
clarification superseding the old five-tab note), `founder-vision-bible.md`
(principles 19–25 addendum + a revised non-goals section), `design-bible.md`
(six-destination navigation section), `free-premium-policy.md` (new
Free/Premium entries + the revised pricing hypothesis — ~USD 12.99/7.99,
~PHP 599/299 — replacing the original ~USD 4.99/9.99 draft),
`atlas-nova-bible.md` (an emotional-boundaries section), `parking-lot.md`
(a new Scenarios 21–27 deferred-items list, updated as each part below
lands), `roadmap.md` (a paragraph pointing at this document).

### Capability model

11 new `AppCapability` entries added to both
`services/api/src/common/entitlements/capability.util.ts` and
`apps/mobile/lib/core/entitlements/capability.dart` (kept in lockstep, as
required): six free (`EXPANDED_CARDIO_ACTIVITIES`, `NUTRITION_LIBRARY`,
`SUPPORT_ACCESS`, `COMMUNITY_REELS`, `TRAINER_GROUPS_BASIC`,
`SPORTS_SCORING_MANUAL`) and five premium-future (`VISION_ACCESS`,
`CARDIO_ADVANCED_ANALYTICS`, `TRAINER_GROUPS_EXPANDED`, `ASCEND_PROMOTE`,
`SPORTS_SCORING_ASSISTED`). Both test suites' hardcoded free/premium lists
were updated to match — the backend spec also asserts every enum member
has exactly one entitlement entry, which caught nothing missing here.

### Real navigation code, not just docs

The five existing tabs were relabeled in `AppShell` (Workout→Train, Meal
Prep→Fuel, Social→Community, Assistant→Ascend AI, Leaderboards→Rankings)
— **route path segments were deliberately left unchanged**
(`/workout`, `/meal-prep`, etc.) so existing deep links, redirects, and
tests keep working; only the visible label/icon changed. A genuinely new
sixth destination, Vision, was added — a capability-gated placeholder
screen (`VisionScreen`) that shows an honest "Premium destination, locked"
state for every account today (nobody has Premium — no billing exists
yet) or an honest "still being built" state for a hypothetical Premium
account, never a fabricated camera preview. The full Vision shell (Form
Coach, Food Scan, etc.) is Part 8's job; Part 1 only adds the navigation
slot and an honest placeholder behind it.

Fallout fixed: 8 widget-test call sites across
`test/features/nutrition/` that tapped the bottom nav bar by its old
label text (`find.text('Meal Prep')`) were updated to the new label
(`find.text('Fuel')`).

### Commands run and results

Backend: `npx tsc --noEmit` clean, `npx eslint --max-warnings=0` clean,
`npx jest --silent` → 180 tests passed (was 158).

Flutter: `dart analyze` clean, `dart format --output=none
--set-exit-if-changed .` clean, `flutter test` → 213 tests passed (was
189; +24: 11 new capability tests, 2 new Vision-screen tests, plus count
drift from the nav-label fallout fixes).

### Known scope decisions

- Individual screens' own AppBar titles (e.g. `WorkoutScreen`'s "Workout")
  were deliberately **not** renamed to match the new nav labels — only the
  bottom nav bar itself. Renaming every screen header would have meant
  fixing many more test assertions for a cosmetic-only change; the
  directive's explicit ask was the navigation destinations, which is the
  nav bar. Flagged here as an honest, bounded scope cut, not an oversight.

---

## Part 2 — Live GPS cardio

Commit: `Implement live private GPS cardio`

### Backend: route storage, encoding, and privacy filtering

`CardioSession` gained `source` (`MANUAL` | `LIVE_GPS` | `WEARABLE` —
forward-compatible with the Health Connect/HealthKit foundation in Part
3), `encodedRoute` (a Google-style encoded polyline — see
`common/geo/polyline.util.ts`, a from-scratch, dependency-free
implementation verified against the algorithm spec's own published
reference example), and `routePointCount`. Forward-only migration
(`20260806225734_live_gps_cardio`), purely additive: two new nullable
columns, a new `source` column with a `MANUAL` default so every existing
row stays valid, and `CardioActivityType` gained four new values (`JOG`,
`SPRINT`, `HIKE`, `WHEELCHAIR` — pure `ALTER TYPE ... ADD VALUE`,
existing `WALK`/`RUN`/`CYCLE`/`OTHER` untouched), satisfying Scenario 26's
expanded-cardio-activities requirement at the same time.

**Privacy is enforced at write time, not just read time**: when a
session's `hideRoute` is true (the default), route points are never
persisted at all — not stored-then-filtered, genuinely never written to
the database. When `hideStartLocation`/`hideEndLocation` are true (also
the default), the first/last few points are trimmed by
`trimEndpoints()` *before* encoding, so the exact start/end coordinates
are discarded, never merely hidden. Flipping `hideRoute` to `true` later
via `PATCH` permanently wipes any previously stored route — there is no
"un-hide" that brings deleted coordinates back. `CardioService.serialize()`
only includes `encodedRoute`/`routePointCount` in a response when the
owner hasn't hidden the route; a `hasRoute` boolean is always present so
the client can show "this session has a route" without ever seeing
coordinates it shouldn't.

**Ownership validation** was already in place (`findOwned` on every
read/update/delete) and needed no changes. **Idempotent uploads** reuse
the existing `IdempotencyService` ledger, unchanged. **Payload/point-count
limits**: `routePoints` is capped at `@ArrayMaxSize(2000)` in the DTO — a
deliberately compact wire format (`{lat, lng, t}`, `t` = elapsed seconds,
not a full timestamp) keeps a full 2000-point payload safely under the
default request body size limit, verified with a dedicated e2e test
sending 2001 points and asserting a 400.

### Flutter: live tracking architecture

New `geolocator: ^14.0.2` dependency (added via `flutter pub add`,
resolved cleanly). `LiveLocationService` is defined as an abstract
interface (`GeolocatorLiveLocationService` is the real implementation)
specifically so `LiveCardioSessionController` is unit-testable against a
`FakeLiveLocationService` instead of a real platform plugin — the same
reasoning as every other repository/service abstraction already in this
codebase. GPS-accuracy filtering (points reported with >30m accuracy are
dropped) is a pure, separately-unit-tested predicate
(`isAcceptableAccuracy`) rather than being buried inside the plugin
stream wiring. Battery-conscious sampling is delegated to the OS location
provider itself via `LocationSettings.distanceFilter` — the stream only
wakes when the device has moved roughly 5m, rather than the app polling
continuously.

`LiveCardioSessionController` mirrors `WorkoutSessionController`'s
established pattern exactly: an immutable `LiveCardioSessionState`,
persisted to a new single-row Drift cache
(`CachedCardioSessionRows`, schema v6→v7, purely additive
`createTable`) on every mutation, which is what makes **interrupted-
session recovery** real — if the app is killed mid-run, relaunching
restores the session (always landing paused, never silently resuming
GPS tracking) with every route point recorded up to that moment intact,
verified by a test that constructs a second controller instance against
the same database mid-session with no `finish()`/`abandon()` in between.
A recovered session belonging to a different signed-in account is
discarded, matching the same account-isolation rule
`WorkoutSessionController` already established.

Distance accumulates point-to-point via a from-scratch haversine
implementation (`geo_distance.dart`, unit-tested against a known
real-world reference distance). Average pace is derived from accumulated
distance/duration; a live duration ticker in the UI recomputes from
wall-clock time every second rather than storing a running counter — the
same `resumedAt`-plus-elapsed pattern `WorkoutSessionState` already uses
for pause/resume accounting.

**Offline operation**: tracking, pausing, resuming, and accumulating
route points never touch the network — only `finish()` calls the backend
(and only once, thanks to the idempotency key). **Manual-summary
fallback**: `CardioLogScreen` (manual entry) is untouched and remains
fully reachable — `CardioHistoryScreen` now offers both a "Start a live
session" and a "Log cardio manually" action side by side, never forcing
live tracking on someone who doesn't want it or can't grant location
access.

### Platform configuration (unverified at runtime — see Platform
Limitations)

`AndroidManifest.xml` gained `ACCESS_FINE_LOCATION`/
`ACCESS_COARSE_LOCATION` (foreground-only — no background/"always"
location permission is requested anywhere, per Scenario 12's "no location
tracking outside an active session" rule). `Info.plist` gained
`NSLocationWhenInUseUsageDescription` with user-facing copy explaining
exactly what the permission is for. Neither could be runtime-verified —
see Platform Limitations.

### Integration points

Train (the new `LiveCardioScreen`, reachable from `CardioHistoryScreen`,
itself reachable from cardio history/logging), activity history
(`CardioHistoryScreen` now shows a "Live" badge and route-recorded
indicator for `LIVE_GPS` sessions), achievements (unchanged — the
existing `evaluateCardioAchievements` trigger fires identically for a
live-tracked session as a manual one, verified by an e2e test), dashboard/
calendar (already read from the same `CardioSession` list this extends,
no changes needed there). Rankings and Community extension points: the
new `source` field is exactly the "manual-entry distinction" Part 6's
anti-cheat model will need, and `hasRoute`/`encodedRoute`'s privacy
filtering is the same shape a future Community-sharing feature would
reuse rather than rebuild.

### Tests

Backend: `common/geo/polyline.util.spec.ts` (9 tests — round-trip
encode/decode, the algorithm spec's own reference example, negative
deltas, empty input, endpoint trimming including the never-goes-negative
edge case); `cardio.service.spec.ts` gained 5 new tests (route storage +
trimming, hideRoute-true never persists points, hideRoute flip wipes a
stored route, response filtering both ways); `cardio.e2e-spec.ts` gained
3 new tests (a real HTTP round-trip storing a trimmed, encoded route and
then hiding it after the fact; hideRoute-true never persisting points
end-to-end; the 2001-point payload limit rejection).

Flutter: `geo_distance_test.dart` (3 tests), `live_location_service_test.dart`
(2 tests, the accuracy-filter predicate), `live_cardio_session_controller_test.dart`
(11 tests — permission denied/service disabled, start/pause/resume/
finish/abandon, distance and route-point accumulation from emitted fixes,
finish() uploading with `source: LIVE_GPS` and defaulting to hidden
route, interrupted-session recovery, cross-account isolation, rejecting a
second concurrent session).

### Commands run and results

Backend: `npx tsc --noEmit` clean, `npx eslint --max-warnings=0` clean,
`npx jest --silent` → 194 tests passed (was 180), `npx jest --config
./test/jest-e2e.json --silent` → 61 tests passed (was 58).

Flutter: `flutter pub add geolocator` resolved cleanly (14.0.2), `dart run
build_runner build` regenerated `app_database.g.dart` for schema v7,
`dart analyze` clean, `dart format --output=none --set-exit-if-changed .`
clean, `flutter test` → 229 tests passed (was 213).

### Platform limitations (honest, not fabricated)

`flutter doctor -v` in this environment reports no Android SDK, no
Chrome, and missing Linux GTK dev libraries — `flutter build apk --debug`
could not be attempted, and no result for it is claimed. The Android
manifest and iOS `Info.plist` permission entries above are real,
necessary configuration, but their actual runtime behavior (the OS
permission prompt appearing, a real GPS fix arriving) is **unverified** —
this is architecture and platform configuration completed ahead of a
real device/emulator, not a claimed working build. `docker compose
build` could not be attempted either — no Docker daemon is reachable in
this environment (`Cannot connect to the Docker daemon at
unix:///var/run/docker.sock`).

### Known scope decisions

- **No background/killed-app continuation.** If the app process is
  killed entirely (not just backgrounded) while tracking, GPS recording
  stops — recovery on relaunch restores progress up to the last point
  recorded while the app was alive, not points that would have been
  recorded during the gap. A true background location service (a
  foreground Android service + iOS background location mode) is a
  materially larger scope than this part's budget and isn't silently
  claimed to work.
- **Conflict-with-scheduled-workout handling** (Scenario 12's other open
  item) is not implemented — starting a live cardio session doesn't check
  for or warn about an overlapping scheduled strength workout.
- **Current (instantaneous) pace** is not a separate rolling-window
  calculation — the UI shows average pace (accumulated distance ÷
  accumulated active duration), which is honest and simple rather than a
  more sophisticated but harder-to-verify instantaneous estimate.

---

## Part 3 — Health Connect and HealthKit foundation

Commit: `Implement connected health platform foundation`

### What this part is

Official OS health-platform integration — Android Health Connect and
Apple HealthKit — behind a single unified sync pipeline, per Scenario 22
(Founder features 21–27) and `packages/docs/wearables.md`'s
previously-simulated wearables architecture. Steps, heart rate, resting
heart rate, exercise sessions, active calories, distance, sleep, and
cycling distance are all modeled. Xiaomi/Mi Fitness data is supported
only through whatever it writes into Health Connect — Ascend never calls
a private or reverse-engineered Xiaomi API directly, and the UI says so.

### Backend: `health-metrics` module

Deliberately **not** built inside the existing `health/` module — that
module is the public `/health` liveness check
(`@Public() @Get() /health` → `{status, timestamp}`), used by
`test/app.e2e-spec.ts` and (presumably) container/orchestration health
probes. A first pass accidentally created colliding files directly under
`src/modules/health/`, overwriting the liveness controller; this was
caught before commit (via `grep -rln "class HealthController"` plus
checking `app.module.ts`'s imports) and fixed by restoring the original
file with `git checkout --` and moving all new code to
`src/modules/health-metrics/` (route prefix `/health-metrics`, classes
`HealthMetricsController`/`HealthMetricsService`/`HealthMetricsModule`)
instead. The two modules now coexist in `app.module.ts` with no naming or
routing overlap.

New Prisma models: `HealthMetricSample` (unique on
`userId + metric + sourceProvider + recordedAt`, so a repeated sync of
the same underlying platform record is silently absorbed rather than
duplicated) and `HealthSyncCursor` (unique on `userId + provider +
metric`, the backend's own bookmark of what's already been stored, kept
deliberately separate from the Flutter app's local incremental-sync
bookmark described below — one tracks what the server has, the other
tracks what the client has already asked the platform for). A new
`HealthMetric` enum covers all eight tracked metrics.

`HealthMetricsService.sync()` accepts a provider id and up to 5,000
samples per call, batch-inserts with `createMany({ skipDuplicates: true
})` for efficient duplicate detection without per-row error handling, and
advances the per-metric cursor. `syncStatus()` returns the caller's
cursors (used by the Connected Health screen's "last synced" display per
metric). `clearCursorsForProvider()` is called by
`DevicesService.remove()` when a `DeviceConnection` is deleted, so
disconnecting a provider on the backend also wipes its sync bookmarks —
verified by an e2e test that connects, syncs, disconnects, and confirms
`syncStatus()` comes back empty for that provider.

Units and timestamps are normalized at the DTO boundary (samples arrive
with an ISO timestamp and a bare numeric value; the metric enum itself
carries the implied unit, e.g. steps are always a count, distance is
always meters), and `sourceProvider`/`sourceId`/`sourceName` are stored
per sample so a future UI could show "via Health Connect" vs. a specific
wearable's own write, without the backend needing to special-case
Xiaomi or any other vendor.

A genuine, unrelated bug surfaced while testing the 5,000-sample payload
limit: oversized JSON bodies are rejected by Express/body-parser
*before* any NestJS DTO validation runs, as a raw `PayloadTooLargeError`
(`.status = 413`) that isn't an `HttpException` — `AllExceptionsFilter`
was defaulting every non-`HttpException` to a generic 500, silently
hiding the real 413 for this (and every other) endpoint's oversized
payloads. Fixed with a `statusFromRawError()` helper that reads a raw
error's numeric `.status`/`.statusCode` when it's a genuine 4xx, with
its own unit tests (including one confirming an out-of-range status like
502 still correctly falls back to generic 500 rather than being trusted
blindly).

### Flutter: unified `HealthAdapter` interface

`package:health` (v13.3.1) wraps both Health Connect and HealthKit
behind one Dart API, but — following this session's established
interface-over-plugin pattern (`LiveLocationService` in Part 2) — it's
never referenced directly outside a single adapter file. `HealthAdapter`
is an abstract class with concrete default behavior (an
`unsupportedMetrics` getter derived from `supportedMetrics`), and
`PlatformHealthAdapter` — the real, `package:health`-backed
implementation — `extends` it (not `implements`, which would have
dropped the concrete getter; caught by the analyzer and fixed). Real
provider id strings (`androidHealthConnectProviderId` /
`appleHealthProviderId`) intentionally match the pre-existing
`wearableProviderCatalog` constants exactly, since the backend matches
`DeviceConnection.provider` against `HealthSyncCursor.provider` by exact
string on disconnect.

`WearableSyncController` (a `StateNotifier`) orchestrates: availability
detection, permission check/request, an incremental per-metric read
(bounded to a 30-day lookback on a first sync, then reading only what's
newer than the last locally-cached bookmark), upload via
`HealthMetricsRepository`, and updating both the local Drift bookmark
(`CachedHealthSyncStatusRows`, schema v7→v8, the same single-row-cache
pattern established for `CachedCardioSessionRows`) and UI state.
`disconnect()` revokes the platform permission and clears the local
bookmark; the backend's matching cursor clear happens separately, driven
by the existing device-disconnect flow.

A real, pre-existing-adjacent race was found and fixed here, not worked
around: `wearableSyncControllerProvider` originally watched
`authControllerProvider.select((s) => s.user?.id)` to construct the
controller with a fixed `userId`, matching a pattern already used
elsewhere in this codebase (`liveCardioSessionControllerProvider`). But
`ConnectedHealthScreen` calls `checkAvailability()` from `initState`
immediately on mount — and if that call is still in flight when
`AuthController`'s async bootstrap resolves from unauthenticated to
authenticated (a real timing window, not just a test artifact), the
provider tears down and rebuilds the controller mid-await, throwing
`Bad state: Tried to use WearableSyncController after dispose was
called`, and — even once guarded — silently losing whatever state the
first, now-discarded instance had already computed. Fixed by having
`WearableSyncController` take a `Ref` and read the signed-in user id
*lazily* (`_ref.read(authControllerProvider)`, at the point each method
actually needs it) instead of having it baked into the provider's
`watch`-triggered construction — the controller instance is now stable
across the auth bootstrap resolving, and every async state mutation is
additionally guarded with `if (mounted)` as defense in depth. This was
caught by writing and running `connected_health_screen_test.dart`
against the real widget tree (not just the controller in isolation),
which is exactly the kind of race a pure unit test would have missed.

The Connected Health screen (`ConnectedHealthScreen`) shows: platform
name and availability (Connected / Permission needed / Unavailable on
this device — an honest state per metric, never a spinner that never
resolves), a Xiaomi/Mi Fitness note on Android explaining it's
Health-Connect-mediated only, a "Sync now" / "Grant permission" action
depending on state, last-synced-per-metric from the backend's cursors,
every supported metric with its sync status and every unsupported metric
explicitly labeled "Unsupported" (never silently hidden), and a
Disconnect action. It's reachable from the existing (still-simulated)
`WearableConnectionsScreen` via a new "Connected Health" entry-point
card, rather than replacing that screen — the two real providers now
have a real screen; the remaining simulated vendor categories are
untouched.

### Integration points

Wearable connections (`WearableConnectionsScreen` gained the entry point
described above), devices (`DevicesService.remove()` now clears
health-metrics cursors on disconnect), and the same extension-point
philosophy as Part 2: `HealthMetricSample.sourceProvider` is exactly the
kind of provenance field a future Dashboard/Rankings/Community
consumption of synced health data would need, built now rather than
retrofitted later.

### Tests

Backend: `health-metrics.service.spec.ts` (6 tests — sync/dedup via the
unique constraint, cursor advancement, `syncStatus()`,
`clearCursorsForProvider()`), `devices.service.spec.ts` (4 tests, new —
disconnect clearing cursors), `all-exceptions.filter.spec.ts` (5 tests,
new — the raw-4xx-status fix, plus the out-of-range-status fallback
case), `health-metrics.e2e-spec.ts` (5 tests — sync + dedup + cursor
round-trip over real HTTP, a date-range query filter, the 5,000-sample
payload rejected at 413, disconnect clearing the cursor end-to-end, and
confirming the pre-existing `/health` liveness check is completely
unaffected by any of this).

Flutter: `wearable_sync_controller_test.dart` (10 tests — availability
detection in all three states, permission request + immediate sync,
incremental-sync bookmark advancement, zero-sample syncs still advancing
the bookmark, a failing sync recording a recoverable error rather than
throwing, disconnect revoking + clearing), `connected_health_screen_test.dart`
(3 widget tests — the unavailable state, the grant-permission state, and
the connected state listing both supported and unsupported metrics).

### Commands run and results

Backend: `npx prisma format`/`npx prisma validate` clean, `npx tsc
--noEmit` clean, `npx eslint "{src,test}/**/*.ts" --max-warnings=0`
clean, `npx jest --silent` → 209 tests passed (was 194), `npx jest
--config ./test/jest-e2e.json --silent` → 66 tests passed (was 61),
`npx nest build` clean. A local Postgres was reachable in this
environment for this part (`pg_isready` succeeded), so `prisma migrate
dev` and the full e2e suite ran for real rather than being skipped.

Flutter: `flutter pub add health` resolved cleanly (13.3.1), `dart run
build_runner build` regenerated `app_database.g.dart` for schema v8,
`dart format .` clean, `dart analyze` → "No issues found!", `flutter
test` → 242 tests passed (was 229).

### Platform limitations (honest, not fabricated)

Same constraints as Part 2: no Android SDK, no Chrome, no Linux GTK dev
libraries in this environment, so `flutter build apk --debug` was not
attempted and no result is claimed for it. The Android
`AndroidManifest.xml`/iOS `Info.plist` health-permission declarations
required by `package:health` were **not** added in this part — the
architecture (adapter interface, real `PlatformHealthAdapter`, sync
controller, storage, UI) is complete and unit/widget-tested against a
fake adapter, but the actual OS permission dialog appearing, a real
Health Connect/HealthKit read succeeding, and the platform manifest
entries themselves are unverified and not claimed to work at runtime.
`docker compose build`/`up -d`/`ps` were attempted and could not run —
no Docker daemon is reachable in this environment (`docker compose
version` succeeds, but `docker ps` reports "Cannot connect to the Docker
daemon at unix:///var/run/docker.sock").

### Known scope decisions

- **Manifest/`Info.plist` health-permission entries are not yet added.**
  `package:health` requires its own Android permissions (health-data
  read scopes) and an iOS `NSHealthShareUsageDescription`/
  `NSHealthUpdateUsageDescription` pair plus the HealthKit capability in
  the Xcode project — none of which can be meaningfully verified without
  a real device/emulator and Xcode, so they were left as documented,
  unimplemented next steps rather than added speculatively and claimed
  to work.
- **No background/periodic sync.** `sync()` is user-triggered ("Sync
  now") or triggered once on granting permission — there is no
  scheduled background refresh, matching this session's "foreground-only,
  no surprise background activity" posture already established for GPS
  cardio in Part 2.
- **Xiaomi has no vendor-specific adapter.** Only whatever Xiaomi/Mi
  Fitness writes into Health Connect is visible; there is no direct
  Xiaomi integration and none is planned outside an explicitly
  Xiaomi-approved future vendor SDK.

---

## Part 4 — Community profiles, posts, and Reels MVP

Commit: `Implement Community profiles posts and reels MVP`

### What this part is

A real Community tab — profiles, posts (including Reels: a VIDEO post
with a caption, per Scenario 21/22's spec), likes, comments, saves,
follows, blocks, and reports — replacing the Social tab's previous
honest coming-soon placeholder. `COMMUNITY_REELS` was already a FREE
capability from Part 1's addendum; this part is the real implementation
behind it.

### Backend: `community` module

Seven new Prisma models: `CommunityProfile` (the public-facing identity
— deliberately separate from `Profile`, which holds private onboarding
data that must never leak through a Community endpoint), `CommunityPost`
(`mediaType` TEXT/IMAGE/VIDEO, `visibility` PUBLIC/FOLLOWERS/PRIVATE,
`moderationStatus` defaulting to APPROVED with PENDING/REMOVED already
modeled for Part 10's moderation queue, `isTrainerContent`),
`CommunityLike`/`CommunitySave` (both unique on `postId + userId`),
`CommunityComment`, `CommunityFollow` (unique on `followerId +
followingId`), `CommunityBlock` (unique on `blockerId + blockedId`), and
`CommunityReport` (a generic `targetType`/`targetId` row covering
POST/COMMENT/PROFILE reports in one table, always created `OPEN` —
never auto-actioned).

`CommunityService` centralizes every visibility rule in one place
(`buildVisibleWhere` for the feed, `findVisiblePost` for a single post):
a post is visible to its own author unconditionally; otherwise only if
`moderationStatus` is APPROVED, `visibility` is PUBLIC, or `visibility`
is FOLLOWERS and the viewer follows the author — and never at all if
either party has blocked the other. Blocking is a transaction that both
creates the block row and deletes any existing follow in either
direction (`$transaction([blockUpsert, followDeleteMany])`) — a blocked
user should not remain "following" the person who blocked them, or vice
versa. A block check that fails returns the same `NotFoundException` a
nonexistent post/profile would — deliberately not a `ForbiddenException`
— so a blocked user can't distinguish "doesn't exist" from "you blocked
me" (matches ordinary social-app behavior). Likes/saves/follows use
`upsert` against their compound unique constraints, making a repeated
like/follow request idempotent rather than a 409.

### Flutter: `community` feature

`CommunityRepository` is a thin client over every endpoint above.
`CommunityFeedController` (a `StateNotifier`, `family`-keyed by an
optional `authorId` so the same class drives both the general feed and
a single profile's post grid) applies likes/saves optimistically and
rolls back on failure — tapping the heart icon updates instantly rather
than waiting on a round trip, matching the UX bar this session has held
since Part 2's live cardio controller. `PostDetailController` (post +
comment thread) and `CommunityProfileController` (a profile plus
follow/block/report actions) are separate, narrower controllers rather
than one god-controller, following this session's established pattern
of splitting state by what a single screen actually needs.

Screens: `CommunityFeedScreen` (the Community tab's real content, at
the pre-existing `/social` route — the path is unchanged from the old
placeholder per Part 1's "don't remove working routes" rule, only the
tab label and content changed), `SavedPostsScreen`, `CreatePostScreen`
(text/photo/Reel, visibility picker, trainer-content toggle),
`PostDetailScreen` (post + comments, add/delete comment), and
`CommunityProfileScreen` / `EditCommunityProfileScreen` (view a
profile's posts and follower/following counts, or edit your own).
`CommunityPostListView` is a shared scrollable list (loading/error/
empty states, pull-to-refresh, infinite scroll) used by both the feed
and the Saved posts screen so they stay visually identical rather than
duplicating that logic twice. The old `features/social/` placeholder
directory was deleted outright — nothing else referenced it.

### Integration points

Reachable from the Community tab (feed) and a new "Connected Health"-
style entry point isn't needed here since Community *is* the
destination itself. `WearableConnectionsScreen`'s and
`ConnectedHealthScreen`'s established "real feature reachable from an
existing screen" pattern doesn't apply — Community already had its own
nav destination from Part 1's six-destination rename. Post
authorship/visibility now gives Rankings (Part 6) and Ascend Promote
(Part 11) something concrete to build against — `isOwnPost`,
`moderationStatus`, and `visibility` are exactly the fields a future
"boost this post" or "this counts toward your Ranked activity" feature
would need, built now rather than retrofitted later.

### Tests

Backend: `community.service.spec.ts` (15 tests — self-follow/self-block
rejection, blocked-user follow rejection, block severing an existing
follow via the transaction, post/comment delete ownership and
moderation rules, report target-existence validation), `community.
e2e-spec.ts` (16 tests over real HTTP — profile upsert/read with
counts, a 404 for a never-created profile, a TEXT post appearing in the
public feed, a VIDEO Reel rejected without `mediaUrl` then accepted with
one, a FOLLOWERS-only post hidden until the viewer follows then visible
after, a PRIVATE post visible only to its author, idempotent like/
unlike with correct counts, save/unsave and the Saved list being
per-viewer, comments with the post author able to moderate any comment
on their own post, follow/unfollow and followers/following listings,
blocking hiding both profile and posts *and* severing an existing
follow, self-follow/self-block rejection, report filing against a real
vs. a made-up target, and delete-post ownership).

Flutter: `community_feed_controller_test.dart` (8 tests — load, empty
state, load failure, author filtering, optimistic like round-trip,
saved-only unsave removing the post from view, optimistic delete with
rollback on failure), `community_profile_controller_test.dart` (5
tests — load, missing-profile error, follow, block, report),
`post_detail_controller_test.dart` (4 tests — load, add comment
including a blank-body no-op, optimistic like),
`community_feed_screen_test.dart` (3 widget tests — empty state, a
rendered post with caption/like count/author, tapping the like icon).

### Commands run and results

Backend: `npx prisma format`/`npx prisma validate` clean, `npx prisma
migrate dev --name community_profiles_posts_reels_mvp` applied against
the same reachable local Postgres used for Part 3, `npx tsc --noEmit`
clean, `npx eslint "{src,test}/**/*.ts" --max-warnings=0` clean, `npx
jest --silent` → 224 tests passed (was 209), `npx jest --config
./test/jest-e2e.json --silent` → 82 tests passed (was 66), `npx nest
build` clean.

Flutter: `dart format .` clean, `flutter analyze` → "No issues found!",
`flutter test` → 262 tests passed (was 242).

### Platform limitations (honest, not fabricated)

Same as every other part this session: no Android SDK/Chrome/Linux GTK
libs, so `flutter build apk --debug` was not attempted. `docker compose
build`/`up -d`/`ps` were not attempted — no Docker daemon is reachable
in this environment.

### Known scope decisions

- **No in-app media capture or upload pipeline.** `CreatePostScreen`
  requires an already-hosted URL for IMAGE/VIDEO posts and says so
  explicitly in the UI — there is no camera, photo picker, or object
  storage integration in this session. `_MediaPlaceholder` renders a
  labeled icon, never a fake thumbnail.
- **"Native sharing" is not implemented.** Nothing in this part posts to
  Instagram, Facebook, or TikTok, and no such claim is made anywhere in
  the UI or docs — Scenario 21's explicit prohibition on implying
  automatic external-platform publishing.
- **No moderation review queue/admin UI.** `moderationStatus` defaults
  to APPROVED and reports land as OPEN rows with no reviewer workflow
  yet — that's Part 10 (Support and Administration).
- **`isTrainer` is self-declared, not verified.** The edit-profile
  screen says this directly; there is no trainer-application or
  verification flow.
