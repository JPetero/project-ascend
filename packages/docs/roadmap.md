# Roadmap

Sprint 0 + Sprint 1 delivered the foundation and first vertical slice: auth, onboarding,
companion selection, a sample-data dashboard, and simulated wearable connections, all backed by a
real NestJS API and Prisma schema. Sprint 2 delivered the **Workout Engine**: the exercise
catalog, workout browsing, user-owned workout plans, a full session lifecycle (start/pause/
resume/finish/abandon) with offline-first set logging, deterministic progression suggestions, and
automatic personal-record detection — see [architecture.md](architecture.md#workout-engine-sprint-2)
for how it's built and [synchronization strategy](architecture.md#offline-and-synchronization-strategy)
for how offline logging syncs. The modules below are the next layers to build on top of that
foundation, roughly in the order they unlock the most further work.

## 1. Nutrition tracking

Meal logging (the "Log a meal" quick action already exists as a companion entry point, routing to
Home today) backed by a real food/nutrition data source, macro targets tied to the user's
`primaryGoal`, and the protein/hydration progress rings on the dashboard switching from sample
data to real logged data.

## 2. Real wearable adapters

Implement the `WearableAdapter`/`HealthMetric`/`SyncCursor` design documented in
[wearables.md](wearables.md#planned-architecture-for-real-integrations), starting with Apple
HealthKit and Android Health Connect (the two hubs that cover the widest device range with the
least per-vendor integration work), then layering in direct vendor APIs (Garmin, Fitbit, etc.)
by priority of user demand.

## 3. AI gateway

Replace `LocalCompanionResponseService` with a real AI backend behind the same
`CompanionChatController` interface, so the Ascend Command Center's UI doesn't need to change.
This needs, at minimum: a server-side proxy (never call an LLM provider directly from the mobile
client — that would leak API keys), conversation memory tied to the `aiMemoryEnabled` preference
that already exists, and the same safety/no-diagnosis constraints from the product identity
section enforced server-side, not just in prompt copy.

## 4. Community

Replace the sample-data-only `CommunityScreen` with real posting, following, and a moderation
story. Privacy-by-default (already the stated principle) needs to extend to: who can see a post,
whether workout data attached to a post is shareable-safe (reusing the hide-weight/measurements/
location pattern from `AscendShareService`), and a reporting/moderation queue.

## 5. Subscription

Free-tier-first, as stated in the product identity: essential fitness/health tracking must stay
free. This module adds the premium tier (advanced AI interactions, richer analysis,
customization, cloud capacity) — billing integration, entitlement checks gating specific
features, and restore-purchase flows on both platforms.

## 6. Scanners

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
