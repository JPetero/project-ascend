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
  `build-session-7.md` Part 4. A moderation review queue/admin UI
  shipped in Part 10 (`AdminService`, `apps/admin/src/pages/
  CommunityReportsPage.tsx`), and native device-share-sheet sharing of
  achievements/posts shipped in Build Session 9 Part 3
  (`features/sharing/`, `AscendShareService` wraps `share_plus`'s
  `Share.shareXFiles`). Still deferred: an in-app camera/photo/video
  capture and upload pipeline — IMAGE/VIDEO posts still require an
  externally-hosted URL, not a device-native picker/recorder feeding a
  server upload.
  A dedicated full-screen vertical-swipe Reel viewer is also still open
  — Reels currently play inline in the feed only, never in their own
  swipeable viewer (Build Session 9 Part 20/21's UX audit flagged this
  as the next well-scoped Community polish item, not yet built).
- **Leaderboards** — superseded by Build Session 7 Part 6: the Rankings
  tab now has a real opt-in-only FRIENDS/REGION/GLOBAL leaderboard plus
  time-boxed, join-by-choice Challenges — see `build-session-7.md` Part
  6. Scoring is a non-gameable "active days" model (never raw volume,
  never a streak alone), matching Scenario 16a's constraint. Still a
  deliberate simplification: 3 scopes instead of Scenario 16a's full
  local/city/region/state/national/global granularity, and no seasonal
  rewards/badges beyond the season's point total.
- **Subscriptions/payment processing** — superseded by Build Session 7
  Part 7 and Build Session 9 Part 17/18. `CapabilityService.getPlanTier`
  reads a real per-user `UserSubscription` row (defaulting FREE),
  centralized pricing exists (`common/config/pricing.config.ts`), and
  the Student/Accessibility/Senior/Regional Affordability application
  pipeline is live, including admin review (`GET`/`PATCH
  /admin/eligibility-applications`, `apps/admin/src/pages/
  EligibilityPage.tsx`). As of Part 17/18, real purchase verification
  also exists: `POST /purchases/verify`
  (`services/api/src/modules/purchases`) checks an iOS receipt against
  Apple's `verifyReceipt` endpoint or an Android purchase token against
  the Google Play Developer API, and only a real verified purchase ever
  upserts a `Purchase` row and flips `UserSubscription.tier` to PREMIUM
  — there is still no self-service endpoint that grants PREMIUM without
  a checked receipt/token. The mobile app's `features/purchases/` uses
  the official `in_app_purchase` plugin to query the live catalog and
  drive a real buy flow from SubscriptionScreen; an approved
  affordability application selects the discounted
  `premium.monthly.eligible` product instead of the standard one. No
  live `APPLE_IAP_SHARED_SECRET` or `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
  exists in this environment (no App Store Connect/Google Play Console
  account has been configured this session), and no real store
  connection exists in this Linux CI/dev environment either, so both
  verifiers and the purchase flow are real but unexercised against a
  live store — see `build-session-9.md`.
- **Scanners** (food/body) — premium capability placeholder only.
- **Live AI provider integration** — **shipped in Build Session 9 Part
  15/16**, gated behind the pre-existing `AppCapability.advancedAiConversations`
  (a Free account never attempts the network call, per Scenario 18's
  "free deterministic dialogue... stays free"). Backend: a new
  `AssistantModule` (`POST /assistant/reply`) proxies to Anthropic via
  `@anthropic-ai/sdk` when `ANTHROPIC_API_KEY` is configured — no key
  exists in this environment, so this honestly rejects with "not
  configured" (503) rather than fabricating a reply; see
  `AssistantService`'s doc comment. A single shared system prompt
  (`buildSystemPrompt`) carries the same hard safety rules regardless of
  companion/coaching style, per atlas-nova-bible.md's "a shared
  system-prompt safety layer, not a per-companion one" requirement —
  defense-in-depth only, since the client's `AiProvider.reply()` gate
  already intercepts red-flag/pain input before this endpoint is ever
  called. Mobile: `LiveAiProvider extends AiProvider` (never wraps
  `LocalDeterministicAiProvider` as a base, so `reply()`'s safety gate
  stays structurally un-bypassable), falling back to the local
  deterministic provider on any error — not configured, offline, or a
  server error — so a Premium account never sees a raw error bubble.
  Not exercised against a live Anthropic call in this environment — no
  API key available this session; see build-session-9.md.
  `AiProvider.generateReply` also gained a `history` parameter (an
  additive, backward-compatible widening) so the live provider can give
  the model real conversational context, which
  `LocalDeterministicAiProvider` simply ignores.
  **Deliberately still open: Research Mode's live, source-verified
  answers.** Scenario 19's hard rule — "must never invent a citation...
  must include source verification before it ships" — isn't satisfied by
  an LLM call alone (no real web-search or citation-verification
  pipeline exists), so `LiveAiProvider` does not override
  `researchReply`; it inherits the same honest "not available" default
  `LocalDeterministicAiProvider` already had. Shipping an LLM-generated
  answer with no verified sources would be exactly the fabrication this
  rule exists to prevent — see `build-session-7.md` Part 9 and
  `atlas-nova-bible.md`'s "Future: live AI" section for the architecture
  this now realizes.
- **Voice integration** — **on-device speech input/output shipped in
  Build Session 9 Part 14** (see the Scenario 18 entry below); the
  underlying conversation is still the same deterministic local dialogue
  described above, not a live/generative voice model.
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
  10-item seeded catalog, and an `AchievementsScreen`. A real
  celebration moment shipped in Build Session 5 Part 2
  (`AchievementCelebrationController` + `AchievementCelebrationOverlay`
  — an offline-first, durable queue of newly earned achievements shown
  the moment they're earned, not only next time the screen is opened;
  see `build-session-5.md`). Still open: Google Play Games / Game
  Center sync (explicitly deferred, not "not started" — see that
  session's notes), and Recovery-category achievements once deload has
  a countable trigger.
- **GPS cardio tracking (12)** — ✅ manual/summary logging shipped in
  `build-session-4.md`; ✅ live GPS tracking (permission flow, start/
  pause/resume/finish/abandon, live distance/duration/pace, route-point
  capture with accuracy filtering and endpoint trimming, interrupted-
  session recovery, offline operation) shipped in `build-session-7.md`
  ("Implement live private GPS cardio"); ✅ true active-session
  background continuation (Android foreground service via
  `AndroidSettings.foregroundNotificationConfig`, iOS "Always"-authorized
  background updates via `AppleSettings.allowBackgroundLocationUpdates`,
  both requested only once a session has actually started, never at
  launch) shipped in `build-session-9.md` Part 10 — not physically
  device-tested this session, see that doc's disclosed limitation. Still
  open: conflict-with-scheduled-workout handling, wearable-sourced
  sessions (the `source` field already distinguishes
  `MANUAL`/`LIVE_GPS`/`WEARABLE` for when that lands — see the Health
  Connect/HealthKit foundation), and killed-process continuation — if the
  OS kills the app process outright (not just backgrounds it), the
  foreground service/background updates die with it and recovery still
  only restores progress up to the last point recorded before the kill,
  same as before Part 10.
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
  17's "do not implement this milestone" (no real ML/pose/food-
  recognition model exists anywhere in this codebase). Build Session 7
  Part 8 added the honest modular shell (capability gate + the six-mode
  list); Build Session 8 Part 16 added real camera capture/preview per
  mode, still uploading and analyzing nothing. Build Session 9 Part
  11-13 shipped genuine, non-simulated V1 assists for three of the six
  modes, built entirely on top of existing plumbing rather than any new
  ML work: **Progress Scan** — a real side-by-side comparison of two
  photos the user already saved to a PROGRESS gallery album (Build
  Session 9 Part 2's gallery), no measurement or inference; **Food
  Scan** — capture a reference photo, then log via the existing
  food-search/meal-entry flow (no auto-recognition, no photo attached to
  the entry); **Form Coach** — capture a video, then review it against a
  static, non-personalized general form-cues checklist (no per-rep
  analysis). Rep Counter, Sport Capture, and Outfit Guidance remain
  exactly the capture-only placeholder from Part 16. Full safety-rail
  requirements for a real analysis build remain documented in
  `user-scenario-bible.md` and `wellness-ethics-bible.md`.
- **Richer companion voice (18)** — Build Session 9 Part 14 shipped a
  genuine, on-device voice V1, gated behind the pre-existing
  `AppCapability.premiumCompanionVoices`: tapping the mic uses real
  speech-to-text (`speech_to_text`) to transcribe what the user says,
  which is then handed to the exact same text pipeline and safety gate
  every typed message goes through (`AiProvider.reply`); an opt-in
  "speak replies aloud" toggle uses real text-to-speech (`flutter_tts`)
  to read the companion's reply back. Both are on-device only — no audio
  ever leaves the phone — and both require explicit per-session
  activation, per atlas-nova-bible.md's "no always-listening behavior by
  default" rule. Free typed chat is unaffected and stays free. Still
  future work: the underlying conversation itself remains
  `LocalDeterministicAiProvider`'s deterministic dialogue, not a live/
  generative voice model — that's Part 15/16's live-AI-provider scope,
  separate from this voice I/O layer. Not exercised on a physical device
  — no device available this session; see build-session-9.md.
- **Assistant research mode with citations (19)** — live web-backed
  research with source verification; still not available (see the "Live
  AI provider integration" entry above for the Build Session 9 Part
  15/16 decision to keep this honestly unavailable rather than ship
  unverified LLM answers). Ordinary companion chat now has a real live
  provider option; research mode specifically does not yet.
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
  lists and replies to tickets, gated by a minimal `UserRole`
  (MEMBER/ADMIN) foundation with no self-service promotion endpoint —
  see `build-session-7.md` Part 10. Becoming ADMIN in the first place
  is still that same out-of-band DB write. As of Build Session 9 Part
  19, being ADMIN is only the floor: each of the four admin surfaces
  (community moderation, eligibility review, support queue, promote
  review) additionally requires its own `AdminPermission` grant,
  managed self-service by any admin holding `MANAGE_ADMINS`
  (`GET/POST/DELETE /admin/admins...`, `apps/admin/src/pages/
  AdminsPage.tsx`) — see AdminPermissionGuard's doc comment. Existing
  ADMIN accounts were backfilled with every permission except
  MANAGE_ADMINS at migration time so nobody already trusted lost
  access; the first MANAGE_ADMINS grant for a new admin is, like ADMIN
  itself, an out-of-band DB write. Atlas/Nova tone-and-boundary rules
  (no consciousness claims, no NSFW, no therapy replacement) were
  already true of the existing deterministic dialogue and remain so.
  Centralized, configurable pricing with Student/Accessibility/Senior/
  Regional Affordability programs shipped in Part 7; real Store
  purchase verification (`POST /purchases/verify`, backed by Apple's
  `verifyReceipt` and the Google Play Developer API) shipped in Build
  Session 9 Part 17/18 — see the "Subscriptions/payment processing"
  entry above. Not yet exercised against a live store in this
  environment.

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
