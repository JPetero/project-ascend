# User Scenario Bible

Ten founder scenarios, each converted into a concrete specification. These
are authoritative for the corresponding feature's behavior. Status notes
reflect what ships in the session that introduced this document
(`build-session-3.md`) — check that file for the real, verified state.

---

## Scenario 1 — Terms and safety

**User story**: As a new user, I read the Terms and Conditions before using
Ascend, and I understand what the app is and isn't, and what I'm
responsible for.

**Flow**: Registration → Terms screen (blocking, must accept to continue) →
account created → onboarding.

**UI requirements**: A dedicated Terms screen showing the safety-framed
copy (see `wellness-ethics-bible.md`), an explicit "I have read and agree"
acceptance action (not a pre-checked box), and a visible "draft — pending
legal review" label. Re-shown, with a clear "what changed" framing, when
the server's current terms version differs from the user's last-accepted
version.

**Backend requirements**: `LegalDocument` (versioned Terms/Privacy content)
and `LegalAcceptance` (per-user record: version accepted, timestamp, which
document, optional region). `POST /legal/accept`, `GET /legal/status`
(current version + whether the signed-in user needs to reaccept).
Registration itself requires a terms version + acceptance timestamp in the
payload (can't create an account without it).

**Data requirements**: acceptance is stored server-side, keyed to the user,
never solely on-device (a reinstall must not lose the record). Optional
country/region metadata captured if available from the client, never
required.

**Safety requirements**: no dismissive "not responsible for any harm"
wording anywhere in the copy. The four required points (educational
support, not a replacement for professionals, stop-on-symptom guidance,
user responsibility) are all present.

**Acceptance criteria**:
- registering without an accepted terms version is rejected
- accepting is recorded with version + timestamp, retrievable later
- bumping the server's terms version flags every existing user as needing
  to reaccept on next relevant check
- the draft/legal-review label is visible on the rendered Terms content

**Tests**: backend e2e — register without acceptance rejected; register
with acceptance recorded and retrievable; version bump flags reaccept
needed; accept endpoint is idempotent-safe for a repeat call with the same
version.

---

## Scenario 2 — Google sign-in

**User story**: As a user, I can sign in with Google, and I understand my
progress lives in my Ascend account, not "inside Gmail."

**Status this session**: architecture only. No Google OAuth client
credentials are configured in this environment, so no live Google sign-in
button is wired to a real provider. Email authentication remains fully
supported and unchanged.

**UI requirements**: the sign-in/register screens document (in a short
inline note, not a dead button) that additional sign-in providers are
coming; no button that looks tappable but silently fails.

**Backend requirements**: the `AuthIdentity` model (Scenario 3) is
provider-agnostic and already supports a `GOOGLE` provider value; a
`GoogleAuthService` interface documents the intended token-verification
flow (verify Google ID token → find-or-create `AuthIdentity` → issue
Ascend session) without a live implementation.

**Data requirements**: none beyond `AuthIdentity` (Scenario 3).

**Documentation**: `services/api/src/modules/auth/providers/google/
README.md` (setup doc) lists exactly what's needed to activate it
(OAuth client ID/secret, redirect URIs, mobile SDK config) and where it
plugs in.

**Acceptance criteria**: email auth is unaffected; the Google architecture
compiles and is documented; nothing claims to be operational that isn't.

**Tests**: none required for an unimplemented live integration; existing
email-auth tests must still pass unmodified.

---

## Scenario 3 — Apple linking and cross-device sync

**User story**: As a user who signed up with Google, I can later link Apple
and sign in with either on any device, landing in the same account with all
my progress.

**Data model**:
```
AuthIdentity
- id
- userId          (FK -> User, cascade delete)
- provider        (EMAIL | GOOGLE | APPLE)
- providerSubject (provider's stable user id; for EMAIL, the email itself)
- providerEmail   (nullable — the email the provider reported, if any)
- createdAt
- lastUsedAt
- unique(provider, providerSubject)
```

**Requirements**:
- one `(provider, providerSubject)` pair belongs to exactly one
  `userId`, enforced by a unique constraint
- linking a new identity to an already-authenticated user requires that
  user to already be signed in (authenticated confirmation) — no
  unauthenticated "link by email match" flow
- two identities are never silently merged into one account because they
  share an email address; a matching email on a *different* existing
  account surfaces a conflict instead of auto-merging
- all progress (workout, nutrition, preferences) stays keyed to the one
  `userId` regardless of how many identities are linked to it

**Backend requirements**: `AuthIdentityService` with `findByProvider`,
`linkIdentity(userId, provider, subject, email)` (rejects if the pair is
already linked to a different user), and existing email/password login
continues to work by treating it as an `AuthIdentity` with
`provider = EMAIL`.

**Acceptance criteria**:
- linking Apple to an account that already has a Google identity succeeds
  and both work as login going forward
- attempting to link an identity already claimed by a different user is
  rejected with a clear conflict error, not a silent merge
- login via either linked identity resolves to the same `userId` and the
  same data

**Tests**: backend unit/e2e — link success, link conflict (already
claimed), login via each linked identity resolves to the same user,
existing email users get a backfilled `EMAIL` identity row via the
migration.

**Status this session**: model, service, migration, and tests ship. Apple
OAuth itself is not wired to a live provider (no credentials) — same
documented-architecture status as Scenario 2's Google flow.

---

## Scenario 4 — Standard email

**User story**: As a user without a Google or Apple account, I register
with any valid email and password.

**Status**: already implemented and tested prior to this session
(`AuthModule`, `register`/`login` endpoints, Flutter register/sign-in
screens). This scenario's requirement is **preserve and keep tested** —
verified unchanged by this session's full test run, and now modeled as an
`AuthIdentity` row with `provider = EMAIL` per Scenario 3 without changing
its external behavior.

---

## Scenario 5 — Companion selection

**User story**: After creating an account, I choose Atlas or Nova, and my
companion welcomes me and explains what Ascend is.

**Status**: already implemented (`OnboardingCompanionPage`,
`Companion` preference, synced via `PreferencesModel`). This session
verifies the welcome copy avoids exaggeration and confirms the choice is
changeable later in Settings (Scenario 6 adds the coaching-style control
alongside it).

**Acceptance criteria**: companion choice persists in preferences, syncs
across devices via the existing preferences sync, and is changeable from
Settings at any time — not a one-time onboarding-only choice.

---

## Scenario 6 — Companion vs. coaching style

**User story**: As a male user, I can choose Nova. As a female user, I can
choose Atlas. Either way, I separately choose how direct or gentle my
coaching feels.

**UI requirements**: onboarding's companion step is followed by (or
combined with, space permitting) a coaching-style picker showing all five
styles with a one-line description each — no style labeled by sex.
Settings gets the same picker for later changes, plus a tone-intensity
slider (1–5).

**Data requirements**: `Preference.coachingStyle` (enum, default
`BALANCED`), `Preference.toneIntensity` (int 1–5, default 3). Additive
migration.

**Backend requirements**: `PreferencesService` accepts and validates the
new fields; existing preference rows get the defaults via the migration
(no backfill script needed — column defaults handle it).

**Safety requirements**: see `atlas-nova-bible.md` — every style respects
the same hard limits.

**Acceptance criteria**: selecting Nova as a male user (or Atlas as a
female user) is unremarkable — no gating, no warning, no different content
path. Coaching style changes take effect immediately and sync across
devices.

**Tests**: backend — preference update accepts valid style/intensity,
rejects invalid enum values, rejects out-of-range intensity. Flutter —
settings screen renders all five styles unconditionally regardless of the
user's recorded sex, selecting one persists it.

---

## Scenario 7 — Lifestyle, body profile, and BMI

**User story**: During onboarding I provide the information Ascend needs
to personalize training, including my height and weight, and I see my BMI
presented respectfully with context.

**Status**: onboarding already collects date of birth, sex for
calculations, height, weight, goal, experience, equipment, and schedule
(`OnboardingBodyMeasurementsPage`, `OnboardingPersonalDetailsPage`,
`OnboardingExperienceEquipmentPage`, `OnboardingSchedulePage`). **Gap this
session**: BMI is not calculated or displayed anywhere.

**UI requirements**: a BMI informational card (dashboard, see Part 5) shows
the computed value, a plain-language category label, and the required
disclaimer (`wellness-ethics-bible.md`) inline — not hidden behind a tap.

**Backend requirements**: `ProfilesService` (or a small
`BodyMetricsService`) computes BMI from `heightCm`/`weightKg` on read; not
stored as a persisted "score" field (it's derived, and derived values
recompute correctly if height/weight change — storing it would risk
staleness).

**Safety requirements**: BMI is never returned or rendered without
category + disclaimer together. "Body shape" preferences, if ever added,
are informal descriptors only — not implemented this session (no current
use case needs them; see `parking-lot.md`).

**Acceptance criteria**: BMI card only renders when both height and weight
are present; shows a graceful "add your height and weight" prompt
otherwise (never a fabricated number).

**Tests**: backend — BMI calculation unit tests across representative
height/weight pairs, and a null-safe case when either is missing. Flutter
— BMI card renders the disclaimer and category label; renders the
missing-data prompt when profile data is incomplete.

---

## Scenario 8 — Guided onboarding and workout setup

**User story**: After my profile is complete, my companion introduces the
app's navigation and how to start a workout.

**Status**: onboarding already collects goal, equipment, and schedule
(`OnboardingGoalPage`, `OnboardingExperienceEquipmentPage`,
`OnboardingSchedulePage`) and `OnboardingCompletionPage` exists as the
final step. **This session**: `OnboardingCompletionPage` copy is reviewed
to reference the current five-tab navigation (Workout, Meal Prep, Social,
Assistant, Leaderboards) and the profile icon, replacing any references to
the prior tab set, so onboarding doesn't describe a navigation structure
that no longer exists.

**Goal set** (already implemented, verified matches spec): build muscle,
lose fat, improve fitness, become stronger, improve endurance, improve
mobility, maintain health — familiar labels like "bulking"/"cutting" may
appear as synonyms in copy but are always explained, never framed as an
extreme.

**Equipment set** (already implemented, verified matches spec):
no equipment, bodyweight, resistance bands, dumbbells, adjustable
dumbbells, barbell, bench, pull-up bar, cardio equipment, full gym, custom
equipment, apartment-friendly/no-jumping preference.

**Recommendation inputs** (already implemented — `ProgressionSuggestion`
and workout catalog filtering consider goal, experience, equipment, and
schedule; explicitly not sex- or BMI-only): verified unchanged.

---

## Scenario 9 — Workout completion and Meal Prep introduction

**User story**: After finishing a workout, I see a clear, honestly-labeled
summary, my companion celebrates with me, and I'm introduced to Meal Prep.

**Status**: workout summary screen already exists with duration/exercise/
set/volume metrics, PR celebration, and RPE/substitution display
(`WorkoutSummaryScreen`, prior sessions). **Gaps this session**: an
explicitly-defined completion percentage, a calendar interaction/summary,
and a Meal Prep introduction nudge.

**Percentage definitions** (exactly these, never blended):
- **Workout completion percentage** = (sets logged ÷ sets planned in the
  session's originating plan) × 100, shown on the summary screen.
- **Weekly planned-session completion** = (completed sessions this week ÷
  planned/scheduled sessions this week) × 100, shown on the dashboard.
- Neither combines with sleep, recovery, or any other unrelated metric.

**UI requirements**: summary screen gains a circular progress ring showing
workout completion percentage (defined above) with the raw numbers
alongside it ("6 of 8 sets"); a compact calendar strip highlighting the
just-completed date; and, after PRs/celebration, a one-time-per-completion
card introducing Meal Prep ("Fuel the work — check out Meal Prep") linking
to the tab.

**Backend requirements**: none beyond what already exists — completion
percentage is computed client-side from data already in the finish
response (planned vs. logged sets), consistent with keeping the backend
response shape stable.

**Acceptance criteria**: the percentage shown always matches (logged ÷
planned) × 100 for that session, clamped 0–100; the calendar strip marks
the session's completion date; the Meal Prep nudge links to the Meal Prep
tab.

**Tests**: Flutter — percentage computed correctly from a known
sets-logged/sets-planned fixture; calendar strip marks the right date; Meal
Prep nudge renders and navigates.

---

## Scenario 10 — Deload recommendation

**User story**: After months of consistent training, Ascend may suggest a
deload, explains why, and lets me dismiss or postpone it — it never nags.

**Backend requirements**: `DeloadRecommendationService` (extension-point
style, deterministic) evaluates, per user: consecutive training weeks
(from `WorkoutSession` dates via the shared `calculateStreak`-adjacent
weekly grouping in `common/progress`), recent set volume trend, session
frequency, and a simple "high RPE frequency" signal (share of recent sets
with `rpe >= 8`). Sleep/recovery data is deliberately **not** used (no real
wearable data source exists yet — see `parking-lot.md`; using placeholder
data here would violate the no-fabrication rule).

A recommendation includes a plain-language reason (e.g. "You've trained 6
weeks in a row with rising average RPE — a lighter week can help you keep
progressing.") and a suggested action (reduce volume and/or intensity,
keep moving). It never says "you are overtrained" (that's a diagnosis) —
only that the pattern suggests a lighter week could help.

**Data requirements**: `DeloadRecommendation` (id, userId, suggestedAt,
reason, dismissedAt nullable, postponedUntil nullable). A user can dismiss
(never shown again for that trigger window) or postpone (re-offered after
the postponed date, not before).

**Safety requirements**: never repeated on every screen open once
dismissed/postponed for its window; never claims a diagnosis; always
optional.

**Acceptance criteria**: a user with 6+ consecutive training weeks and a
rising high-RPE share gets a recommendation; dismissing it suppresses it;
postponing re-surfaces it only after the postponed date; a user who
trained normally gets no recommendation.

**Tests**: backend unit tests for the trigger logic (consecutive weeks
threshold, RPE-share threshold, dismiss/postpone behavior) using
constructed date/RPE fixtures — no reliance on wall-clock "now" without an
injectable clock.

---

# Founder Scenarios 11–20 Addendum

Added to the living documents on the Founder's instruction. These refine
product direction; they do not authorize unsafe, deceptive, illegal, or
privacy-invasive behavior, and they do not override
`wellness-ethics-bible.md` or `engineering-bible.md`. **Status for all ten**:
documentation and (where explicitly noted) small extension points only —
none of Scenarios 11–20 is implemented as a shipped feature this session.
See `parking-lot.md` for sequencing.

## Scenario 11 — Achievements and medals

**User story**: I earn meaningful achievements for consistent, safe
activity and real milestones, and Atlas or Nova celebrates with me.

**Examples**: first completed workout, ten active days with appropriate
recovery, first full workout week, first personal record, first 5 km walk
or run, thirty-day consistency milestone, hydration consistency,
completing a deload week, completing a beginner program.

**Data requirements**: Ascend owns the canonical, cross-platform
achievement record — an `Achievement` (catalog entry: identifier, title,
description, icon/medal asset reference, rarity or category, visibility)
and an `AchievementAward` (per-user: achievement id, earned timestamp,
progress toward multi-step achievements). Award logic must be **idempotent**
— re-evaluating the same trigger for a user who already has the award is a
no-op, never a duplicate row (the existing idempotency ledger pattern in
`engineering-bible.md` is the template).

**Safety requirements**: achievement conditions must never reward unsafe
daily intense training — no "train every single day" or "never take a rest
day" achievement. Cardio, mobility, walking, and recovery activities may
contribute differently than heavy strength volume. Conditions must account
for rest and safe training frequency, consistent with the deload logic in
Scenario 10 — the two systems must never send contradictory signals (an
achievement congratulating exactly the pattern a deload recommendation is
warning about).

**Companion behavior**: Atlas and Nova both get a celebration moment when
an achievement is earned, following the same dialogue content rules as
`atlas-nova-bible.md` (no fabricated stats, only celebrate what actually
happened).

**Extension points**: a stable identifier scheme and sync architecture that
can later map to Google Play Games Services and Apple Game Center, without
either being required — Ascend's own achievement record is canonical, and
achievements must never be blocked or degraded when an external gaming
service is unavailable or not linked.

**Free/Premium**: the complete core achievement system is free. Premium may
add cosmetic medal frames, richer unlock animations, and historical
analytics — never an exclusive *health* milestone unavailable to free
users.

**Relationship to existing code**: builds on the existing
`AchievementRule<TContext>` abstraction already present in
`common/progress/` (backend) — see `parking-lot.md`, where this was already
flagged as the intended foundation before this addendum.

**Tests (when built)**: backend — idempotent award logic (same trigger
evaluated twice awards once), achievement conditions respect rest/frequency
safety rules; Flutter — profile achievement display, celebration UI.

---

## Scenario 12 — GPS cardio and optional joint sessions

**User story**: I can start a walk, run, or ride; if it conflicts with a
scheduled strength workout, Ascend explains the conflict and lets me
choose what to do — it never silently drops my plan.

**Conflict handling**: if a scheduled strength workout exists for today,
starting cardio must explain the conflict and offer: continue the
scheduled routine, replace it for the day, add cardio separately, or
postpone the routine. Never silently delete or skip a scheduled workout.

**Location and privacy**: request location permission only when the user
actually starts location-based cardio, with a clear explanation of why.
Support automatic GPS and manual region tagging when GPS is unavailable —
a manual tag must never fabricate a route distance. Route and location
data are private by default; users can hide the starting point, ending
point, and route independently.

**Tracked where available**: duration, distance, pace, elevation, route,
heart rate from a connected wearable, and estimated calories with a clear
"estimate" label (never presented as precise).

**Free/Premium**: GPS cardio tracking, activity summary, private route
history, milestone/achievement support, companion celebration, the
progress ring and calendar, and manual privacy controls are all free.
Future premium *social* cardio (opt-in nearby session discovery, joint
sessions, shared temporary session rooms, group goals, richer analytics,
social comparisons) is separate from core tracking, which stays free.

**Stranger proximity matching — explicitly deferred, do not implement this
milestone.** If ever built: exact live locations must never be exposed to
unknown users; another user's full route, home, workplace, or exact
distance must never be revealed without explicit consent; matching must
use coarse proximity zones or privacy-preserving matching; both users must
explicitly opt in; matches expire after a limited period; users can block,
report, leave, and disable discovery instantly; minor accounts cannot
participate in stranger-based nearby matching; friend-only joint sessions
are the preferred MVP scope over stranger matching. Any emergency-related
guidance must never claim Ascend is an emergency service. See
`parking-lot.md`.

**Tests (when built)**: conflict-handling flow (all four choices preserve
or correctly modify the schedule, never silent data loss); privacy
controls actually hide the fields they claim to hide; manual region
tagging never produces a fabricated distance value.

---

## Scenario 13 — Fair subscription and eligibility discounts

**User story**: I can see what Premium offers without it pressuring me,
interrupting my workout, or making me feel worse for staying free.

**Presentation rules**: visible but non-intrusive; never interrupts an
active workout; never blocks core logging; appears in the dashboard and
appropriate settings only; clearly compares Free and Premium; discloses
current and renewal pricing and trial duration/renewal behavior; always
dismissible; no countdown manipulation, no fake scarcity, no guilt-based
language implying a free user is less committed. Suggested tone: "Ready to
go further? Premium adds deeper personalization and insight while keeping
the essential Ascend experience free."

**Pricing architecture**: pricing must be centrally configurable and
localized — never hard-coded throughout the app. Support configuration
concepts for an introductory monthly price, a standard monthly renewal
price, an annual price, a student discount, a disability-access discount,
region-specific affordability programs, and promotional periods. The
Founder's current pricing hypothesis (~USD 4.99 intro, ~USD 9.99 regular,
reduced pricing for verified-eligible users) is a **configurable business
assumption**, not a final price, and must not be hard-coded as one.

**Eligibility verification (student / disability-access) — architecture
only, no raw-ID scanning this milestone**: use the least intrusive
verification method available; prefer a trusted third-party verification
service over Ascend building its own document-scanning pipeline; never
retain full identity documents longer than necessary; encrypt verification
metadata; keep eligibility status separate from public profile data and
never publicly expose disability status; define an expiration/
reverification policy (a six-month reverification concept is a
**configurable** default, not a mandatory rule baked into the system);
allow manual appeals; comply with applicable regional law; ensure
accessibility discounts don't create discriminatory treatment elsewhere in
the product.

**Explicitly not this session**: payment processing of any kind.

**Tests (when built)**: subscription UI never renders mid-workout or
blocks a logging action; pricing values are read from configuration, not
hard-coded in more than one place; eligibility status is never present in
any public-profile-facing API response.

---

## Scenario 14 — Social profile customization and safe media

**Free**: profile description/bio, in-app default avatar, a basic profile
border, one cover image, visibility controls, progress highlights,
achievements. **Privacy controls must remain free** — a user must never
have to pay to make a profile private.

**Premium future**: more avatar styles, more borders, richer/multiple
cover layouts, additional cosmetic themes, controlled phone-gallery
import. Cosmetic only — never a privacy control.

**Media policy** (feeds directly into `wellness-ethics-bible.md`): Ascend
is a fitness and wellness platform. Allowed: normal workout photos,
progress photos, meals, achievements, exercise clips, appropriate athletic
clothing. Prohibited, without exception: pornography, explicit sexual
activity, sexual solicitation, sexualized content involving minors,
non-consensual intimate imagery, covert recordings, exploitation, graphic
abuse, and content whose primary purpose is promoting adult sexual
services. **No Premium-only NSFW network, ever** — age verification alone
does not make explicit content appropriate for Ascend, and no
entitlement tier changes that.

**Privacy-sensitive progress-photo handling** (adult users still need
this, even with strict content policy): private-by-default albums, manual
blur/crop tools, audience controls, report and appeal systems, automated
moderation, limited human review only when content is reported or
flagged, strict audit logs, retention limits.

**Tests (when built)**: privacy controls are available and effective on a
Free account with no upsell gate; automated-moderation and report/appeal
flows have coverage before any media upload feature ships.

---

## Scenario 15 — Friends, messaging, and joint workouts

**Explicitly deferred to the parking lot** unless a future milestone
names it directly. Documented now so the eventual build has a spec to
follow rather than inventing one under time pressure.

**Scope when built**: user search, friend requests (send/accept/decline),
block, report, private profiles, text chat, appropriate fitness photos,
message delivery state, read receipts between friends, joint workout
invitations, shared workout summaries, and comparison only when both
users explicitly consent.

**Initial restrictions**: non-friends have limited contact options;
message requests are separate from established chats; users control who
may contact them; minors get stricter defaults; location is never shared
through chat automatically.

**Joint workouts**: friend-only for the initial implementation; every
participant explicitly accepts; each participant chooses which of their
own results are shared; a future entitlement model may let a Premium host
invite a limited number of Free friends; no participant's private health
data is automatically exposed to the others; any participant can leave at
any time.

**Chat moderation principles**: no routine, unrestricted staff access to
all private conversations. Use automated safety/spam detection, user
reports, consent-aware media scanning, limited authorized human review
with role-based access, audit logs, reason codes, retention limits, an
appeal process, and clear privacy notices. If end-to-end encryption is
pursued, its moderation trade-offs must be documented honestly *before*
implementation, not discovered after. Explicit sexual content remains
prohibited even between consenting adults — Ascend is not an adult-content
platform, full stop.

**Tests (when built)**: friend-request/block/report state machine;
message-request-vs-established-chat separation; joint-workout consent and
selective result-sharing; moderation action audit trail.

---

## Scenario 16a — Location-based leaderboards

**Optional, off by default.** Users may choose: private progress only,
friends leaderboard, local area, city, region/state, national, or global.
Free users may enable Ranked mode and disable it again at any time.

**Privacy and integrity**: exact GPS coordinates must never appear
publicly — use verified but coarse geographic regions, with manual
location selection supported as an alternative to GPS. Apply anti-cheat
and anomaly detection where practical, without invasive surveillance.
Never reveal home addresses or exact workout routes through a leaderboard.
Minor accounts get stricter limitations. Ranking criteria must be
transparent to the user. Private profiles stay a free feature; a private
profile may optionally show a minimal public card only if the user
chooses to participate in Ranked mode.

**Ranking must reward consistency and varied healthy behavior, never raw
danger** — never rank solely by weight lifted, calories burned, or
uninterrupted training days (an uninterrupted-streak-only ranking directly
rewards the pattern Scenario 10's deload logic exists to discourage).

**Status**: data models and extension points only unless Leaderboards is
the active milestone (it is not, this session). See
`user-scenario-bible.md`'s earlier note that the Leaderboards tab ships as
an honest coming-soon state.

**Tests (when built)**: no exact coordinate ever appears in a leaderboard
API response; ranking algorithm unit tests confirm it can't be gamed by a
single dangerous-volume metric alone.

## Scenario 16b — Global, affordable meal support

**User story**: Meal Prep gives me useful suggestions that fit my actual
budget, country, schedule, and restrictions — without stereotyping me.

**Requirements**: never stereotype a user based only on nationality; ask
budget and ingredient availability directly rather than assuming them;
support low-cost meal suggestions, regional foods, allergies/preferences,
cooking-time constraints, and available kitchen equipment; use supportive,
respectful language throughout.

**Example pattern** (the tone every generated suggestion should match):
"Based on the foods you said are available — sardines, eggs, tomatoes, and
rice — that could make an affordable protein-containing meal. Nutrition
values are estimates and depend on portions and preparation." Never:
generalizing statements about what "people from your country" can or
cannot afford.

**Health considerations** (diabetes, elevated blood sugar, kidney disease,
allergies, older age): do not diagnose; do not independently prescribe a
medical meal plan; offer general educational guidance; flag risks;
recommend a qualified professional; allow a user to record
clinician-provided constraints for the app to respect. This extends, and
must never contradict, the existing "Nutrition guidance for fat-loss
goals" rule in `wellness-ethics-bible.md`.

**Free/Premium**: core food logging and practical meal suggestions stay
free. Premium future: deeper meal research, cited recipe sources, richer
localization, advanced meal planning, community meal sharing. Meal photos
shared publicly follow the same moderation policy as Scenario 14.

**Tests (when built)**: suggestion copy never references nationality as a
basis for affordability assumptions; a suggestion for a user with a
recorded clinician constraint never contradicts it.

---

## Scenario 17 — Premium camera and computer vision

**Explicitly deferred — do not implement this milestone.** Documented in
full so a future build has real safety rails from day one rather than
retrofitting them.

**Potential future scanner modes**: exercise-form estimation, repetition
counting, body-region visualization, progress comparison, food
recognition, ingredient confirmation, fashion analysis, posture
estimation.

**Hard safety requirements, non-negotiable when this is built**: clearly
display confidence and limitations on every result; never claim
medical-grade accuracy without independent validation; never diagnose
gynecomastia, injuries, deficiencies, or disease from an image; never
assign a fabricated muscle-development percentage; never promise a
reliable body-fat estimate from one camera image; never claim the camera
guarantees emergency detection, replaces a human spotter, or should delay
calling emergency services; require explicit camera consent every time;
process on-device where practical; minimize retention; allow deletion;
never use a user's body images for model training without a separate,
explicit consent.

**Example acceptable form-feedback copy**: "Your knee position appears to
move inward in this recording. The camera angle may affect this result.
Consider lowering the load and checking your form with a qualified
coach." **Never**: "You are definitely injured." Progress compliments must
be respectful and based only on comparison data the user has approved.

**Free/Premium**: future premium capability; not built this session.

**Tab architecture note**: the camera is **not** a sixth persistent tab
(see the Tab Architecture Clarification below). When built, it launches
from Assistant, Workout, Meal Prep, a central scan action, or a future
navigation redesign explicitly approved by the Founder — never a silent
change to the current five-tab structure.

---

## Scenario 18 — Companion interactions and voice

**Free**: Atlas or Nova selection, idle animations, deterministic local
greetings, basic companion interactions, core written guidance, essential
safety responses (the Scenario 1 stop-and-redirect list) — all free,
always.

**Premium future**: richer voice conversations, additional voice choices,
expressive dialogue, advanced long-term insights, expanded customization.

**Hard rule**: essential safety guidance must never be gated behind a
consumable AI-credit system. If/when live AI usage limits are introduced
for richer conversation, they must be transparent and separate from
safety-critical responses, which stay unlimited and free.

**Voice, when built**: requires explicit user activation and microphone
permission, a clear recording indicator, transcription privacy controls,
deletion controls, and no always-listening behavior by default.

---

## Scenario 19 — Assistant health and research behavior

**User story**: I can ask the Assistant about soreness or pain and get
careful, educational guidance that knows when to send me to a
professional instead of guessing.

**Behavior for reported soreness/pain**: ask about severity, ask when it
began, ask whether there was an acute injury, identify red flags, explain
common possibilities without diagnosing, recommend rest or modification
when appropriate, and recommend professional evaluation when symptoms are
concerning, persistent, severe, or unclear. This is the same
concerning-symptoms protocol already required by
`wellness-ethics-bible.md` — Scenario 19 doesn't introduce a second one,
it specifies how the Assistant's *conversational* flow applies it (ask
before assuming, rather than jumping straight to the stock safety line).

**Red flags** (non-exhaustive): chest pain, fainting, severe breathing
difficulty, sudden weakness, severe swelling, deformity, inability to bear
weight, signs of a serious allergic reaction, severe or worsening pain.

**Premium future "research mode"**: more detailed explanations, citations,
links to reputable sources, evidence-quality labels, study dates,
conflict-of-evidence notes. Sources must prioritize peer-reviewed
research, professional medical organizations, government health agencies,
established universities, and official clinical guidance. **A general web
search engine is a discovery tool, not an evidence-quality category** —
"I found this via a search engine" is never presented as equivalent to a
cited, quality-labeled source. The system must admit uncertainty and must
never invent a citation. Live web-backed research is a future milestone
and must include source verification before it ships.

**Tests (when built)**: red-flag phrases in a simulated user message
always trigger the professional-evaluation recommendation; no response
path fabricates a citation.

---

## Scenario 20 — Highly personalized scheduling

**Personalization inputs**: available time, day/night shift, sleep
schedule, training experience, goal, equipment, accessibility needs,
movement limitations, recovery, preferred training days, a connected
calendar, alarms/reminders.

**Explicitly prohibited as a training-algorithm basis**: using
mesomorph/ectomorph/endomorph as a scientifically decisive model (already
prohibited in `wellness-ethics-bible.md`; restated here because scheduling
is exactly where this temptation resurfaces), and assuming a "low
metabolism" without suitable evidence.

**Older adults, wheelchair users, people with disabilities, and users
with health concerns**: support accessible programs; ask functional and
preference-based questions rather than assuming; avoid assumptions;
recommend qualified professional input where appropriate; provide
modifications; prioritize safety and autonomy.

**Free/Premium**: basic schedule customization and accessibility are
free, always — never paywalled. Premium future: deeper adaptive
scheduling, advanced calendar automation, richer recovery analytics,
greater personalization, clinician/trainer collaboration tools.

**Tests (when built)**: scheduling logic never branches on a
body-type classification; accessibility-driven modifications are
available without a premium check.

---

## Tab architecture clarification

The five-tab navigation from `design-bible.md` — Workout, Meal Prep,
Social, Assistant, Leaderboards — is unchanged by this addendum. The
camera (Scenario 17) is **not** a sixth persistent tab. When premium
camera capability is eventually built, it launches from an existing
surface (Assistant, Workout, Meal Prep, a central scan action) or a
navigation redesign the Founder explicitly approves — never a silent
restructuring of the current five-tab shell.

## Compatibility check against existing decisions

Reviewed against this addendum and found consistent, no conflicts:
- **Terms (Scenario 1)**: already covers the stop-on-symptoms and
  professional-care framing this addendum extends into GPS/camera/
  Assistant contexts; no redraft needed this session.
- **Onboarding / profile**: no public-facing profile page exists yet, so
  Scenario 14's media/privacy rules have nothing to retrofit — they apply
  prospectively when Social/profile customization is built.
- **Nutrition (Meal Prep)**: the existing "balanced, not reductive"
  fat-loss guidance rule already matches Scenario 16b's spirit; added the
  explicit anti-nationality-stereotyping rule as a direct extension, not a
  contradiction.
- **Workout Engine / Deload (Scenario 10)**: Scenario 11's achievement
  safety rule and Scenario 16a's ranking-integrity rule both explicitly
  reference and reinforce the deload logic rather than conflicting with
  it.

---

# Founder Scenarios 21–27 Addendum

Added to the living documents on the Founder's instruction, at the start of
the Major Product Expansion session. These refine product direction; they
do not authorize unsafe, deceptive, illegal, or privacy-invasive behavior,
and they do not override `wellness-ethics-bible.md` or
`engineering-bible.md`. **Status**: unlike the Scenarios 11–20 addendum
(which deferred every scenario), several of Scenarios 21–27 are actively
built across this same session's later parts (see `roadmap.md` and
`parking-lot.md` for exactly what shipped vs. what remains architecture-
only, updated as each part lands) — this addendum itself is documentation
and capability-model alignment, done first so every part that follows has
an authoritative spec to build against.

## Scenario 21 — Six-destination navigation and the Vision gate

**User story**: My five core destinations are named Train, Fuel,
Community, Ascend AI, and Rankings. As a Premium member I also get a sixth
destination, Vision, for camera-based coaching tools. My profile stays one
tap away from the icon in the corner, not a seventh destination.

**Requirements**: the primary shell has five free destinations — Train
(formerly Workout), Fuel (formerly Meal Prep), Community (formerly
Social), Ascend AI (formerly Assistant), Rankings (formerly Leaderboards)
— plus Vision as a sixth, Premium-gated destination. The profile/dashboard
icon in the upper-right remains the entry point to Profile/Dashboard and
is explicitly not one of the six destinations (unchanged from
`design-bible.md`'s existing rule). Migrating the visible labels and
adding the Vision slot must never remove or break the existing routes
those tabs already serve — this is a rename and an addition, not a
rebuild.

**Free/Premium**: the five renamed destinations are free, unchanged from
today's five-tab access. Vision is Premium-only (`AppCapability
.visionAccess`); a Free user sees the destination exists (honest, not
hidden) but its content is a locked/upgrade state, never a fabricated
preview of camera features that don't run for them.

**Tests (when built)**: navigation renders exactly six destinations for a
Premium test user and five plus a locked Vision entry for a Free test
user; every pre-existing route (Train/Fuel/Community/Ascend
AI/Dashboard) still resolves after the rename.

---

## Scenario 22 — Community Reels

**User story**: I can post and watch short fitness and wellness videos
from people I follow and from creators I discover, react to what I see,
and control who sees what I post.

**Requirements**: reels (short video posts) with captions, likes,
comments, saves, follows, reports, blocks, visibility controls (private/
friends/followers/public, matching the profile privacy model), native
external sharing to whatever apps the OS share sheet supports, a
moderation pipeline, creator profiles, and trainer content as a
recognized profile category. **Explicitly not promised**: automatic
publishing to Instagram, Facebook, or TikTok — that requires each
platform's own official API integration and app review, which doesn't
exist yet. Sharing today, like every other share surface in this app
(`AscendShareService`), hands content to the native OS share sheet; a
user chooses where it goes next.

**Free/Premium**: posting, viewing, and interacting with Reels is free —
Community is a core product surface, not a premium add-on. Trainer/
creator profile status is free to hold; paid distribution of a creator's
content is a separate capability (Scenario 23, Ascend Promote).

**Tests (when built)**: a blocked user's Reels never appear in the
blocker's feed; a private-visibility Reel is never returned to a non-
follower; report submission creates a moderation-queue entry.

---

## Scenario 23 — Ascend Promote

**User story**: As a creator, I can pay to get my post or Reel in front of
more people — and everyone who sees it can tell it's promoted, not
organic.

**Requirements**: promoted content is always labeled **Promoted**,
visibly and unambiguously. Paid reach/engagement metrics are tracked and
displayed separately from organic metrics — never blended into one
number that overstates authentic interest. No guaranteed engagement is
promised to the creator (a paid budget buys distribution/impressions, not
a promised number of likes or follows). No fake followers or fake likes,
ever, under any circumstance. Every promoted campaign passes moderation
review before it goes live. Frequency limits cap how often the same user
sees promoted content. Promoted reach and engagement have **zero**
influence on fitness Rankings (Scenario 6 below) — a paid boost is a
distribution mechanism, never a competitive advantage. Actual billing is
future, store-compliant work (see Scenario 27's Pricing section and
`free-premium-policy.md`) — this scenario is the transparent-promotion
architecture, not a live payments feature.

**Free/Premium**: creating a promoted campaign is a Premium/creator
capability (`AppCapability.ascendPromote`) — viewing and interacting with
promoted content (like any Community content) is free for everyone.

**Tests (when built)**: a promoted post's paid impression/click counts
never contribute to any Ranking calculation; every promoted post renders
the Promoted label; a campaign in `PENDING_REVIEW` never serves
impressions.

---

## Scenario 24 — Trainer groups

**User story**: I can create a small group to train with friends or
clients, share plans, and chat — free, with room to grow if I need more
later.

**Requirements — free tier**: one group owned per user, a centrally
configurable small-member limit (three to five members, not hard-coded
per-widget), text chat, safe image sharing (subject to the same media
content policy as everywhere else in the app — see
`wellness-ethics-bible.md`), shared workout plans, and invitations.

**Requirements — Premium future**: more groups per owner, larger group
sizes, scheduled announcements, scheduled sessions, assignments, and
distinct trainer/moderator roles within a group.

**Free/Premium**: the free tier above (`AppCapability
.trainerGroupsBasic`) is real, not a crippled trial — genuinely usable
for a small friend or client group. The expanded tier
(`AppCapability.trainerGroupsExpanded`) adds scale and structure, never
gates the basic ability to train together in a small group.

**Tests (when built)**: a Free-tier owner cannot create a second owned
group; the member-limit check reads from central configuration, not a
literal in the UI or the service.

---

## Scenario 25 — Sports scoring (Vision-assisted, badminton first)

**User story**: My friend and I can log the score of our badminton match
together. If a camera-assisted feature suggests a score, it's only a
suggestion — the two of us always confirm what actually happened.

**Requirements**: both players join the match record. Both users must
confirm the final score before it's final. If the two submitted scores
conflict, the match becomes **disputed** rather than silently picking
one side's number. No Ranked points are awarded until both players agree.
Any camera-based score assistance (Vision, Scenario 8/Scenario 27's Part
8) produces a suggestion only — manual score entry is always available
and is never removed or downgraded once camera assistance exists. No
gambling or wagering feature of any kind attaches to sports scoring.

**Free/Premium**: manual match creation, confirmation, and dispute
resolution are free (`AppCapability.sportsScoringManual`) — two friends
can always score a match together without Premium. Camera-assisted score
suggestion is a Vision/Premium capability
(`AppCapability.sportsScoringAssisted`) layered on top, never a
replacement for the free manual flow.

**Tests (when built)**: a match with conflicting player-submitted scores
transitions to `DISPUTED`, not to either submitted score; no Ranking
points post until both confirmations match; a camera-suggested score
alone (no human confirmation) never finalizes a match.

---

## Scenario 26 — Expanded cardio activities and the Nutrition Library

**User story**: I can log the cardio activity that actually fits my body
and my day — walking, jogging, running, sprint work, cycling, hiking, or
wheelchair mobility — and in Fuel I can learn what a nutrient actually
does without being told I'm deficient in it.

**Expanded cardio requirements**: the free activity type list grows to
include walking, jogging, running, sprint sessions, cycling, hiking,
wheelchair mobility (where appropriate to the user), and a custom
outdoor-cardio type for anything not in the preset list. Premium may add
advanced analytics on top of these activities (deeper pace/effort
trend analysis) — it never gates access to logging the activity types
themselves.

**Nutrition Library requirements**: a free educational nutrient
encyclopedia (macronutrients, minerals, vitamins) that explains a
nutrient's function, shows common food sources, and discusses deficiency
and excess risk **cautiously** — describing general, well-established
risk categories, never diagnosing a specific user's deficiency from their
logged intake (same boundary `wellness-ethics-bible.md` already applies
to nutrition guidance generally). It never prescribes a specific
supplement or dose. It distinguishes dietary requirements (nutrients the
body cannot make and must get from food) from substances the body can
synthesize on its own. Where a future research/citation integration
exists, sources follow the same evidence-quality rules as Scenario 19 —
peer-reviewed research, professional medical bodies, government health
agencies, established universities; a general web search is a discovery
tool, never a cited source on its own.

**Free/Premium**: expanded cardio activity types
(`AppCapability.expandedCardioActivities`) and the Nutrition Library
(`AppCapability.nutritionLibrary`) are both free — the free product stays
genuinely complete. `AppCapability.cardioAdvancedAnalytics` is the
Premium depth-add for cardio.

**Tests (when built)**: every listed free activity type is loggable
without a Premium check; Nutrition Library copy for any nutrient never
contains a first-/second-person diagnostic claim ("you are deficient in
X") — only general, sourced, third-person information.

---

## Scenario 27 — Support, companion tone evolution, and centralized pricing

**User story**: I can always get help, my companion feels warm without
ever feeling like it's trying to be my only relationship, and if pricing
ever changes I see one honest number, not something hidden in code.

**Support requirements**: every user, on every tier, has access to a help
center, support ticket creation, bug reporting, a safety report path, an
accessibility feedback channel, account recovery, billing help, and a
moderation-appeal path. None of this is ever Premium-gated
(`AppCapability.supportAccess`).

**Atlas and Nova tone requirements**: both companions stay warm, upbeat,
empathetic, and emotionally aware, honest about their own limitations,
supportive of rest (never guilt for taking one), and capable of setting a
boundary when a conversation asks for something outside safe scope. They
must never: claim consciousness or sentience, manipulate a user into
emotional dependence, present themselves as a replacement for therapy,
diagnose a mental illness, act as though they are a user's only friend or
family, or engage in sexual or NSFW roleplay of any kind, at any
entitlement tier — this restates `wellness-ethics-bible.md`'s media policy
in the dialogue domain, not a new exception to it. A future "Playful
warmth" presentation layer may allow light charm and tasteful compliments
within the existing coaching-style system, but explicit sexual behavior
is never in scope, Free or Premium, present or future — see Founder
Vision principle 15.

**Pricing requirements**: pricing configuration must be centralized
(never a literal hard-coded into individual widgets) and support the
Founder's current hypotheses as configurable, non-final values:
approximately USD 12.99 standard monthly, approximately USD 7.99 for
verified-eligible users, approximately PHP 599 standard, approximately
PHP 299 for verified-eligible users. These replace the earlier ~USD 4.99/
~USD 9.99 hypothesis recorded in `free-premium-policy.md`'s original
draft — both are explicitly non-final business assumptions, not store
prices. The configuration model must support Student Access, Accessibility
Access, Senior Access, and Regional Affordability as distinct eligibility
programs (extending, not replacing, the student/disability-access model
already documented in Scenario 13). Eligibility status is never exposed
publicly on a profile or anywhere another user can see it — the existing
Scenario 13 rule about keeping eligibility separate from public profile
data applies identically to every program added here.

**Tests (when built)**: no pricing literal appears directly in Flutter
widget code (a config/provider lookup only); a support-ticket-creation
capability check never returns false for any tier; dialogue-content tests
assert no companion response includes consciousness claims, therapy-
replacement framing, or sexual/NSFW content regardless of coaching style
or "Playful warmth" state.

---

## Six-destination navigation clarification (supersedes the five-tab note above for Vision)

The "Tab architecture clarification" section above (written for the
Scenarios 11–20 addendum) said the camera is not a sixth tab. Scenario 21
above supersedes that specific point: Vision **is** now the sixth,
Premium-gated destination, per direct Founder instruction. Every other
part of that clarification — five free destinations keep their relative
order, no further silent restructuring beyond what Scenario 21
authorizes — still holds.

## Compatibility check against Scenarios 21–27

Reviewed against this addendum and found consistent, no conflicts:
- **Rankings integrity (Scenario 16a)**: Scenario 23's "Promoted reach
  never influences Rankings" rule directly extends the existing
  ranking-integrity principle rather than introducing a new one.
- **Achievement safety (Scenario 11)**: Scenario 26's expanded cardio
  activity list is exactly the kind of varied, non-dangerous activity set
  Scenario 11's achievement-safety rule already anticipated ("cardio,
  mobility, walking, and recovery activities may count differently than
  heavy strength volume").
- **Camera safety rails (Scenario 17)**: Scenario 25's "camera output is
  a suggestion only" rule for sports scoring is a direct application of
  Scenario 17's existing camera hard-safety-requirements list, not a new
  policy.
- **Media and content policy**: Scenario 22's Reels and Scenario 24's
  group image sharing both explicitly point back to
  `wellness-ethics-bible.md`'s existing media policy rather than defining
  a separate one.
