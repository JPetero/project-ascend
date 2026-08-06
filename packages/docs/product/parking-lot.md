# Parking Lot

Ideas, deferred scope, and explicitly-out-of-scope-for-now items, tracked so
they aren't lost or accidentally half-built. Nothing here should be started
without first updating the relevant Bible document and confirming it's
actually in scope for the current session.

## Explicitly deferred for this build phase

- **Wearables depth** — connection UI exists (`features/wearables/`);
  deeper sync (steps, sleep, recovery feeding the dashboard) is deferred
  until real device data sources are integrated. Never fabricate these
  values in the meantime.
- **Community/Social** — the Social tab ships as an honest coming-soon
  state this session. Posting, following, moderation, and real activity
  feeds are future work.
- **Leaderboards** — ships as an honest coming-soon state. Real ranking
  requires a real activity/points model that doesn't exist yet.
- **Subscriptions/payment processing** — the capability model
  (`free-premium-policy.md`) is ready to receive a `PlanTier`, but no
  billing integration, receipt validation, or store integration exists.
- **Scanners** (food/body) — premium capability placeholder only.
- **Live AI provider integration** — Atlas/Nova use deterministic local
  dialogue. See `atlas-nova-bible.md` for the intended architecture when
  this is picked up.
- **Voice integration** — not started; existing "coming soon" UI markers
  in the companion feature predate this session and remain accurate.
- **Photos/videos gallery** — dashboard shows an honest unavailable state;
  real media storage is future work.
- **Friends** — dashboard shows an honest unavailable state; depends on
  Social shipping first.
- **Google/Apple OAuth activation** — architecture (AuthIdentity model,
  linking service, DTOs) is built and documented in
  `user-scenario-bible.md` Scenarios 2–3, but not wired to a live
  provider without real credentials. See `services/api/docs/` (or the
  relevant setup doc referenced from the scenario) for what's needed to
  activate it.
- **Saved meals / multi-day meal plans** — Meal Prep ships with logging,
  targets, and deterministic recommendation cards; saved-meal and
  meal-plan extension points exist as documented stubs, not full features.
- **AI-generated meal plans** — deferred until the AI milestone; Meal Prep
  uses deterministic, rule-based recommendation cards for now.

## Founder Scenarios 11–20 (addendum) — deferred items

Full requirements for all of these live in `user-scenario-bible.md`'s
Scenarios 11–20 addendum. None are implemented this session; only
documentation and (where explicitly noted elsewhere) small, safe
extension points exist.

- **Achievements (11)** — ✅ core build-out shipped in `build-session-4.md`:
  `Achievement`/`AchievementAward` models, an idempotent
  `AchievementsService` (workout/streak/PR/nutrition/cardio triggers), a
  10-item seeded catalog, and an `AchievementsScreen`. Still open:
  Google Play Games / Game Center sync (explicitly deferred, not
  "not started" — see that session's notes), a proper celebration
  moment surfaced at the point an achievement is newly earned (rather
  than only visible next time the screen is opened), and Recovery-
  category achievements once deload has a countable trigger.
- **GPS cardio tracking (12)** — manual/summary logging (activity type,
  duration, distance/elevation/calorie estimate, privacy-flag model)
  shipped in `build-session-4.md`. Still open: the actual location
  permission flow, live route recording, conflict-with-scheduled-workout
  handling, and wearable-sourced sessions — the `CardioSession` schema's
  privacy flags are already shaped for when that lands.
- **Stranger proximity matching (12)** — explicitly not to be built
  without re-reading the full restriction list in `user-scenario-bible.md`:
  coarse zones only, mutual opt-in, expiring matches, instant block/
  report/leave/disable, no minors, friend-only joint sessions preferred
  as the actual MVP over any stranger-matching feature.
- **Subscription/pricing configuration (13)** — centrally configurable,
  localized pricing model; no payment processing yet.
- **Student/disability-access eligibility verification (13)** — prefer a
  trusted third-party verification service; no in-house raw-ID scanning.
- **Profile customization and safe media (14)** — free basics (bio,
  default avatar, one cover image, privacy controls) plus a moderation
  pipeline before any user media upload ships; premium cosmetics are a
  separate, later layer. Privacy controls ship free from day one of this
  feature, not added later.
- **Friends, messaging, and joint workouts (15)** — full social graph,
  chat, and moderation system; friend-only joint workouts as the initial
  scope, not stranger-based.
- **Location-based leaderboards (16a)** — ships as an honest coming-soon
  state; real ranking needs the achievement/activity model above plus the
  coarse-region privacy model.
- **Global affordable meal support (16b)** — partially addressed already
  (Meal Prep's existing balanced-guidance rules); the explicit budget/
  ingredient-availability prompt and anti-stereotyping copy review is
  still open.
- **Premium camera and computer vision (17)** — explicitly deferred, full
  safety-rail requirements documented in `user-scenario-bible.md` and
  `wellness-ethics-bible.md` ahead of any build.
- **Richer companion voice (18)** — premium voice conversation; free
  deterministic dialogue is what exists today and stays free.
- **Assistant research mode with citations (19)** — live web-backed
  research with source verification; today's Assistant is deterministic
  local dialogue only.
- **Deep adaptive scheduling (20)** — advanced calendar automation,
  clinician/trainer collaboration tools; basic accessible scheduling
  stays free and is a smaller, nearer-term item.

## Founder Scenarios 21–27 (addendum) — Major Product Expansion session

Full requirements for all of these live in `user-scenario-bible.md`'s
Scenarios 21–27 addendum. Unlike the 11–20 addendum, most of these are
being actively built across this same session's later parts — this list
is updated as each part actually lands (see `build-session-7.md` for the
authoritative, verified record of what shipped vs. what's still
architecture-only below).

- **Six-destination navigation and Vision (21)** — label/route rename
  (Train/Fuel/Community/Ascend AI/Rankings) plus a sixth, Premium-gated
  Vision destination.
- **Community Reels (22)** — reels, captions, likes, comments, saves,
  follows, reports, blocks, visibility, native external sharing,
  moderation, creator profiles, trainer content.
- **Ascend Promote (23)** — transparent paid distribution architecture;
  no live billing.
- **Trainer groups (24)** — free basic tier (one group, small configurable
  limit, chat, safe images, shared plans, invitations); Premium expanded
  tier is architecture-only until Premium billing exists.
- **Sports scoring (25)** — manual match creation/confirmation/dispute
  flow; camera-assisted suggestion depends on the Premium Vision Shell.
- **Expanded cardio and Nutrition Library (26)** — new free activity
  types on top of existing GPS cardio; a free educational nutrient
  encyclopedia.
- **Support, companion tone, and pricing (27)** — help center/ticket/
  bug-report/safety-report/accessibility/billing-help/appeal surfaces;
  Atlas/Nova tone-and-boundary rules (no consciousness claims, no NSFW,
  no therapy replacement); centralized, configurable pricing model with
  Student/Accessibility/Senior/Regional Affordability programs — no live
  store billing.

## Ideas not yet scheduled

- Data export (capability defined, not implemented).
- Account switching / multi-profile on one device.
- Push-notification strategy that stays consistent with the
  no-manipulative-engagement principle.
- Localization beyond English copy.

## How to promote something out of the parking lot

1. Confirm the relevant Bible document(s) don't need updating first.
2. Confirm required external dependencies (credentials, legal review,
   design assets) actually exist — don't build a "live" feature on a
   guess.
3. Move the item into a session's priority list, not straight into code.
