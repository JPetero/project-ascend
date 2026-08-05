# Roadmap

Sprint 0 + Sprint 1 delivered the foundation and first vertical slice: auth, onboarding,
companion selection, a sample-data dashboard, and simulated wearable connections, all backed by a
real NestJS API and Prisma schema. The modules below are the next layers to build on top of that
foundation, roughly in the order they unlock the most further work.

## 1. Exercise catalog

A structured, searchable library of exercises (name, muscle groups, equipment required,
difficulty, instructional media) that workout plans and logging both depend on. Needed before
"Workout planning/logging" below can be more than a coming-soon shell.

## 2. Workout planning & logging

Turn the current `WorkoutSchedule` (days/duration preference, collected in onboarding) into
actual generated or user-built workout plans, plus a logging flow (sets, reps, weight, RPE) that
writes through the offline-first outbox described in [architecture.md](architecture.md#offline-foundation-drift).
Replaces the current `WorkoutScreen` coming-soon shell.

## 3. Nutrition tracking

Meal logging (the "Log a meal" quick action already exists as a companion entry point, routing to
Home today) backed by a real food/nutrition data source, macro targets tied to the user's
`primaryGoal`, and the protein/hydration progress rings on the dashboard switching from sample
data to real logged data.

## 4. Real wearable adapters

Implement the `WearableAdapter`/`HealthMetric`/`SyncCursor` design documented in
[wearables.md](wearables.md#planned-architecture-for-real-integrations), starting with Apple
HealthKit and Android Health Connect (the two hubs that cover the widest device range with the
least per-vendor integration work), then layering in direct vendor APIs (Garmin, Fitbit, etc.)
by priority of user demand.

## 5. AI gateway

Replace `LocalCompanionResponseService` with a real AI backend behind the same
`CompanionChatController` interface, so the Ascend Command Center's UI doesn't need to change.
This needs, at minimum: a server-side proxy (never call an LLM provider directly from the mobile
client — that would leak API keys), conversation memory tied to the `aiMemoryEnabled` preference
that already exists, and the same safety/no-diagnosis constraints from the product identity
section enforced server-side, not just in prompt copy.

## 6. Community

Replace the sample-data-only `CommunityScreen` with real posting, following, and a moderation
story. Privacy-by-default (already the stated principle) needs to extend to: who can see a post,
whether workout data attached to a post is shareable-safe (reusing the hide-weight/measurements/
location pattern from `AscendShareService`), and a reporting/moderation queue.

## 7. Subscription

Free-tier-first, as stated in the product identity: essential fitness/health tracking must stay
free. This module adds the premium tier (advanced AI interactions, richer analysis,
customization, cloud capacity) — billing integration, entitlement checks gating specific
features, and restore-purchase flows on both platforms.

## 8. Scanners

Camera-based input (e.g., food/barcode scanning, form-check style body estimates). Must ship with
the disclaimers already required in [security.md](security.md#known-gaps-before-production): no
claims of clinical accuracy, no diagnosis, and honest framing of what a camera-based estimate can
and can't tell the user.

## Also planned, not yet scheduled

- **Session/device management UI** — the backend already tracks `deviceName` per refresh token;
  a "Sign out of other devices" screen in Profile is mostly a UI task once needed.
- **Email verification & password reset** — see [security.md](security.md#known-gaps-before-production).
- **Voice input** — the microphone button in the Ascend Command Center and companion quick
  actions sheet are UI placeholders today; Android App Actions and Apple App Intents/Shortcuts
  integration would let a user invoke Ascend hands-free.
- **Instagram publishing via official Meta APIs** — today `AscendShareService` hands a rendered
  achievement card to the native OS share sheet. Direct in-app publishing to Instagram would use
  Meta's Content Publishing API, which requires a Business/Creator account and Meta app review —
  worth doing once sharing volume justifies the integration cost.
