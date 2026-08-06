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
