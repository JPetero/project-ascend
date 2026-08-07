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

---

## Part 5 — Trainer Groups messaging MVP

Commit: `Implement messaging and trainer groups MVP`

### What this part is

Free-tier Trainer Groups: one owned group per user, a small centrally-
configured member limit, text/image group chat, shared workout plans,
and invitations — Founder Scenario 24. There is no general 1:1/friends
messaging system in this part (that's Scenario 15, still parked) —
"messaging" here specifically means a group's own chat thread, per the
scenario's own scope.

### Backend: `trainer-groups` module

Five new Prisma models: `TrainerGroup`, `TrainerGroupMember` (unique on
`groupId + userId`, `role` currently OWNER/MEMBER only — the enum is
deliberately left room to add MODERATOR/TRAINER for the Premium-future
tier without a breaking migration), `TrainerGroupInvitation` (unique on
`groupId + inviteeId` — a single row per group+invitee for all time; a
re-invite after a decline/cancel flips the same row back to PENDING via
`upsert` rather than erroring on the unique constraint or creating a
duplicate), `TrainerGroupMessage` (`body`/`imageUrl`, at least one
required — enforced in the service since it's a cross-field rule),
and `TrainerGroupSharedPlan` (a read-only reference to a member's own
`WorkoutPlan`, unique on `groupId + workoutPlanId` — not a copy, so
edits to the sharer's plan are visible to the group and a delete
cascades the share away too).

The free-tier limits (one owned group, five members) live in a single
new file, `common/policy/trainer-group-policy.ts`, per Scenario 24's
explicit "centrally configurable... not hard-coded per-widget"
requirement — both the owned-group check and the member-limit check
(enforced at both invite-creation time and again at accept time, since
the group could fill up in between) read from the same two constants.

Ownership and membership rules mirror the caution already established
in Community: only the group owner may invite or delete the group; the
owner can never be removed (must delete the group instead); only the
owner may remove a *different* member, but any member may remove
*themselves* (leave); only the sharer or the group owner may unshare a
plan. There is no delete-message endpoint in this MVP at all — chat
moderation is deferred alongside Part 10's Community moderation queue.
Route ordering in
`TrainerGroupsController` required care: `GET /trainer-groups/invitations`
and the `/trainer-groups/invitations/:invitationId/...` routes are
registered *before* `GET /trainer-groups/:id`, otherwise Nest would
match a request for the invitations list as `:id = "invitations"`.

### Flutter: `trainer_groups` feature

`TrainerGroupsScreen` (the caller's groups plus pending invitations,
with a "New group" FAB that only appears once the owned-group slot is
free) and `TrainerGroupDetailScreen` (a three-tab Chat/Members/Shared
plans view) are reachable from a new "Trainer Groups" icon in the
Community tab's app bar — Community and Trainer Groups are both under
Founder Scenario 21's single "Community" nav destination, so this
doesn't add a seventh nav item. `TrainerGroupsController` (list +
invitations) and `TrainerGroupDetailController` (one group's members,
chat, shared plans) follow this session's established split-by-screen-
need controller pattern rather than one shared god-controller. Sharing a
plan reuses the existing `workoutPlanRepositoryProvider.list()` (Sprint
2) to let the user pick from their own plans — no new workout-plan code
was needed.

### Integration points

Reachable from Community (the new AppBar icon). Shared workout plans
reuse the existing `WorkoutPlan` model and its ownership rule (only the
plan's own owner may share it) rather than inventing a parallel
plan-sharing model. The same `common/policy/` directory pattern
(centralized, non-hard-coded limits) is now available for any future
part that needs a similar free-tier numeric cap.

### Tests

Backend: `trainer-groups.service.spec.ts` (19 tests — owned-group limit,
member-limit enforcement on invite and on accept, self-invite/self-block-
style rejections, decline vs. accept branching, the accept transaction,
cancel-invitation permission, owner-cannot-be-removed, leave-vs-remove
permission split, empty-message rejection, plan-ownership check on
share, unshare permission), `trainer-groups.e2e-spec.ts` (11 tests over
real HTTP — group creation with owner auto-membership, the owned-group
limit, the full invite → list → accept flow reflected in membership, a
non-owner blocked from inviting, decline leaving no membership *and* the
same invitation reusable afterward, filling a group to its 5-member
limit and then rejecting a 6th invite, sending/listing text and image
messages with an empty one rejected, a non-member blocked from sending
or reading messages, sharing a workout plan with an ownership check and
listing/unsharing it, the owner-can't-be-removed plus leave-yourself
rules, and delete-group ownership).

Flutter: `trainer_groups_controller_test.dart` (3 tests — initial load,
accept, decline), `trainer_group_detail_controller_test.dart` (4 tests
— load, empty-message rejection, send, share/unshare round-trip),
`trainer_groups_screen_test.dart` (3 widget tests — empty state, a
listed group's member count, a pending invitation's accept/decline
actions).

### Commands run and results

Backend: `npx prisma format`/`npx prisma validate` clean, `npx prisma
migrate dev --name trainer_groups_messaging_mvp` applied against the
same local Postgres used for Parts 3–4 (the daemon had stopped between
parts in this environment and was restarted with `sudo service
postgresql start` before this migration), `npx tsc --noEmit` clean,
`npx eslint "{src,test}/**/*.ts" --max-warnings=0` clean, `npx jest
--silent` → 243 tests passed (was 224), `npx jest --config
./test/jest-e2e.json --silent` → 93 tests passed (was 82), `npx nest
build` clean.

Flutter: `dart format .` clean, `flutter analyze` → "No issues found!",
`flutter test` → 272 tests passed (was 262).

### Platform limitations (honest, not fabricated)

Same as every other part this session: no Android SDK/Chrome/Linux GTK
libs, so `flutter build apk --debug` was not attempted. No Docker daemon
reachable, so `docker compose build`/`up -d`/`ps` were not attempted.

### Known scope decisions

- **No message deletion or moderation.** Chat messages can be sent and
  listed but not removed by anyone, including the group owner — a
  moderation affordance for group chat is deferred to Part 10 alongside
  Community's moderation queue.
- **No in-app image capture for chat.** `imageUrl` requires an
  already-hosted URL, the same limitation as Community's Reels — no
  upload pipeline exists this session.
- **Invite by user ID only, no search.** `TrainerGroupDetailScreen`'s
  invite dialog asks for a raw user ID (sourced from the invitee's
  Community profile in the meantime) — there is no member-search/
  autocomplete UI yet.
- **Premium-future roles/scale are not implemented.** `TrainerGroupMemberRole`
  has only OWNER/MEMBER; announcements, scheduled sessions, assignments,
  and a MODERATOR/TRAINER role are Scenario 24's explicitly-deferred
  Premium-future list.

## Part 6 — Rankings seasons and Challenges MVP

Commit: `Implement optional Rankings seasons and challenges MVP`

### What this part is

Opt-in-only Rankings leaderboards and time-boxed, join-by-choice
Challenges — Founder Scenario 16a. Off by default: with no opt-in row,
a user appears on zero leaderboards and no leaderboard is fetchable at
all. Scoring is deliberately never a raw-volume or streak-only metric —
Scenario 16a's explicit constraint — so it can't reward one dangerous,
oversized session or punish a single missed day after a long streak.

### Backend: a shared non-gameable scoring utility

`common/scoring/activity-scoring.util.ts`'s `computeActivitySummary`
is the single source of truth both Rankings and Challenges score
against. It buckets a user's completed workout sessions, cardio
sessions, and meal entries into UTC calendar days over a date range,
then awards 1 point per active day, plus a variety bonus (capped at 2
points/day total) for logging in 2+ of the 3 domains the same day.
Ten workouts in one day still count as exactly one active day — this
is asserted directly in `activity-scoring.util.spec.ts` (7 tests) so
the non-gameable guarantee has a named, permanent test rather than
living only in a docstring.

### Backend: `rankings` module

New Prisma models: `RankingOptIn` (unique on `userId` — one row per
user, `scope` FRIENDS/REGION/GLOBAL, an optional user-typed
`regionLabel` — never an exact coordinate) and `RankingSeason`
(`getOrCreateCurrentSeason` lazily creates a season spanning the
current UTC calendar month the first time anyone asks — no admin
scheduling UI needed for this MVP). `RankingsService.getLeaderboard`
throws `ForbiddenException` if the viewer has no opt-in row at all,
and `BadRequestException` for a REGION request unless the viewer's own
opt-in is REGION-scoped with a `regionLabel` set — a viewer can only
see a regional board they're actually part of. FRIENDS resolves
against the existing Community `CommunityFollow` graph (one-way, not
mutual) rather than a new parallel friend model. This MVP simplifies
Scenario 16a's local/city/region/state/national/global granularity
down to three scopes — an explicit, documented scope reduction, not an
oversight.

### Backend: `challenges` module

New Prisma models: `Challenge` (creator, title, description, a
startsAt/endsAt window) and `ChallengeParticipant` (unique on
`challengeId + userId`). Creating a challenge auto-joins the creator.
`listDiscoverable` excludes challenges already joined and any that
have ended. `getById` gates per-participant progress the same way
Community gates blocked-user visibility: a non-participant gets
`participants: null` rather than an error, so the endpoint's shape
never leaks who's ahead to someone who hasn't joined. `join` is
idempotent (joining twice is a no-op, not an error) and rejects a
challenge that has already ended; `delete` is creator-only. Progress
per participant is `activeDays`/`totalDays` computed via the same
`computeActivitySummary`, over the challenge's own window (clamped to
"now" if the challenge is still running) — identical non-gameable
guarantee as Rankings.

### Flutter: `rankings` and `challenges` features

`RankingsScreen` replaces the Leaderboards tab's coming-soon
placeholder (`RoutePaths.leaderboards`, path unchanged from the
pre-rename tab per the existing route-stability convention). With no
opt-in, it shows an honest opt-in prompt — a `SegmentedButton` for
FRIENDS/REGION/GLOBAL plus a region text field gated to REGION — never
a leaderboard. Once opted in, a `SegmentedButton` scope switcher (with
REGION disabled unless the viewer actually opted in with REGION) drives
`RankingsController`, which lazily fetches the leaderboard only for
the selected scope. `ChallengesScreen` (Mine/Discover tabs, reachable
via a "Challenges" icon in the Rankings app bar, matching the Trainer
Groups entry-point pattern from Part 5) and `ChallengeDetailScreen`
(join/leave/delete, per-participant progress once joined) round out
the feature. `CreateChallengeScreen` uses Flutter's built-in
`showDateRangePicker` rather than two separate date fields.

### Integration points

Reachable from the Rankings tab (already the sixth bottom-nav
destination since the Scenario 21 rename — no new nav item added).
FRIENDS scope reuses Community's follow graph; leaderboard and
challenge-progress entries reuse `CommunityProfile` for display
name/avatar, the same pattern Trainer Groups used in Part 5. Scoring
itself is shared code, not reimplemented per module.

### Tests

Backend: `activity-scoring.util.spec.ts` (7 tests),
`rankings.service.spec.ts` (9 tests), `challenges.service.spec.ts` (10
tests), `rankings.e2e-spec.ts` (9 tests over real HTTP — default-off
status, 403 before opting in, region-requires-regionLabel validation,
a real logged cardio session contributing exactly one activity-day
point, the GLOBAL board excluding a never-opted-in user and never
containing a lat/lng/latitude/longitude match anywhere in the response
body, REGION rejected for a non-REGION viewer, FRIENDS including a
followed+opted-in user, and opting out revoking leaderboard access
again), `challenges.e2e-spec.ts` (8 tests — window validation,
auto-join on create, the discover/mine split from both the creator's
and a stranger's point of view, progress hidden from a non-participant
plus a 404 for a made-up id, join-idempotency and the discover→mine
transition, join rejected on an already-ended challenge, leave, and
delete permission plus the 404 after).

Flutter: `rankings_controller_test.dart` (4 tests — default-off with no
fetch, opt-in loading the chosen scope's board, opt-out clearing it,
and a REGION switch without a region opt-in surfacing an error rather
than crashing), `rankings_screen_test.dart` (2 widget tests — the
opt-in prompt, and a populated leaderboard), `challenges_controller_test.dart`
(2 tests — initial mine/discover load, join moving a challenge between
lists), `challenge_detail_controller_test.dart` (2 tests — load with
participant progress, leave), `challenges_screen_test.dart` (2 widget
tests — empty state, a listed challenge's participant count).

### Commands run and results

Backend: `npx prisma format`/`npx prisma validate` clean, `npx prisma
migrate dev --name rankings_seasons_challenges_mvp` applied against the
same local Postgres used for Parts 3–5 (the daemon had stopped again
between parts in this environment and was restarted with `sudo service
postgresql start`), `npx tsc --noEmit` clean, `npx eslint
"{src,test}/**/*.ts" --max-warnings=0` clean, `npx jest --silent` → 269
tests passed (was 243), `npx jest --config ./test/jest-e2e.json
--silent` → 110 tests passed (was 93), `npx nest build` clean.

Flutter: `dart format --set-exit-if-changed .` clean, `flutter analyze`
→ "No issues found!", `flutter test` → 284 tests passed (was 272).

### Platform limitations (honest, not fabricated)

Same as every other part this session: no Android SDK/Chrome/Linux GTK
libs, so `flutter build apk --debug` was not attempted. No Docker
daemon reachable, so `docker compose build`/`up -d`/`ps` were not
attempted.

### Known scope decisions

- **Three ranking scopes, not six.** FRIENDS/REGION/GLOBAL instead of
  Scenario 16a's full local/city/region/state/national/global
  granularity — an explicit MVP simplification, documented in
  `parking-lot.md`.
- **No seasonal rewards or badges.** A season tracks a label and a
  points/active-days total only; cosmetic season-end rewards are not
  implemented.
- **No challenge invitations.** Challenges are discoverable and
  joinable by anyone, not invite-only — there is no
  "invite a friend to this challenge" affordance yet.
- **No push notifications for challenge milestones or leaderboard rank
  changes.** Both screens are pull/refresh-based only in this MVP.

## Part 7 — Subscription entitlement and affordability foundation

Commit: `Add subscription entitlement and affordability foundation`

### What this part is

Founder Scenario 27's subscription/pricing/support requirements, split
into what's honestly buildable without a payment provider: a real
per-user tier read (replacing `CapabilityService.getPlanTier`'s
hardcoded `PlanTier.FREE` literal), centralized non-final pricing, and
a working Student/Accessibility/Senior/Regional Affordability
application pipeline. Deliberately **not** built: any self-service
"upgrade to Premium" endpoint or button. No billing/payment integration
exists this session (see `parking-lot.md`), so a working upgrade flow
would require either faking a payment success or faking a real payment
integration — both dishonest. What exists now is the seam a future
payment-provider webhook writes into.

### Backend: `common/entitlements` and `subscriptions` module

New Prisma models: `UserSubscription` (unique `userId`, `tier`
FREE/PREMIUM, defaults FREE) and `AffordabilityEligibility` (unique
`userId`, `program` STUDENT/ACCESSIBILITY/SENIOR/REGIONAL, `status`
PENDING/APPROVED/REJECTED, defaults PENDING). Eligibility status is
never joined into any public-profile query — same "private unless
explicitly surfaced" discipline as `RankingOptIn` and Community's block
model. `CapabilityService.getPlanTier` is now `async` and queries
`UserSubscription`, defaulting to `PlanTier.FREE` when no row exists —
the same "absence of a row = the default" pattern used everywhere else
in this schema. It had zero other call sites in the codebase, so the
signature change (sync → async) was a safe, contained edit.
`common/config/pricing.config.ts` centralizes Scenario 27's pricing
hypotheses (≈USD 12.99 standard / ≈USD 7.99 eligible, ≈PHP 599 standard
/ ≈PHP 299 eligible) — the single place any future UI or endpoint reads
from, never a duplicated literal. `SubscriptionsService.applyForEligibility`
upserts on `userId`, so re-applying (after a REJECTED outcome, or to
switch programs) resets the same row back to PENDING rather than
erroring on the unique constraint — one live application per user.

### Flutter: real tier resolution plus a Membership screen

`core/entitlements/capability_provider.dart`'s `planTierProvider` used
to be `Provider<PlanTier>((ref) => PlanTier.free)` — a hardcoded
literal every screen read. It's now backed by a `FutureProvider` that
calls the new `SubscriptionStatusRepository.getMyTier()` (a genuine
`/subscriptions/me` round trip), unwrapped with `.valueOrNull ??
PlanTier.free` so it stays synchronously readable and never throws —
loading and error states both resolve to FREE, matching the "must never
fail open into Premium" rule. Because `planTierProvider` kept its exact
`Provider<PlanTier>` type, no existing call site (`dashboard_screen.dart`'s
subscription card, `VisionScreen`'s capability gate) or test
(`vision_screen_test.dart`'s `planTierProvider.overrideWithValue(...)`)
needed to change — a genuinely real wiring change with zero call-site
churn. The minimal fetch lives in `core/entitlements/` on purpose (not
in a `features/subscriptions` repository) so this core layer never has
to import a feature, matching the layering discipline the rest of
`core/` already follows. A new `features/subscriptions` feature holds
the richer `SubscriptionScreen` (current tier, the pricing table, and
the affordability-program application form), reachable by tapping the
dashboard's existing subscription status card (now genuinely tappable
instead of inert).

### Integration points

`dashboard_screen.dart`'s pre-existing `_SubscriptionStatusCard` — which
already watched `planTierProvider` — now both reflects the real fetch
and pushes to the new Membership screen on tap; no new nav destination
was needed. Every other `AppCapability` check in the app (Vision's gate,
any future premium check) automatically inherits real tier resolution
through the same `planTierProvider`/`capabilityProvider` seam, without
each call site needing to know a network call is now involved.

### Tests

Backend: `capability.service.spec.ts` (6 tests — FREE default with no
row, PREMIUM/FREE from an explicit row, a free capability available
with no row, a premium capability unavailable with no row and available
once PREMIUM), `subscriptions.service.spec.ts` (4 tests — pricing shape,
no-eligibility status, eligibility included once applied, upsert
keyed on userId), `subscriptions.e2e-spec.ts` (5 tests over real HTTP —
centralized USD/PHP pricing with a lower eligible amount than standard,
FREE-with-no-eligibility default, an application reflected on both
`/me` and `/eligibility`, re-applying with a different program replacing
the pending one, and 401 for an unauthenticated request).

Flutter: `subscription_controller_test.dart` (2 tests — initial
status/pricing load, an eligibility application recorded as PENDING),
`subscription_screen_test.dart` (2 widget tests — Free plan plus both
pricing currencies rendered, a pending application shown instead of the
application form).

### Commands run and results

Backend: `npx prisma format`/`npx prisma validate` clean, `npx prisma
migrate dev --name subscriptions_affordability_foundation` applied
against the same local Postgres used for Parts 3–6, `npx tsc --noEmit`
clean, `npx eslint "{src,test}/**/*.ts" --max-warnings=0` clean, `npx
jest --silent` → 279 tests passed (was 269), `npx jest --config
./test/jest-e2e.json --silent` → 115 tests passed (was 110), `npx nest
build` clean.

Flutter: `dart format --set-exit-if-changed .` clean, `flutter analyze`
→ "No issues found!", `flutter test` → 288 tests passed (was 284).

### Platform limitations (honest, not fabricated)

Same as every other part this session: no Android SDK/Chrome/Linux GTK
libs, so `flutter build apk --debug` was not attempted. No Docker
daemon reachable, so `docker compose build`/`up -d`/`ps` were not
attempted.

### Known scope decisions

- **No billing/payment integration.** Nothing in this app can write a
  PREMIUM `UserSubscription` row yet — that's the explicit boundary of
  "foundation," not full Scenario 27. A future payment-provider webhook
  is the intended writer.
- **No self-service upgrade endpoint.** Deliberately omitted rather
  than faked — see "What this part is" above.
- **No eligibility review/approval tooling.** Applications land in
  PENDING and stay there; an admin review queue is Part 10's territory.
- **Pricing is read-only display, not a checkout flow.** The Membership
  screen shows the centralized non-final numbers; it does not attempt
  any store integration.
