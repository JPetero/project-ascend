# Founder Vision Bible

Authoritative statement of what Project Ascend is for and how it must behave.
This document, and the other files in `packages/docs/product/`, override
unstated implementation assumptions. They do **not** override security, law,
platform policy, or verified technical constraints — where a product
requirement here conflicts with one of those, the engineering team escalates
rather than silently picking one.

## Mission

Project Ascend helps people become healthier, stronger, more confident, and
more consistent — through honest guidance, not pressure. It is a companion
for the work, not a replacement for professional care, and not a system
designed to maximize time-in-app for its own sake.

## Non-negotiable product principles

1. **Genuinely useful for free.** A user who never pays gets real workout
   logging, real nutrition logging, a real dashboard, and a real companion —
   not a crippled trial. See `free-premium-policy.md` for exactly where the
   free/premium line sits.
2. **No body shaming, ever.** No implication that a body size, shape, or
   weight is a moral failing. No "before/after" framing that treats a
   starting point as shameful. See `wellness-ethics-bible.md`.
3. **No manipulative engagement.** No fake urgency, no guilt-based push
   notifications, no dark-pattern streak mechanics that punish a missed day
   harder than they reward a kept one, no fabricated social proof (fake
   users, fake activity, fake ranks).
4. **No encouragement of unsafe training.** The app warns rather than
   pushes through when something looks inconsistent with a user's profile,
   recent training, or stated limits.
5. **Explain uncertainty.** Estimates are labeled as estimates. A BMI
   number, a calorie estimate, a recommendation confidence — none of it is
   presented with false precision.
6. **Know the edge of safe scope.** When a question crosses into diagnosis,
   prescription, or a concerning symptom, the app says so and points to a
   qualified professional instead of guessing.
7. **Reward consistency, not perfection.** Streaks and progress framing
   should make a "good enough" day feel like it counted, not treat anything
   short of a perfect week as failure.
8. **Preserve privacy.** Private by default. No public sharing without
   explicit user action. No third-party data sale.
9. **Work across devices.** A user's account, preferences, and history
   follow them — not tied to one phone.
10. **Offline-first for core logging.** Logging a workout set or a meal
    must never require a live connection to succeed locally.
11. **Atlas and Nova are one shared intelligence, two presentations.** Same
    safety rules, same knowledge, same recommendation quality — the
    difference is voice and tone, never substance. See `atlas-nova-bible.md`.

## What premium is for

Premium exists to add **depth, convenience, and personalization** on top of
a genuinely complete free product — never to gate basic health improvement
behind a paywall. Full detail in `free-premium-policy.md`; the short version:
premium makes the *experience* richer, never the *workout* more effective.

## Product order of operations

When priorities conflict, resolve in this order:
1. User safety and honesty.
2. Legal/compliance correctness (flagged for professional review where this
   document provides only a draft).
3. Preserving working functionality and user data.
4. Shipping the specific scenario/feature requested.
5. Polish.

## Non-goals for the current build phase

Wearables depth, Community/Social features, Leaderboards, subscriptions/
payment processing, food/body scanners, live third-party AI provider
integration, and voice integration are intentionally deferred. Where a
scenario requires their *existence* as a placeholder or extension point,
build the honest placeholder — never a fabricated, fully-populated fake
version of the feature.

## Founder Scenarios 11–20 (addendum)

Full detail lives in `user-scenario-bible.md`'s addendum section; the
principles they add to this document are:

12. **Reward consistency and varied healthy behavior, never raw volume or
    danger.** Achievements, leaderboards, and any future ranking system
    must never reward the pattern the deload logic (Scenario 10) exists to
    discourage — e.g. an uninterrupted-streak-only ranking is exactly
    wrong.
13. **Location is coarse by default, everywhere.** GPS cardio,
    leaderboards, and any location-adjacent feature show coarse regions,
    never exact coordinates, to anyone but the user themselves.
14. **Subscription presentation is honest, not persuasive-by-manipulation.**
    Visible, comparable, dismissible, never interrupts core use, no
    countdown/scarcity tricks, no guilt for staying free. Pricing is
    configuration, never a hard-coded literal.
15. **Ascend is not an adult-content platform, at any entitlement tier.**
    No Premium-only NSFW network, no sexual-content feature, regardless of
    age verification.
16. **Accessibility and privacy controls are never premium.** Basic
    schedule accessibility, profile privacy, and blocking/reporting stay
    free at every tier, permanently — not just "for now."
17. **A search engine is not an evidence source.** Any future
    research-mode Assistant feature cites peer-reviewed research,
    professional medical bodies, government health agencies, or
    established universities — never "found via search" as if that were
    itself a quality signal.
18. **External integrations are additive, never load-bearing.** Google
    Play Games Services / Apple Game Center sync (achievements) and any
    similar third-party integration must never block or degrade the
    Ascend-native version of a feature when unavailable.

These sit alongside, and never override, principles 1–11 above.
