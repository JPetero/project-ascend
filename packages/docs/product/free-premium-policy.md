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

## Premium (future capabilities — not built this session)

- advanced AI conversations (live provider integration)
- premium companion voices and additional avatar customization
- advanced analytics (deeper trend analysis beyond the free dashboard)
- advanced meal planning (AI-generated plans, saved multi-day plans)
- scanner features (food/body scanning)
- larger media storage (photo/video gallery beyond a free tier limit)
- deeper wearable insights

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
