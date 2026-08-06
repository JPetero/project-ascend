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

## Pricing and eligibility architecture (Founder Scenario 13)

No payment processing exists yet. When it ships, pricing must be
**centrally configurable and localized** — never hard-coded as a literal
scattered through the app. The configuration model needs to support (not
necessarily implement yet): an introductory monthly price, a standard
monthly renewal price, an annual price, a student discount, a
disability-access discount, region-specific affordability programs, and
promotional periods. The Founder's current pricing hypothesis (~USD 4.99
intro, ~USD 9.99 regular, reduced pricing for verified-eligible users) is
a configurable business assumption, not a value to hard-code as final.

Eligibility verification (student / disability-access) is architecture
only this session — no raw-ID scanning is built. When implemented: use
the least intrusive method available, prefer a trusted third-party
verification service over an in-house document-scanning pipeline, never
retain full identity documents longer than necessary, encrypt
verification metadata, keep eligibility status separate from public
profile data (never publicly expose disability status), define an
expiration/reverification policy (a six-month reverification concept is
configurable, not mandatory), allow manual appeals, comply with
applicable regional law, and ensure accessibility discounts don't create
discriminatory treatment elsewhere in the product.

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
