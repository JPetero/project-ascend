# Design Bible

Authoritative UI/UX rules for Project Ascend, on top of the existing
`core/design_system/` component library (Ascend* widgets, spacing, color,
typography tokens). This document governs *how* those components are used
in product flows; it does not replace the design system itself.

## Navigation

**Six primary destinations, in this exact order** (Founder Scenario 21,
`user-scenario-bible.md`): Train, Fuel, Community, Ascend AI, Rankings —
all free — plus Vision as a sixth, Premium-gated destination. This is the
authoritative order — do not reorder or rename without a product-doc
update here first. These are renames of the original five tabs (Train =
formerly Workout, Fuel = formerly Meal Prep, Community = formerly Social,
Ascend AI = formerly Assistant, Rankings = formerly Leaderboards); the
underlying routes and screens are unchanged by the rename, only the
visible label and icon. Vision is genuinely new — see Scenario 21 and the
Premium Vision Shell build for its content. A Free user sees Vision exists
(an honest, non-hidden sixth destination) but tapping it shows a real
locked/upgrade state, never a faked preview of camera output. **Vision
does not affect the free five**: Train, Fuel, Community, Ascend AI, and
Rankings must keep working exactly as before for every user regardless of
tier.

**Profile is not a tab.** A profile icon appears in the upper-right of the
primary app shell's app bar. Tapping it opens the Dashboard/Profile area as
a pushed route (not a shell branch), so:
- a back button appears in the upper-left of the Dashboard screen
- Android system back and the Android back gesture both work
- returning goes to wherever the user came from, not a hardcoded location
- no duplicate route entries accumulate on repeated open/close

**Unavailable features** (any destination or sub-feature not yet built —
this applied to Community and Rankings before their MVPs shipped this
session, and still applies to anything not yet built within them, plus
Vision until the Premium Vision Shell exists) get a polished, honest
coming-soon or locked state: an icon, a one-line explanation of what's
coming or why it's locked, and nothing fabricated — no fake users, fake
ranks, fake activity, fake photos. See `AscendEmptyState` for the existing
component to build this from.

## States every data-bearing screen must handle

1. **Loading** — a real loading indicator, not a blank frame.
2. **Empty** — an honest "nothing here yet" state with a clear next action
   where one exists.
3. **Error** — a retry affordance, not a silent failure or a raw exception.
4. **Offline** — where the feature supports offline use (workout logging,
   nutrition logging), the UI reflects "saved locally, will sync" rather
   than blocking or erroring.

## Accessibility

- Every interactive element gets a `Semantics` label where the visible
  text doesn't already describe the action clearly (existing components
  like `AscendCard.semanticLabel` already support this — use it).
- Respect the user's reduced-motion preference (`PreferencesModel
  .reducedMotion`) everywhere an animation is optional.
- Support both light and dark theme for every new screen — never hardcode
  a color that only works in one theme; use `Theme.of(context)`.
- Text must scale with the system font-size setting (avoid fixed-height
  containers that clip scaled text).

## Tone in copy

- No body-shaming language, ever — see `wellness-ethics-bible.md`.
- No urgency/scarcity manipulation ("last chance", countdown timers on
  ordinary features).
- Numbers presented as estimates (BMI, calorie targets, macro estimates)
  always carry a short, visible qualifier — not just in a tooltip a user
  has to find.
- Celebration copy (workout completion, streaks, PRs) is warm but not
  exaggerated, and never claims something the data doesn't support.

## BMI display

BMI appears as one informational card among several, never as a hero
metric, never as a score, never with a color-coded "good/bad" treatment.
It always carries a visible disclaimer (see `wellness-ethics-bible.md` for
exact required wording) and is never the sole input to a workout or
nutrition recommendation shown elsewhere in the product.

## Progress and percentages

Any percentage or progress ring must have an explicit, discoverable
definition — e.g. "3 of 5 planned sessions this week" behind a "workout
completion percentage" ring. Never show an unexplained number that mixes
unrelated metrics (e.g. don't blend workout completion and sleep quality
into one unlabeled score).

## Leaderboard and location UI (Founder Scenario 16a)

Ranked mode is off by default and always user-toggleable. Any UI showing a
region (local/city/region/national/global) shows a coarse, human-readable
place name — never raw coordinates, never precise-enough-to-dox detail.
Ranking criteria shown to the user must be genuinely transparent (what's
being measured, not a black-box score). A private profile that opts into
Ranked mode shows only the minimal public card it explicitly agreed to —
never the full profile.

## Subscription presentation (Founder Scenario 13)

Subscription UI is visible but non-intrusive: it lives on the dashboard
and in appropriate settings screens, never as an interstitial over an
active workout or a blocker in front of core logging. It always shows a
clear Free-vs-Premium comparison, current and renewal pricing, trial
terms, and a dismiss action. No countdown timers, no fake scarcity, no
copy implying a free user is less committed — see `wellness-ethics-bible.md`
for the full manipulative-engagement rule this extends.

## Achievement UI (Founder Scenario 11)

An achievement card shows its icon/medal asset, title, description, and
(for multi-step achievements) a progress indicator using the same
`AscendProgressRing`/percentage-definition conventions as the rest of the
app — never an unexplained fraction. Earned achievements show their
earned date. Category/rarity is a visual grouping, not a paywall — every
free user sees the complete core achievement set on their profile.

## Componentization

Prefer extending `core/design_system/widgets/` over hand-rolling one-off
styled containers in feature code. If a new pattern (e.g. a coming-soon
card, a disclaimer banner) is used in more than one place, promote it to a
shared widget.
