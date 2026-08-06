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

## Ideas not yet scheduled

- Data export (capability defined, not implemented).
- Account switching / multi-profile on one device.
- Push-notification strategy that stays consistent with the
  no-manipulative-engagement principle.
- Localization beyond English copy.
- A real achievement/badge catalog built on top of the existing
  `AchievementRule<TContext>` shared abstraction (`common/progress/`).

## How to promote something out of the parking lot

1. Confirm the relevant Bible document(s) don't need updating first.
2. Confirm required external dependencies (credentials, legal review,
   design assets) actually exist — don't build a "live" feature on a
   guess.
3. Move the item into a session's priority list, not straight into code.
