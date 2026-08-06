# Wellness & Ethics Bible

The safety and ethical rules every feature, every dialogue line, and every
piece of copy in Project Ascend must follow. This document is authoritative
over tone, safety framing, and the boundary of what the app is allowed to
claim or recommend.

## Scope boundary

Ascend is an **educational fitness and wellness support tool**. It is not a
doctor, physiotherapist, registered dietitian, or other qualified
professional, and it does not replace one. When a user's question or
reported symptom crosses into diagnosis, prescription, or a concerning
medical situation, the app says so plainly and points toward professional
care — it does not guess, and it does not stay silent.

### Concerning symptoms — always stop-and-redirect

Pain, dizziness, difficulty breathing, chest pain, or any symptom in that
category triggers the same response regardless of companion, coaching
style, or feature area: stop the activity, and consider seeking medical
attention if it continues or worsens. This is never softened by a "Tough"
coaching style and never skipped to keep a flow moving.

## Never do this

- **Body shaming.** No implication that a body size, shape, or weight is a
  moral failing. No "before" photo framing that treats a starting point as
  something to be ashamed of.
- **Manipulative engagement.** No fake urgency, no guilt-tripping push
  copy, no streak mechanics designed to make a missed day feel worse than
  a kept day feels good.
- **Unsafe training encouragement.** No pushing through a stated limit, no
  ignoring a reported injury/condition, no praising "no pain no gain"
  extremes.
- **Starvation, purging, or dehydration encouragement**, under any framing
  including "discipline" or "cutting weight fast."
- **Diagnosing a deficiency** (e.g. "you're low in potassium") from logged
  data. The app can say intake of a nutrient looks low relative to a
  general guideline; it cannot diagnose.
- **Prescribing supplementation.** The app does not tell a user to take a
  specific supplement or dose. It can note that a topic is worth discussing
  with a professional.
- **Recommending unsafe rapid weight change.** Fat-loss and muscle-gain
  guidance stays within generally-recognized sustainable ranges; the app
  does not generate an aggressive deficit/surplus on request without at
  least surfacing the safety context.
- **Unsupported "body type" science as a training algorithm.** If terms
  like ectomorph/mesomorph/endomorph appear anywhere in the product, they
  are presented as informal, non-validated descriptions — never as the
  basis for what workout or nutrition plan a user receives.

## BMI — required framing

BMI is calculated from height and weight and shown as one informational
metric among several. It is:
- informational only, never a success score
- never used alone to select a workout or nutrition plan
- always shown with a visible disclaimer

Required (or materially equivalent) disclaimer text:

> BMI is one general screening metric and may not reflect muscle mass,
> body composition, or individual health. Your consistency, strength,
> mobility, energy, and overall wellbeing matter too.

Do not say a high BMI is "totally fine, don't worry about it" (dismissing a
genuine health signal) and do not treat it as alarming or shameful either —
supportive, accurate, and bounded is the target.

## Nutrition guidance for fat-loss goals

For a user with an elevated BMI or a stated fat-loss goal, guidance is
balanced, not reductive. Never respond with only "eat low carb." Use:
appropriate total energy intake, adequate protein, fiber-rich foods,
minimally processed foods, hydration, reasonable portions, sustainable
habits, and awareness of saturated fat and added sugar — as a set, not a
single silver-bullet instruction.

## Consistency over perfection

Progress framing (streaks, weekly completion, dashboard copy) should make a
partially-complete week feel like real progress, not a failure. A missed
day breaks a *display* streak counter, never the user's sense that their
overall consistency matters.

## Media and content policy (Founder Scenario 14)

Ascend is a fitness and wellness platform, not a general social network
and never an adult-content platform, at any entitlement tier.

**Allowed**: normal workout photos, progress photos, meals, achievements,
exercise clips, appropriate athletic clothing.

**Prohibited, without exception, regardless of age verification or
subscription tier**: pornography, explicit sexual activity, sexual
solicitation, sexualized content involving minors, non-consensual
intimate imagery, covert recordings, exploitation, graphic abuse, and any
content whose primary purpose is promoting adult sexual services. Age
verification alone never makes explicit content appropriate for Ascend —
there is no Premium tier or gate that changes this rule.

Progress-photo handling still needs to be privacy-sensitive even under
this strict content policy: private-by-default albums, manual blur/crop
tools, audience controls, a report-and-appeal system, automated
moderation, limited human review only when content is reported or
flagged, strict audit logs, and retention limits.

## Achievement safety (Founder Scenario 11)

Achievement conditions must never reward unsafe daily intense training —
no achievement for training every single day without rest, no achievement
that implicitly discourages a needed rest day. Cardio, mobility, walking,
and recovery activities may count differently than heavy strength volume
toward a milestone. This rule must never contradict the deload logic
(the "Consistency over perfection" section above and Scenario 10) — an
achievement should never celebrate exactly the pattern a deload
recommendation exists to flag.

## Location and camera privacy (Founder Scenarios 12, 16a, 17)

Exact GPS coordinates and precise routes are private by default and must
never be exposed publicly (leaderboards, social features, or anywhere
else) — use coarse regions instead, and let the user hide their route's
start/end points independently. Any future camera/scanner feature
requires explicit consent every time it's used, processes on-device where
practical, minimizes retention, allows deletion, and never uses a user's
images for model training without a separate, explicit consent. None of
this claims Ascend is an emergency service — guidance about concerning
symptoms or injuries always points to seeking real medical attention, and
a camera feature must never claim it can reliably detect an emergency or
delay a user from calling for real help.

## Global and respectful meal guidance (Founder Scenario 16b)

Meal Prep must never stereotype a user based only on their nationality or
assumed circumstances. Ask about budget and ingredient availability
directly instead of guessing from a country or region. Acceptable framing:
"Based on the foods you said are available, [x, y, z] could make an
affordable, protein-containing meal. Nutrition values are estimates and
depend on portions and preparation." Never generalize about what "people
from your country" can or cannot afford, or anything in that register.

## Research and evidence quality (Founder Scenario 19)

Any future research-backed guidance must prioritize peer-reviewed
research, professional medical organizations, government health agencies,
established universities, and official clinical guidance. A general web
search engine is a discovery tool, not an evidence-quality category —
never present "found via search" as equivalent to a cited, quality-labeled
source. The system must admit uncertainty and must never invent a
citation.

## Terms of Service content requirements

The in-product Terms must state, in plain language:
- Ascend provides educational fitness and wellness support
- it does not replace doctors, physiotherapists, registered dietitians, or
  other qualified professionals
- the app will warn users when an activity appears inconsistent with their
  profile, recent training, or stated limits
- users should stop when experiencing pain, dizziness, breathing
  difficulty, chest pain, or other concerning symptoms
- users remain responsible for their own exercise decisions
- the company does not attempt to waive legal responsibility through
  careless or dismissive wording (never "the app is not responsible for
  any harm" or equivalent blanket disclaimers)

**Legal status of the shipped Terms copy**: the Terms content shipped in
this codebase (`services/api/src/modules/legal/` and the onboarding Terms
screen) is a clearly-labeled, product-safe **draft** written to the
requirements above. It is not final, jurisdiction-specific legal language
and requires review by qualified legal counsel before any real launch.
Every place it's rendered says so.
