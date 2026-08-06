# Roadmap

Sprint 0 + Sprint 1 delivered the foundation and first vertical slice: auth, onboarding,
companion selection, a sample-data dashboard, and simulated wearable connections, all backed by a
real NestJS API and Prisma schema. Sprint 2 delivered the **Workout Engine**: the exercise
catalog, workout browsing, user-owned workout plans, a full session lifecycle (start/pause/
resume/finish/abandon) with offline-first set logging, deterministic progression suggestions, and
automatic personal-record detection — see [architecture.md](architecture.md#workout-engine-sprint-2)
for how it's built and [synchronization strategy](architecture.md#offline-and-synchronization-strategy)
for how offline logging syncs. Build Session 3 delivered the five-tab navigation (Workout, Meal
Prep, Social, Assistant, Leaderboards), a Dashboard rebuilt on real data only, and a Meal Prep
vertical slice (food search, custom foods, per-meal logging, water tracking) — see
[build-session-3.md](build-session-3.md) and
[packages/docs/product/parking-lot.md](product/parking-lot.md) for what's still open in each
area. A Founder addendum then added Scenarios 11–20 (achievements, GPS cardio, fair subscription
presentation, safe social/media policy, location-based leaderboards, global meal support, a
premium camera roadmap, companion voice, Assistant research behavior, and accessible scheduling)
to the product documents — see `user-scenario-bible.md`'s addendum section and
`product/parking-lot.md` for the full deferred list; none of Scenarios 11–20 is implemented yet.
The product documents in [packages/docs/product/](product/) are now the authoritative source for
what ships next and why — this file is kept for the pre-Session-3 modules that predate them.

## 1. Nutrition tracking — foundation shipped in Build Session 3

Meal logging, custom foods, and water tracking are live (see `build-session-3.md`). Still open,
tracked in `packages/docs/product/parking-lot.md`: offline queueing for nutrition writes (online-
first today; the Workout Engine's outbox is the template), saved meals/meal plans, and
deterministic (not AI-generated) meal recommendation cards.

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

## 4. Social

`SocialScreen` (the fifth tab set now renamed from Community, per
`packages/docs/product/design-bible.md`) is an honest coming-soon state — no simulated posts or
activity, replacing the old `CommunityScreen`'s sample-data content. This module replaces it with
real posting, following, and a moderation story. Privacy-by-default (already the stated
principle) needs to extend to: who can see a post, whether workout data attached to a post is
shareable-safe (reusing the hide-weight/measurements/location pattern from
`AscendShareService`), and a reporting/moderation queue. Leaderboards (a separate tab) needs the
same real-data-only treatment before it can replace its own honest coming-soon state.

## 5. Subscription

Free-tier-first, as stated in the product identity: essential fitness/health tracking must stay
free. This module adds the premium tier (advanced AI interactions, richer analysis,
customization, cloud capacity) — billing integration, entitlement checks gating specific
features, and restore-purchase flows on both platforms. See
`packages/docs/product/free-premium-policy.md`'s "Pricing and eligibility architecture" section
(Founder Scenario 13) for the required configurable-pricing and eligibility-verification model —
pricing must never be hard-coded, and eligibility verification should prefer a trusted
third-party service over in-house document scanning.

## 6. Scanners

Camera-based input (e.g., food/barcode scanning, form-check style body estimates, exercise-form
feedback). Must ship with the disclaimers already required in
[security.md](security.md#known-gaps-before-production) and the fuller safety-rail list in
`packages/docs/product/user-scenario-bible.md` Scenario 17 (Founder addendum): no claims of
medical-grade accuracy, no diagnosis of injuries/conditions from an image, no fabricated
body-composition percentages, explicit consent every use, on-device processing where practical,
and a clear statement that it never replaces a human spotter or emergency services.

## 7. Achievements and GPS cardio

Founder Scenarios 11–12: a cross-platform achievement system (idempotent award logic, built on
the existing `AchievementRule<TContext>` abstraction in `common/progress/`) and GPS-based cardio
tracking (walk/run/ride, with schedule-conflict handling and private-by-default route data). Both
ship free at the core; see `packages/docs/product/free-premium-policy.md` for exactly what stays
free versus what premium cosmetics/social hosting may add later. Stranger-based proximity
matching for joint cardio sessions is explicitly out of scope until the full restriction list in
`user-scenario-bible.md` Scenario 12 is implemented — friend-only joint sessions are the intended
first cut.

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
