# Free & Premium Policy

Authoritative statement of what's free, what's premium, and how the
distinction is implemented. No payment processing exists yet (explicitly
out of scope for this build phase) — this document defines the
**capability model** so gating can be added later without scattering
`isPremium` checks through the codebase.

## Principle

Premium adds depth, convenience, and personalization on top of a genuinely
complete free product. Premium never makes a workout inherently more
effective and never locks away basic health improvement. If a capability
would materially change how effective someone's training or nutrition is,
it stays free.

## Free (always, for every account)

- complete workout logging (sets, reps, weight, duration, distance, RPE)
- personal workout plans (create, edit, duplicate, archive, delete)
- nutrition logging (food search, custom foods, meal entries, water)
- water tracking
- progress dashboard (workout progress, calendar, streak, personal
  records, BMI informational card)
- Atlas or Nova companion selection
- coaching style selection (Gentle/Balanced/Direct/Tough/Athlete)
- basic companion interactions (deterministic dialogue)
- supported account authentication (email; Google/Apple when configured)
- offline use for core logging
- data export extension point (see `CapabilityService` —
  `EXPORT_DATA` is defined as a capability now so the UI has a stable
  hook, even though export isn't implemented yet)
- **the complete core achievement system** (Founder Scenario 11) —
  cosmetic medal frames/animations/historical analytics may be premium;
  earning the achievements themselves never is
- **GPS cardio tracking**, activity summary, private route history, and
  manual privacy controls (Founder Scenario 12) — future social/joint
  cardio hosting is separate and may be premium
- **Ranked leaderboard opt-in** (Founder Scenario 16a) — off by default,
  free to enable/disable at will
- **profile privacy controls** and **block/report** (Founder Scenarios
  14–15) — a user must never pay to make a profile private or to block/
  report someone
- **basic regional meal suggestions** that respect budget/ingredients/
  restrictions (Founder Scenario 16b)
- **basic Assistant safety guidance**, including the full concerning-
  symptoms protocol (Founder Scenario 19) — never gated behind a
  consumable AI-credit system
- **accessible scheduling** — basic schedule customization and
  accessibility accommodations (Founder Scenario 20)
- **Community Reels** — posting, viewing, liking, commenting, saving,
  following, reporting, and blocking are all free; native external
  sharing to the OS share sheet is free (Founder Scenario 22)
- **Trainer Groups (basic tier)** — one owned small group, a configurable
  three-to-five-member limit, text chat, safe images, shared workout
  plans, and invitations (Founder Scenario 24)
- **expanded cardio activity types** — walking, jogging, running, sprint
  sessions, cycling, hiking, wheelchair mobility, and custom outdoor
  cardio are all free to log (Founder Scenario 26)
- **the Nutrition Library** — the free educational nutrient encyclopedia
  (Founder Scenario 26)
- **manual sports scoring** — creating a match, confirming a score, and
  the disputed-match flow are free (Founder Scenario 25)
- **Support access** — help center, tickets, bug reports, safety reports,
  accessibility feedback, account recovery, billing help, and moderation
  appeals are free for every tier, permanently (Founder Scenario 27)

## Premium (future capabilities — not built this session)

- advanced AI conversations / research mode with citations (live
  provider integration, Founder Scenario 19)
- premium companion voices, additional avatar customization, and richer
  voice conversation (Founder Scenario 18)
- advanced analytics (deeper trend analysis beyond the free dashboard)
- advanced meal planning (AI-generated plans, saved multi-day plans)
- scanner features (food/body scanning, Founder Scenario 17)
- larger media storage (photo/video gallery beyond a free tier limit)
- deeper wearable insights
- **achievement cosmetics** (medal frames, richer animations, historical
  analytics — Founder Scenario 11) — never an exclusive health milestone
- **social joint-session hosting** (a Premium host inviting a limited
  number of Free friends to a joint cardio session — Founder Scenario 12)
- **profile cosmetic customization** beyond the free basics (more avatar
  styles/borders/cover layouts — Founder Scenario 14; privacy controls
  themselves stay free, see above)
- **deep adaptive scheduling** (advanced calendar automation, richer
  recovery analytics, clinician/trainer collaboration — Founder Scenario
  20; basic accessibility stays free, see above)
- **Vision** — the sixth navigation destination and every camera-based
  mode it hosts (Form Coach, Rep Counter, Progress Scan, Food Scan, Sport
  Capture, Outfit Guidance — Founder Scenario 21 and the Premium Vision
  Shell build)
- **camera-assisted sports-scoring suggestions** (manual scoring and
  match confirmation stay free, see above — Founder Scenario 25)
- **advanced cardio analytics** (deeper pace/effort trend analysis on top
  of the free activity types above — Founder Scenario 26)
- **Trainer Groups (expanded tier)** — more groups, larger groups,
  trainer/moderator roles, announcements, scheduled sessions, and
  assignments (Founder Scenario 24; the basic tier above stays free)
- **Ascend Promote** — paid distribution for a creator's own Community
  content; viewing and interacting with promoted content stays free for
  everyone (Founder Scenario 23)

## Pricing and eligibility architecture (Founder Scenario 13)

No live payment processing exists yet. Pricing must be **centrally
configurable and localized** — never hard-coded as a literal scattered
through the app. The configuration model needs to support: an
introductory monthly price, a standard monthly renewal price, an annual
price, a student discount, a disability-access discount, a senior
discount, region-specific affordability programs, and promotional
periods. The Founder's current pricing hypothesis, updated in the Major
Product Expansion session (Founder Scenario 27) and superseding the
original ~USD 4.99/~USD 9.99 draft: approximately USD 12.99 standard
monthly, approximately USD 7.99 for verified-eligible users,
approximately PHP 599 standard, approximately PHP 299 for
verified-eligible users. All of these remain configurable business
assumptions, never values to hard-code as final store prices — see
`services/api/src/common/pricing/` and
`apps/mobile/lib/core/pricing/` for the configuration model (Major
Product Expansion Part 7) once built.

Eligibility programs now explicitly include **Student Access**,
**Accessibility Access**, **Senior Access**, and **Regional
Affordability** (Founder Scenario 27) — Regional Affordability and Senior
Access extend the original student/disability-access model below rather
than replacing it. Eligibility verification is architecture only — no
raw-ID scanning is built. When implemented: use the least intrusive
method available, prefer a trusted third-party verification service over
an in-house document-scanning pipeline, never retain full identity
documents longer than necessary, encrypt verification metadata, keep
eligibility status separate from public profile data (**never publicly
expose eligibility status for any program**, not just disability status),
define an expiration/reverification policy (a six-month reverification
concept is configurable, not mandatory), allow manual appeals, comply
with applicable regional law, and ensure every eligibility discount
avoids creating discriminatory treatment elsewhere in the product.

Subscription UI presentation rules (visible-but-non-intrusive, never
interrupts a workout, always dismissible, no manipulative urgency) live in
`design-bible.md`'s "Subscription presentation" section.

## Implementation model

Backend: `services/api/src/common/entitlements/` defines `PlanTier`
(`FREE` | `PREMIUM`), `AppCapability` (an enum of the capabilities listed
above), and a `CapabilityService.hasCapability(user, capability)` check.
Every capability in the Free list above returns `true` for every plan tier
today — there is no gate yet, by design, since payment processing doesn't
exist. The service exists now so that when premium billing ships, gating a
capability is a one-line change in `CapabilityService`, not a hunt through
every controller and widget for a raw `isPremium` check.

Flutter: `apps/mobile/lib/core/entitlements/` mirrors the same enum and
exposes a `capabilityProvider(AppCapability)` Riverpod provider widgets
read instead of checking a raw premium flag.

## Testing requirement

A test asserts that every capability in the Free list resolves to
available for a plain `FREE`-tier user — protecting against a future
change accidentally gating something that's supposed to stay free.
