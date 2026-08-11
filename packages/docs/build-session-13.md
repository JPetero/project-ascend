# Build Session 13 — Feature Flags, Trainer Groups Completion, Rankings/Research/Vision Depth, Release Engineering, Retention

Starting HEAD: `d627ce2` (Merge Session 12 Part 33: final structured report)
on `main`. Work branch: `claude/session-13-beta-delivery`.

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
skipped for any merged part; the merge history on `main` (17 individual
merge commits, `d627ce2..5263273`) is the audit trail, and the order of
Parts below matches that real chronological merge order rather than a
reconstructed numbering.

This session's own visible working windows began and resumed multiple
times across context compactions; each resumption picked up the standing
autonomous directive rather than starting over, and every part cited
below was implemented, tested, and merged with full command output
observed at each step — none of it reconstructed from memory.

**Update:** this report was originally written and merged (commit
`9326055`) with "S13 Part 8: Ranking categories + provenance" listed as
deferred. The session continued afterward and actually implemented it —
see Part 8 below, appended after Part 33-49 in the order it was really
built rather than backdated into its numbered position above. Every
count and blocker elsewhere in this document (test totals, the
remaining-blockers list) reflects that final state, not the mid-session
snapshot.

## Part 1 — Feature flag registry redesign + real wiring

**Status: IMPLEMENTED, VERIFIED** (commit `53cfc27` merge; completed by
continuation Part A below).

Reworked `FeatureFlagsService` so flags are actually consulted by the
subsystems they're meant to gate, rather than existing as an
administered-but-unused registry.

## Part 2/28 — TrainerGroupsService.listMyGroups N+1 fix

**Status: IMPLEMENTED, VERIFIED** (commit `0157bce` merge).

Closed the N+1 query pattern in `listMyGroups` that Build Session 12
Part 27-32's performance audit identified but explicitly deferred
(finding #5 in that session's report) — batched into the same
`IN (...)`-filtered-query pattern used for the other four findings fixed
in that prior session.

## Part 3 — Trainer scheduled session RSVP/participation

**Status: IMPLEMENTED, VERIFIED** (commit `8745f67` merge).

A member can RSVP (`GOING`/`MAYBE`/`DECLINED`) to a trainer group's
scheduled session, and cancellation now notifies every RSVP'd member
(new `NotificationType.GROUP_SESSION_CANCELED`) instead of silently
deleting the booking. Migration:
`20260810132227_add_trainer_group_session_rsvp`.

## Part 4 — Trainer assignment UX polish

**Status: IMPLEMENTED, VERIFIED** (commit `5d28640` merge).

A member can decline an assigned workout (new
`WorkoutAssignmentStatus.DECLINED`), overdue assignments are surfaced
distinctly, due dates are shown, and the Trainer Dashboard gained
real assignment-status counts instead of just a member roster. Migration:
`20260810134801_add_workout_assignment_declined_status`.

## Continuation Part A — Finish feature flag wiring

**Status: IMPLEMENTED, VERIFIED** (commit `f5203b9` merge).

Closed the remaining gap from Part 1: every subsystem the flag registry
was meant to gate now actually checks it, product-wide, rather than a
subset.

## Continuation Part B — Trainer scheduled sessions end to end

**Status: IMPLEMENTED, VERIFIED** (commit `366d0ea` merge).

Scheduled sessions gained a real detail deep link
(`RoutePaths.trainerGroupScheduledSessionDetail`) distinct from the
inline tab-only view they previously had, and a link to the associated
joint workout session where one exists. Migration:
`20260810150000_trainer_group_scheduled_session_joint_workout_link`.

## Part 5 — Complete Privacy Center

**Status: IMPLEMENTED, VERIFIED** (commit `c259e1d` merge).

The Privacy Center (Build Session 12 Part 12-14) gained real default
visibility preferences — `defaultPostVisibility`,
`defaultGalleryVisibility`, `progressPhotoDefaultVisibility`,
`defaultHideCardioRoute` — actually consulted at the point new content
is created, rather than a settings screen with nothing behind it.
Migration: `20260810160000_privacy_center_default_preferences`.

## Part 6-7 — Rankings locality hierarchy + expanded scopes

**Status: IMPLEMENTED, VERIFIED** (commit `32ab37c` merge).

Restored the full Rankings locality hierarchy (beyond a flat global/
regional split) and the complete set of opt-in scopes it was originally
specified to support. Migration:
`20260810170000_rankings_locality_hierarchy`.

**Note:** the separately-tracked "Part 8: Ranking categories +
provenance" item was not started as part of this Part — it was picked up
later in the session; see Part 8 below (appended after Part 33-49).

## Part 9 — Sports Rankings integration

**Status: IMPLEMENTED, VERIFIED** (commit `63035e9` merge).

Wired Sports match ratings (including the Build Session 12 Part 23-24
Table Tennis addition) into the same scope/locality Rankings system Part
6-7 restored, rather than leaving sports ratings as an island.

## Part 10-12 — Grounded generative research synthesis + tests

**Status: IMPLEMENTED, VERIFIED** (commit `fab0612` merge).

Research mode's `conciseAnswer` is now a real generative synthesis over
retrieved documents (via a new `AiReplyProvider.generateResearchSynthesis`
on all three providers — Anthropic/OpenAI/Gemini — behind the existing
fallback router) with citation-tag verification
(`research-grounding.util.ts`'s `CITATION_TAG_PATTERN`/
`parseGroundedAnswer`), replacing the earlier non-generative
pass-through. Falls back to the prior extractive behavior if every
provider fails, rather than surfacing an error for a non-critical
enhancement.

## Part 13-15 — Vision front/rear camera + position guides + quality score

**Status: IMPLEMENTED, VERIFIED** (commit `fdbdf32` merge).

Live pose-analysis sessions gained front/rear camera switching
(`camera_lens_selection.dart`), on-screen positioning guidance
(`position_guidance.dart` — "move closer," "step back," "center
yourself," computed from pose-frame confidence and framing), and a
per-session tracking-quality score surfaced in the session summary.

## Part 16-27 — Release engineering

**Status: IMPLEMENTED** (commits `957a704`, `8e62cef` merges).
Android/CI portions **NOT_RUN** — no Android SDK, Xcode, or Docker
daemon exists in this sandbox; disclosed per-commit rather than claimed
as compile-verified, matching this repository's established convention
for unverifiable-in-sandbox changes.

- Android package identity, `key.properties`-driven release signing
  (with a debug fallback so unsigned local builds still work), and
  `dev`/`staging`/`prod` product flavors (`build.gradle.kts`), each
  requiring `--flavor` on every `flutter run`/`build` command —
  README updated accordingly.
- `AppConfig.environment` (parsed from `--dart-define=ENVIRONMENT=...`)
  and a visible `EnvironmentBanner` for non-prod builds — deliberately
  never given a fabricated staging/prod `apiBaseUrl` default; that value
  must always be passed explicitly.
- A new `android-build` CI job producing a `prod`-flavor release APK
  artifact.
- Release Readiness V2: a real migration-status check
  (`ReleaseReadinessService.checkMigrations`, comparing `schema.prisma`'s
  migration directories against `_prisma_migrations` via a raw query
  rather than shelling out to the `prisma` CLI, which is pruned from the
  production build) surfaced in a new "Database migrations" section of
  the admin Release Readiness page.
- New docs: `founder-setup-checklist.md`, `staging-deployment.md`,
  `beta-blockers.md`; `qa/release-device-matrix.md` updated.

No new migration this Part — `ReleaseReadinessService` reads the
existing `_prisma_migrations` table rather than adding one.

## Part 33-49 — Paywall polish, Support Help Center, retention, security headers

**Status: IMPLEMENTED, VERIFIED** (commits `4d7c9bc`, `e35e52b`,
`54a2b57` merges — three sub-parts, each independently verified and
merged).

**Security headers + paywall polish** (`4d7c9bc`) — `helmet()`'s
Content-Security-Policy is now tuned rather than left at bare defaults
(`common/middleware/security-headers.ts`'s `buildHelmetOptions`,
unit-tested standalone): every Helmet default directive is preserved,
and only `script-src`/`style-src`/`img-src` are relaxed, and only enough
for Swagger UI (`/docs`, the API's one HTML page — a CSP directive has
no effect on JSON responses) to render. `security.md` updated: the old
"security headers beyond Helmet's defaults have not been reviewed" gap
is resolved; a new gap is documented instead — the admin app has no
deployment/header story at all, and a static CSP `<meta>` tag was
deliberately **not** added to `apps/admin/index.html`, since its real
API host is only known at build time (`VITE_API_BASE_URL`) and a
same-origin-only `connect-src` baked into static HTML would silently
break every cross-origin API call once admin and API are deployed
separately — judged worse than the current honest gap. Paywall: mobile
gained "Restore Purchases" (`PurchaseService.restorePurchases`,
required by App Store guidelines whenever a paywall exists — replayed
purchases feed the existing `PurchaseUpdateStatus.restored` handling
path unchanged) and honest error states on the Subscription screen (a
full-screen retry state when pricing fails to load at all; a
non-destructive banner when a refresh fails but stale data remains
visible).

**Support Help Center** (`e35e52b`) — a static, self-serve FAQ screen
(`faq_entry.dart`'s hardcoded content — no backend CMS exists for it
this sprint, matching the same content-versus-release-cadence tradeoff
as the Terms-of-Service checkbox copy) grouped by category (account,
billing, privacy, Vision, reporting a problem), following the Nutrition
Library screen's existing list-of-cards convention. Reachable from the
Support screen ahead of ticket creation, with a "still need help?" card
linking back into it.

**Retention win-back scheduler** (`54a2b57`) — the first scheduled/cron
job in this codebase, via a newly added `@nestjs/schedule` dependency.
`RetentionService.runWinBackCheck` runs daily, finds users whose most
recent refresh-token activity predates a 14-day inactivity threshold —
the existing real "last opened the app" signal (`RefreshToken.createdAt`
resets on every rotation while the app is in active use), deliberately
not a new `lastActiveAt` column that would start out null for every
current user — and fires a new `NotificationType.RE_ENGAGEMENT`
notification through the existing `NotificationsService.notify`, so the
master switch and per-category opt-out preferences apply exactly as they
do to every other notification type. A 14-day cooldown (checked against
existing `NotificationEvent` rows) stops the daily cron from renotifying
the same inactive user on every run. Migration:
`20260811113220_add_re_engagement_notification_type`.

## Part 8 — Ranking categories + provenance

**Status: IMPLEMENTED, VERIFIED** (commit `5263273` merge). Picked up
after the rest of this report was originally written and merged — see
the Update note in the Summary above.

No Founder-level spec for this exact backlog phrase exists anywhere in
`packages/docs/product/` (checked directly); the closest real
requirement is `design-bible.md`'s Rankings section: "Ranking criteria
shown to the user must be genuinely transparent (what's being measured,
not a black-box score)." Scoped from that plus the domains
`common/scoring/activity-scoring.util.ts` already tracked separately
before blending them into one number:

- **Categories** — `GET /rankings/leaderboard` accepts a new `category`
  query param (`RankingCategory`: `OVERALL`/`STRENGTH`/`CARDIO`/
  `NUTRITION`, default `OVERALL`). A single-category leaderboard sorts
  by that domain's active-day count directly — no cross-domain variety
  bonus to apply, since there's only one domain. `OVERALL`'s existing
  blended score, bonus, and sort order (`points` then `activeDays` then
  `userId`) are byte-for-byte unchanged; every pre-existing rankings
  test still passes against the same assertions.
- **Provenance** — every leaderboard entry (and `/rankings/me`) now
  always includes `strengthDays`/`cardioDays`/`nutritionDays` regardless
  of which category is selected, plus `verifiedCardioDays` — the subset
  of cardio days recorded via `CardioSession.source` being `LIVE_GPS` or
  `WEARABLE` rather than typed in manually, extending a distinction the
  schema already made (see its own doc comment) rather than inventing a
  new verification concept. Mobile shows this as a per-entry breakdown
  line ("2 strength days · 1 cardio day, 1 verified · 3 meal days") and
  a "Ranked by" category chip row above the leaderboard.
- No new migration: `RankingCategory` is a query-time filter with
  nothing to persist, and `CardioSession.source` already existed from
  an earlier session.

## Migrations (this session, chronological)

1. `20260810132227_add_trainer_group_session_rsvp` (Part 3)
2. `20260810134801_add_workout_assignment_declined_status` (Part 4)
3. `20260810150000_trainer_group_scheduled_session_joint_workout_link` (continuation Part B)
4. `20260810160000_privacy_center_default_preferences` (Part 5)
5. `20260810170000_rankings_locality_hierarchy` (Part 6-7)
6. `20260811113220_add_re_engagement_notification_type` (Part 33-49 — retention)

Part 8 added no migration — see its own section above.

## New dependencies

- `@nestjs/schedule: ^6.1.3` (backend, Part 33-49) — powers
  `RetentionService`'s daily `@Cron` job; `ScheduleModule.forRoot()`
  registered once in `AppModule`.

No new mobile or admin dependencies this session.

## Test results (final, on merged `main`, commit `5263273`)

- Backend unit: **1138 passed**, 78 suites (1040 at session start — +98).
- Backend e2e: **371 passed**, 40 suites (349 at session start — +22).
- Backend lint (`eslint --max-warnings=0`): clean.
- Backend build (`nest build`): clean.
- Mobile `flutter analyze`: clean, 0 issues.
- Mobile `dart format --set-exit-if-changed`: clean, 0 files changed
  (609 files checked).
- Mobile `flutter test`: **889 passed** (799 at session start — +90).
- Admin `tsc --noEmit`: clean.
- Admin `eslint`: clean (one pre-existing
  `react-refresh/only-export-components` warning in `AuthContext.tsx`,
  unchanged from Build Session 12, unrelated to this session — not a
  regression, not a lint failure).
- Admin `vitest`: **39 passed**, 12 files (37 at session start — +2).
- Admin `tsc --noEmit && vite build`: clean.

Every number above was observed directly from command output during
this session's final verification pass, run against the actual merged
`main` commit — not carried forward from an earlier, now-stale run.

## Repository hygiene

TODO/FIXME/XXX/HACK audit (word-boundary grep across
`services/api/src`, `apps/admin/src`, `apps/mobile/lib`): **clean, zero
hits.** Consistent with Build Session 12's clean audit — nothing new was
introduced this session that needed a stub marker instead of a real
implementation or an honestly-documented deferral.

## Android/iOS build status

- `flutter build apk` / `flutter build ios`: **NOT_RUN** — this
  environment has no Android SDK and no Xcode, consistent with every
  prior Build Session (7 through 12) in this repository. Part 16-27's
  Gradle/CI changes were verified by directly reading the installed
  package source (`node_modules/.pnpm/helmet@7.2.0/...` for the Helmet
  API shape used in Part 33-49; the actual Kotlin DSL/Gradle syntax used
  in Part 16-27 by cross-referencing Gradle's own documented syntax)
  rather than a live build — disclosed per-commit, not claimed as
  compile-verified.

## Physical-device tests

**NOT_RUN.** No Android/iOS physical device or emulator exists in this
environment. `packages/docs/qa/vision-physical-device-checklist.md` and
`packages/docs/qa/release-device-matrix.md` (both pre-existing) still
have every row honestly `NOT_RUN`; this session did not add device
access and did not pretend otherwise.

## External credentials still required

Unchanged from Build Session 12's list — none of this session's work
closed these gaps, and none of it depended on them:

- A real Firebase project, Apple Developer Program team + APNs key,
  Android SDK/Xcode/a physical device — block live push delivery,
  Vision on real hardware, live Android/iOS builds, and every row in the
  device matrix.
- `BRAVE_SEARCH_API_KEY` — Part 10-12's generative synthesis layer
  degrades gracefully to the prior extractive behavior without it, but
  a live end-to-end research-mode verification still needs it.
- Apple/Google IAP secrets (`APPLE_IAP_SHARED_SECRET`,
  `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`) — pre-existing, unrelated to this
  session's Restore Purchases UI work, which is client-side only.
- A managed Postgres provider or infrastructure-level cron scheduler —
  Part 33-49's retention job runs inside the Nest process via
  `@nestjs/schedule`, which is correct for this deployment shape, but
  a real production deployment needs to confirm exactly one instance of
  the API process runs the schedule (or move it to a dedicated worker)
  once horizontal scaling is in play — not needed at this sprint's
  single-instance scale, flagged here rather than silently assumed away.

## Remaining beta/launch blockers

Carried forward, updated for what this session actually closed:

1. No live push delivery, Vision-on-camera, Android/iOS release build,
   or any device-matrix row has ever been verified on real hardware —
   unchanged from every prior session's disclosure.
2. Camera-assisted sport score suggestions remain deliberately deferred,
   unchanged from Build Session 12 — no pose/ball-tracking infrastructure
   exists.
3. The admin app has no deployment or security-header story at all
   (Part 33-49) — documented explicitly in `security.md` rather than
   papered over with a CSP `<meta>` tag that could break real
   cross-origin deployments.
4. `RetentionService`'s scheduled job has not been load-tested or run
   against production-scale data — the query shape (`groupBy` over every
   `RefreshToken` row) is reasonable at this sprint's scale but has not
   been proven at real user-base scale.
5. No automated backup schedule is wired up anywhere (Build Session 12's
   runbook documents the procedure; scheduling it against a real
   production database remains deployment-specific and out of this
   sandbox's reach) — unchanged.
6. Rankings' `RankingCategory` split (Part 8) covers only the three
   domains `activity-scoring.util.ts` already tracked (strength/cardio/
   nutrition) — Sports' separate Elo-style per-`SportCode` ratings were
   deliberately not merged into this same filterable list, since unifying
   a day-count score with an Elo rating would need real normalization
   design work, not a mechanical extension.

None of the above are new regressions from this session's work — all are
either pre-existing, explicitly scoped out, or newly *disclosed* (not
introduced) by this session's own verification passes, and are carried
forward honestly rather than hidden.
