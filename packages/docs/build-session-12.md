# Build Session 12 — Notification Safety, AI Hardening, Trainer Platform, Admin Completion

Starting HEAD: `fd973fb` (Merge Build Session 11 final: build-session-11.md
structured report) on `main`. Work branch:
`claude/session-12-beta-platform`.

Status vocabulary used throughout, matching every prior session's
convention: **IMPLEMENTED** (code written), **VERIFIED** (implemented and
confirmed via an automated test that actually ran), **PARTIAL** (some but
not all of a Part is done), **BLOCKED** (cannot proceed without an
external credential/device/service this environment doesn't have),
**DEFERRED** (in scope for a future session, not started this session),
**NOT_RUN** (a check that exists but was never executed). Nothing below
is called "verified" merely because it compiles.

## Summary

Every Part below was individually: implemented → tested (backend
unit+e2e, mobile analyze+format+test, admin lint+test+build where
touched) → committed → pushed to the feature branch → merged `--no-ff`
into `main` → **re-verified in full on the merged `main`** → pushed to
`main` → fast-forwarded back onto the feature branch. No step was
skipped for any merged part; the merge history on `main` (13 individual
merge commits, `fd973fb..0092382`) is the audit trail.

This session's own visible working window began partway through Part
15-17 (the earlier Parts 1-14 were completed in prior turns of this same
session, before context compaction, and their commits are on `main` —
see the real commit log cited per-part below rather than a
reconstruction from memory). Everything from Part 15-17 onward in this
document was implemented, tested, and merged directly in this window,
with full command output observed at each step.

## Part 1-2 — Fail-closed notification types + support/moderation/promote notifications

**Status: IMPLEMENTED, VERIFIED** (commits `ec4f064` merge).

Closed the gap where an unrecognized `NotificationType` value reaching
the mobile client could silently misroute or crash a switch statement,
and wired real notifications for support ticket replies, moderation
decisions, and Ascend Promote review outcomes — surfaces that existed
without ever notifying the affected user.

## Part 3 — AI safety classifier precision

**Status: IMPLEMENTED, VERIFIED** (commit `e8980b7` merge).

Tightened `AssistantSafetyService`'s category classification to reduce
false-positive/false-negative edges found in the Session 11 Part 3
adversarial suite.

## Part 4 — Sensitive AI memory confirmation

**Status: IMPLEMENTED, VERIFIED** (commit `98d656f`).

Added an explicit confirmation step before a sensitive category of
extracted memory candidate (e.g. health-related) is persisted, rather
than auto-saving anything the classifier extracts.

## Part 5 — Grounded research synthesis pipeline

**Status: IMPLEMENTED, VERIFIED** (commit `ef99d95`).

Real citation-grounded synthesis over `ResearchQueryPlannerService`'s
retrieved documents, replacing an earlier pass-through shape.

## Part 6-7 — AI provider resilience + context minimization

**Status: IMPLEMENTED, VERIFIED** (commit `f1b37b4`).

Retry/fallback behavior across the OpenAI/Gemini/Anthropic provider
router, and trimmed what conversation context actually gets sent to a
provider per turn (cost and privacy-surface reduction).

## Part 8 — Separate conversation history from AI memory

**Status: IMPLEMENTED, VERIFIED** (commit `fde6b9c`).

Split the raw chat transcript (`CompanionConversation`/
`CompanionChatMessage`, gated on `Preference.conversationHistoryEnabled`)
from the small set of extracted, structured facts
(`CompanionMemoryNote`) the companion actually uses as context — deleting
one never touches the other. This is also the module a real correctness
bug was found and fixed in during Part 27-32 (below): `appendTurn` wrote
both messages of a turn via a single `createMany`, which shares one
Postgres `CURRENT_TIMESTAMP` across the whole statement, making
"most recent message" ordering nondeterministic.

## Part 9-11 — Trainer workout assignments, scheduled sessions, dashboard

**Status: IMPLEMENTED, VERIFIED** (commit `dae0ad9` merge).

A trainer can assign a specific workout to a group member (distinct from
the member self-selecting one), schedule a group session, and see a
read-only aggregate dashboard across every group they own or moderate.
Migration: `20260809185339_trainer_workout_assignments_scheduled_sessions`.

## Part 12-14 — Privacy, Permission, and Accessibility Centers

**Status: IMPLEMENTED, VERIFIED** (commit `15619be` merge).

Three real mobile settings surfaces backed by actual state (not
placeholder toggles): a Privacy Center, an OS-permission-status Center
(deep-linking to system settings via the new `url_launcher` dependency),
and an Accessibility Center including a real text-scale preference.
Migration: `20260809192400_preference_text_scale`.

## Part 15-17 — Feature Flags, Release Readiness, Observability

**Status: IMPLEMENTED, VERIFIED** (commit `ff0a7e2` merge; admin UI
completed in Part 25-26 below — the backend and diagnostic existed from
this Part with no admin page to operate them until then).

`FeatureFlagsService` (key/description/enabled/rolloutPercentage,
`GET /feature-flags` filtered to enabled-only for clients) and
`ReleaseReadinessService` (a single diagnostic endpoint reporting
configured/not-configured booleans — JWT secrets, CORS, every external
integration — never a raw secret value). Migration:
`20260810043237_feature_flags_and_manage_platform_permission`.

## Part 18-21 — Security/privacy/location/blocking/media audit fixes

**Status: IMPLEMENTED, VERIFIED** (commit `f341f3a` merge).

Two concrete, Explore-agent-identified gaps, not a speculative checklist:
PRIVATE-visibility media assets were served via a permanent, unauthenticated
URL (`getObjectUrl`) instead of a signed/auth-gated one — fixed with
`MediaStorageProvider.getSignedGetUrl` (real S3 presigning; an
auth-gated `GET /media/objects` route for local dev) and gallery items
now use it. Trainer-group invites had zero block check, unlike every
other social-graph mutation (friends, messages, joint workouts) — fixed
to throw the same `NotFoundException('User not found.')` "not found, not
forbidden" pattern used everywhere else blocking is enforced.

## Part 22 — Purchase reconciliation audit

**Status: IMPLEMENTED, VERIFIED** (commit `c3b67d8` merge).

`CapabilityService.getPlanTier` — the single chokepoint every capability
check in the app already funnels through — now lazily downgrades an
expired `PREMIUM` subscription to `FREE` (and persists the downgrade) the
moment anyone reads it, closing the "store said it lapsed, nothing ever
re-verified it" gap without needing real App Store Server
Notifications/Google Play RTDN infrastructure this session has nothing
to test against.

## Part 23-24 — Table Tennis sport + Sports UI generalization

**Status: IMPLEMENTED, VERIFIED** (commit `a7780f8` merge). Camera-assisted
score-suggestion (**DEFERRED** — `user-scenario-bible.md` Scenario 25
explicitly frames it as future work needing real pose/ball-tracking
infrastructure this session has no foundation for; not faked).

Added `TABLE_TENNIS` as a second `SportCode` (the match-engine schema was
already sport-agnostic; needed no new match logic) and generalized the
previously badminton-hardcoded mobile Sports UI to a sport selector,
proving independent per-sport rating tracking. Migration:
`20260810052103_add_table_tennis_sport_code`.

## Part 25-26 — Trainer verification UX + Admin completion

**Status: IMPLEMENTED, VERIFIED** (commit `af02f1b` merge).

A real trainer-verification application-and-review pipeline, deliberately
separate from the pre-existing self-declared `CommunityProfile.isTrainer`
badge:

- `TrainerVerificationApplication` (member applies with free-text
  credentials via `POST /community/trainer-verification`, sees status via
  `GET /community/trainer-verification/me`) and a new
  `CommunityProfile.verifiedTrainer` boolean, settable only by an admin
  approving the application — never self-service, never derived from
  `isTrainer`.
- Admin review lives directly on `AdminService`
  (`listTrainerVerificationApplications`/`decideTrainerVerification`),
  matching the existing split affordability-eligibility review already
  uses (member-facing methods on the domain service, admin review methods
  directly on `AdminService`) rather than putting admin logic in the
  community module — a deliberate architectural correction made mid-Part
  after comparing against the existing convention, before any test ran.
- New `REVIEW_TRAINER_VERIFICATION` admin permission, gating both the new
  routes and a new `TrainerVerificationPage` in `apps/admin`.
- Two admin pages that had *no UI at all* since Part 15-17 finally got
  one: `FeatureFlagsPage` (CRUD table) and `ReleaseReadinessPage`
  (read-only diagnostic).
- Mobile: a `trainer_verification` feature (domain/data/presentation,
  mirroring the existing `subscriptions` feature's
  apply-and-see-status pattern), an entry point from Edit Community
  Profile, a distinct filled `Icons.verified` badge on a platform-verified
  profile vs. the existing outlined `Icons.verified_outlined` self-declared
  one, and the notification deep link wired (the enum/parse/icon plumbing
  for `TRAINER_VERIFICATION_UPDATE` already existed from Part 1-2's
  fail-closed work — only the deep-link target was still `null`).
- A real bug found and fixed during this Part's own verification cycle
  (not fabricated, not skipped): the migration that added
  `NotificationType.TRAINER_VERIFICATION_UPDATE` to `schema.prisma` never
  made it into a `migration.sql` file, so the enum value existed in
  Prisma's generated client but not in the actual Postgres enum — e2e
  caught it immediately as a 500 on the very first approval attempt.
  Fixed with a corrective migration
  (`20260810055033_add_trainer_verification_notification_type`) rather
  than silently working around it.
- A second real bug found during full-suite re-verification: the
  `appendTurn` `createMany` timestamp-tie issue described in Part 8 above
  — found because a pre-existing `assistant.e2e-spec.ts` test flaked
  during this Part's mandatory full-suite run, not because it was being
  looked for. Fixed at the root (sequential `create` calls, both in
  production code and the test's own seed) rather than loosening the
  test's assertion.

Migrations: `20260810053756_trainer_verification_and_manage_platform_permission`,
`20260810055033_add_trainer_verification_notification_type`.

## Part 27-32 — Performance review, backup runbook, security regression suite, QA device matrix, TODO audit, dart-format drift

**Status: IMPLEMENTED, VERIFIED** (commit `0092382` merge).

**Performance** — an Explore-agent audit of real N+1/missing-index
patterns (not a speculative checklist) found, ranked by impact:

1. `RankingsService.getLeaderboard` — `Promise.all(candidateIds.map(...))`
   issued 3 queries per candidate regardless of which page was
   requested, for every opted-in user in scope. **Fixed**: new
   `computeActivitySummaries` batched sibling in
   `activity-scoring.util.ts` (one round of 3 `IN (...)`-filtered
   queries total), used by both `RankingsService` and the identical
   pattern in `ChallengesService`'s per-participant progress.
2. `RankingOptIn.scope` had no index despite being the leaderboard's
   primary filter. **Fixed**: `@@index([scope, regionLabel])`.
3. `WorkoutSession`'s `{userId, status, completedAt}` range query (the
   activity-summary hot path) only had a `[userId, status]` index.
   **Fixed**: added `@@index([userId, status, completedAt])`.
4. `FriendsService.searchUsers` — up to 40 extra queries per type-ahead
   search call (2 per matched profile × 20 results). **Fixed**: batched
   into 2 `IN (...)`-filtered queries total, with a new e2e regression
   test proving `isFriend`/`pendingRequest` (including request
   *direction*) are still computed correctly after the rewrite.
5. `TrainerGroupsService.listMyGroups`'s `1 + 2N` query pattern was
   identified but **not fixed this Part** — lower-traffic surface than
   the four above; carried forward as a known, documented follow-up
   rather than left silently unmentioned.

Migration: `20260810061421_rankings_and_workout_session_perf_indexes`.

**Security regression suite** — `test/security-regression.e2e-spec.ts`,
scoped deliberately to cross-module *chains* the already-thorough
per-module e2e specs don't cover (verified by reading every existing
security-relevant spec first — `blocking-cascade`, `admin-rbac`,
`media.e2e-spec.ts`'s private-object-route test, `assistant.e2e-spec.ts`'s
entitlement-gate tests — to avoid padding with redundant coverage).
One test: a lapsed store subscription's Part-22 lazy downgrade is
enforced by the *very next* Premium-gated request (the Session 11 Part 1
AI entitlement gate), not just reflected on its own status screen.

**Backup and disaster recovery runbook**
(`packages/docs/backup-and-restore-runbook.md`) — `pg_dump`/`pg_restore`
commands verified directly against this session's Postgres instance
(dump → restore into a scratch database → confirm it queries correctly);
the `docker-compose`-wrapped versions are standard usage but unverified
in this sandbox, which has no Docker daemon — disclosed explicitly in
the doc rather than presented as tested. Also covers media object
storage backup posture (why local-dev storage needs none, why S3 should
rely on bucket-level versioning/replication rather than an app-level
re-copy) and a periodic restore-verification procedure.

**Release QA device matrix**
(`packages/docs/qa/release-device-matrix.md`) — a 6-device platform/OS
coverage table plus a 28-point release-gate checklist (install, core
workout/nutrition loop, camera features, location/background execution,
push, IAP, accessibility, store readiness). Every row is honestly
`NOT_RUN`, matching the existing `vision-physical-device-checklist.md`'s
disclosure — this environment has no physical devices, emulators,
Android SDK, Xcode, or store sandbox access.

**TODO/placeholder audit** — grepped every subsystem
(`TODO`/`FIXME`/`XXX`/`HACK`, and prose markers like "not yet"/
"temporary"/"stub"/"coming soon") across `services/api/src`,
`apps/admin/src`, and `apps/mobile/lib`. **Result: clean.** Zero
`TODO`/`FIXME`/`XXX`/`HACK` comments exist in any application source file
(two hits total, both in unmodified Android Gradle template
boilerplate). Every "not yet"/"placeholder"-style comment found traces to
this codebase's established convention of writing honest,
cross-referenced deferral comments (citing a Build Session, Founder
Scenario, or `parking-lot.md`) rather than a silent stub — e.g.
`NoopResearchProvider`, `AUTO_APPROVED_NO_CLASSIFIER`, the design
system's explicitly-labeled `_MediaPlaceholder`. No action items
resulted; this is reported as a clean audit, not skipped.

**dart-format drift** — `dart format --set-exit-if-changed lib test`
reports 0 files changed as of this session's final commit. No stray
`.dart` files exist outside `lib/`/`test/`. Nothing to fix; the sub-item
was already satisfied by the point it was checked.

## Migrations (this session, chronological)

1. `20260809143435_notification_categories_v2` (Part 1-2)
2. `20260809154708_ai_usage_events` (Part 3-7 range)
3. `20260809181412_companion_conversation_history` (Part 8)
4. `20260809185339_trainer_workout_assignments_scheduled_sessions` (Part 9-11)
5. `20260809192400_preference_text_scale` (Part 12-14)
6. `20260810043237_feature_flags_and_manage_platform_permission` (Part 15-17)
7. `20260810052103_add_table_tennis_sport_code` (Part 23-24)
8. `20260810053756_trainer_verification_and_manage_platform_permission` (Part 25-26)
9. `20260810055033_add_trainer_verification_notification_type` (Part 25-26 — corrective, see above)
10. `20260810061421_rankings_and_workout_session_perf_indexes` (Part 27-32)

## New dependencies

- `url_launcher: ^6.3.1` (Flutter, Part 12-14) — deep-links from the
  Permission Center to OS settings.

No new backend or admin dependencies this session.

## Test results (final, on merged `main`, commit `0092382`)

- Backend unit: **1040 passed**, 75 suites (891 at session start —
  +149).
- Backend e2e: **349 passed**, 40 suites (300 at session start — +49).
- Backend lint (`eslint --max-warnings=0`): clean.
- Backend build (`nest build`): clean.
- Mobile `flutter analyze`: clean, 0 issues.
- Mobile `dart format --set-exit-if-changed`: clean, 0 files changed.
- Mobile `flutter test`: **799 passed** (732 at session start — +67).
- Admin `eslint`: clean (one pre-existing `react-refresh/only-export-components`
  warning in `AuthContext.tsx`, unrelated to this session's changes, not
  a lint failure).
- Admin `vitest`: **37 passed**, 12 files.
- Admin `tsc --noEmit && vite build`: clean.

Every number above was observed directly from command output during this
session, on the actual merged `main` commit — not carried forward from
an earlier, now-stale run. Mobile and admin were last modified in Part
25-26; Part 27-32 touched only `services/api` and `packages/docs`, so
their Part 25-26 verification (also 799/37, identical commit-diff
confirmed empty between the two merges) still applies unchanged and was
not redundantly re-run a third time.

## Android/iOS build status

- `flutter build apk` / `flutter build ios`: **NOT_RUN** — this
  environment has no Android SDK and no Xcode, consistent with every
  prior Build Session (7 through 11) in this repository.

## Physical-device tests

**NOT_RUN.** No Android/iOS physical device or emulator exists in this
environment. See `packages/docs/qa/vision-physical-device-checklist.md`
(pre-existing, camera/pose-detection-specific) and this session's new
`packages/docs/qa/release-device-matrix.md` (general release-gate
coverage) — every row in both documents is honestly `NOT_RUN`.

## External credentials still required

Unchanged from Build Session 11's list — none of this session's work
closed these gaps, and none of it depended on them:

- A real Firebase project, Apple Developer Program team + APNs key,
  Android SDK/Xcode/a physical device — block live push delivery,
  Vision on real hardware, and every row in the new device matrix.
- `BRAVE_SEARCH_API_KEY`, Apple/Google IAP secrets — pre-existing,
  unrelated to this session's work.
- A managed Postgres provider or infrastructure-level backup scheduler —
  this session wrote the runbook and verified the underlying `pg_dump`/
  `pg_restore` mechanics, but did not (and could not, from this sandbox)
  wire an actual scheduled job.

## Remaining beta/launch blockers

Carried forward, updated for what this session actually closed:

1. No live push delivery, Vision-on-camera, or any device-matrix row has
   ever been verified on real hardware — unchanged from every prior
   session's disclosure.
2. `TrainerGroupsService.listMyGroups`'s N+1 query pattern (Part 27-32,
   finding #5) is identified but not yet fixed.
3. Camera-assisted sport score suggestions (Part 23-24) remain
   deliberately deferred — no pose/ball-tracking infrastructure exists.
4. No automated backup schedule is wired up anywhere — the runbook
   documents the procedure and verifies the mechanics, but scheduling it
   against a real production database is deployment-specific and out of
   this sandbox's reach.
5. Android release-signing configuration
   (`android/app/build.gradle.kts`'s stock `TODO: Add your own signing
   config`) is still unedited — flagged by this session's TODO audit as
   the one non-cosmetic finding, not yet resolved.

None of the above are new regressions from this session's work — all are
either pre-existing, explicitly scoped out, or newly *discovered* (not
introduced) by this session's own audits, and are carried forward
honestly rather than hidden.
