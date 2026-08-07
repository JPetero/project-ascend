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
- **Community/Social** — superseded by Build Session 7 Part 4: the
  Community tab now has a real profiles/posts/Reels MVP (posting,
  likes, comments, saves, follows, blocks, reports) — see
  `build-session-7.md` Part 4. Still deferred: an in-app camera/photo/
  video capture and upload pipeline (IMAGE/VIDEO posts currently require
  an externally-hosted URL), a moderation review queue/admin UI (Part
  10), and native device-share-sheet sharing of achievements/posts out
  of the app.
- **Leaderboards** — superseded by Build Session 7 Part 6: the Rankings
  tab now has a real opt-in-only FRIENDS/REGION/GLOBAL leaderboard plus
  time-boxed, join-by-choice Challenges — see `build-session-7.md` Part
  6. Scoring is a non-gameable "active days" model (never raw volume,
  never a streak alone), matching Scenario 16a's constraint. Still a
  deliberate simplification: 3 scopes instead of Scenario 16a's full
  local/city/region/state/national/global granularity, and no seasonal
  rewards/badges beyond the season's point total.
- **Subscriptions/payment processing** — superseded in part by Build
  Session 7 Part 7: `CapabilityService.getPlanTier` now reads a real
  per-user `UserSubscription` row (defaulting FREE) instead of a
  hardcoded literal, centralized pricing exists
  (`common/config/pricing.config.ts`), and the Student/Accessibility/
  Senior/Regional Affordability application pipeline is live — see
  `build-session-7.md` Part 7. Still deferred: no billing integration,
  receipt validation, or store integration exists, so nothing can
  actually write a PREMIUM row yet, and there is deliberately no
  self-service "upgrade" endpoint (faking one would mean a fabricated
  payment flow).
- **Scanners** (food/body) — premium capability placeholder only.
- **Live AI provider integration** — Atlas/Nova still use deterministic
  local dialogue; no live LLM call happens anywhere. Build Session 7
  Part 9 added the provider-independent architecture that a live
  integration will plug into (`AiProvider`, its shared safety gate, and
  `LocalDeterministicAiProvider` as the only implementation so far) —
  see `build-session-7.md` Part 9 and `atlas-nova-bible.md`'s "Future:
  live AI" section for the intended architecture this now realizes.
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
- **GPS cardio tracking (12)** — ✅ manual/summary logging shipped in
  `build-session-4.md`; ✅ live GPS tracking (permission flow, start/
  pause/resume/finish/abandon, live distance/duration/pace, route-point
  capture with accuracy filtering and endpoint trimming, interrupted-
  session recovery, offline operation) shipped in `build-session-7.md`
  ("Implement live private GPS cardio"). Still open: conflict-with-
  scheduled-workout handling, wearable-sourced sessions (the `source`
  field already distinguishes `MANUAL`/`LIVE_GPS`/`WEARABLE` for when
  that lands — see the Health Connect/HealthKit foundation), and
  background/killed-app continuation of an active recording (today's
  recovery restores progress up to the last point recorded while the app
  was running, not points that would have been recorded while it wasn't
  — a true background location service is a larger, separate scope).
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
- **Friends, messaging, and joint workouts (15)** — **the friend graph
  implemented in Build Session 8 Part 7**: real mutual `Friendship`
  (search, send/accept/decline/cancel a `FriendRequest`, remove a
  friend, a real friend count) deliberately separate from Community's
  one-directional Follow; blocking someone severs any friendship or
  pending request. Still open: direct messaging (chat) and friend-only
  joint workouts — both build on this same friend graph.
- **Location-based leaderboards (16a)** — ships as an honest coming-soon
  state; real ranking needs the achievement/activity model above plus the
  coarse-region privacy model.
- **Global affordable meal support (16b)** — partially addressed already
  (Meal Prep's existing balanced-guidance rules); the explicit budget/
  ingredient-availability prompt and anti-stereotyping copy review is
  still open.
- **Premium camera and computer vision (17)** — the camera/computer-
  vision processing itself is still explicitly deferred per Scenario
  17's "do not implement this milestone." Build Session 7 Part 8 added
  the honest modular shell around that future work — a real capability
  gate plus a real, single-source-of-truth list of the six future modes
  (Form Coach, Rep Counter, Progress Scan, Food Scan, Sport Capture,
  Outfit Guidance), each its own honest not-yet-built placeholder — see
  `build-session-7.md` Part 8. Full safety-rail requirements remain
  documented in `user-scenario-bible.md` and `wellness-ethics-bible.md`
  ahead of any real camera build.
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
- **Community Reels (22)** — **MVP implemented in Part 4**, moderation
  queue **implemented in Part 10** (posts including Reels, captions,
  likes, comments, saves, follows, reports, blocks, per-post
  visibility, creator/trainer profiles, plus an admin queue that lists
  OPEN reports and can mark a reported post REMOVED — see
  `build-session-7.md` Part 10). **In-app capture/upload, real
  playback, a Following/Discover feed toggle, and reporting a post
  from the feed implemented in Build Session 8 Part 4** — posts now
  attach a real uploaded `MediaAsset` (Media Platform, Part 2) instead
  of requiring an externally-hosted URL, and a VIDEO/"Reel" post plays
  through a real video player in the feed. Still pending: native
  external sharing (Build Session 8 Part 5) and a dedicated full-screen
  vertical swipe Reel viewer (today Reels play inline in the feed).
- **Ascend Promote (23)** — **MVP implemented in Part 11** (Premium
  creators submit a campaign promoting one of their own Community
  posts; every campaign starts PENDING_REVIEW and only an admin can
  activate it; impressions/clicks are recorded into their own tables,
  frequency-capped per viewer per day, and reported back to the
  creator as a metrics view that is structurally separated from
  organic likes/comments — never blended into one number, and proven
  by both a unit test and an e2e test to have zero influence on
  Rankings — see `build-session-7.md` Part 11). Still architecture-only:
  no live billing, so `budgetAmount` is a non-final spend hypothesis,
  never a real charge.
- **Trainer groups (24)** — **free basic tier implemented in Part 5**
  (one owned group per user, a centrally-configured member limit, text/
  image chat, shared workout plans, invitations). Premium expanded tier
  (more/larger groups, announcements, scheduled sessions, assignments,
  distinct roles) is architecture-only until Premium billing exists —
  `TrainerGroupMemberRole` only has OWNER/MEMBER so far.
- **Sports scoring (25)** — manual match creation/confirmation/dispute
  flow; camera-assisted suggestion depends on the Premium Vision Shell.
- **Expanded cardio and Nutrition Library (26)** — new free activity
  types on top of existing GPS cardio; a free educational nutrient
  encyclopedia.
- **Support, companion tone, and pricing (27)** — **Support implemented
  in Part 10**: every user, on every tier, can create a help/bug-
  report/safety-report/accessibility/account-recovery/billing-help/
  moderation-appeal ticket and reply on the thread; an admin queue
  lists and replies to tickets, gated by a new minimal `UserRole`
  (MEMBER/ADMIN) foundation with no self-service promotion endpoint —
  see `build-session-7.md` Part 10. Atlas/Nova tone-and-boundary rules
  (no consciousness claims, no NSFW, no therapy replacement) were
  already true of the existing deterministic dialogue and remain so.
  Centralized, configurable pricing with Student/Accessibility/Senior/
  Regional Affordability programs shipped in Part 7 — still no live
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
