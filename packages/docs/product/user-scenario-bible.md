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
