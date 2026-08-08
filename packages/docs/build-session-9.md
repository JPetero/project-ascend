# Build Session 9 — Completion, Intelligence, and Release Readiness

Continues directly from `main` at the merge of Build Session 8 (`285810b`,
"Merge Build Session 8 final report"). Branch:
`claude/session-9-completion-intelligence`. Nothing from prior sessions was
regenerated or replaced — every change here is additive on top of that
history (Workout Engine, offline-first Workout/Nutrition, achievements,
live GPS cardio, Health Connect/HealthKit, Community, Media Platform,
friendship system, DMs, Trainer Groups, Joint Workouts, Sports Matches,
Rankings/Seasons/Challenges, Nutrition Library, notifications,
subscription/entitlement architecture, Premium Vision shell, Assistant,
Support backend, Admin web app, Ascend Promote, account data export). Work
followed the directive's Parts 4–23 priority order and ran autonomously:
implement → test → commit → push the feature branch → merge into `main`
with `--no-ff` → re-verify on `main` → push `main` → continue, with no
pause for confirmation between parts.

A branch-naming note for anyone continuing this work: the harness's
outer system prompt for later turns in this session named a different
branch (`claude/new-session-qy6hzm`). That branch was investigated and
found to be empty/stale (far behind `main`, no Session 9 work at all —
boilerplate from session creation). All Session 9 work is on
`claude/session-9-completion-intelligence`, which is unambiguously the
correct branch: it contains this entire session's coherent history and
every part's matching merge into `main`.

Final `main` head at the end of this session: **`225c1c7`** (plus this
document's own commit on top).

---

## Parts completed

1. **Part 1 — Stale dashboard placeholders + navigation seams.** Connected
   the Dashboard to real Rankings/Friends/Messages data instead of
   placeholder copy.
2. **Part 2 — Profile customization + private gallery.** Bio, avatar, one
   cover image, a private PROGRESS/GENERAL gallery, privacy controls
   shipped free from day one.
3. **Part 3 — Universal Ascend share system.** Native device share sheet
   (`share_plus`) wired to achievements and Community posts via a single
   `AscendShareService`.
4. **Part 4 — Password recovery + email verification.** Real token-based
   flows, `EMAIL_PROVIDER=console` by default (logs instead of sending;
   `smtp` is real but needs live SMTP credentials this environment
   doesn't have).
5. **Part 5/6 — Account & Security Center + account deletion.** Change
   password, linked-identity view, resend verification, sign-out-
   everywhere (revokes every refresh-token family at once), and a real
   account-deletion flow, consolidated into one screen.
6. **Part 7 — Complete data export.** Extended the Session 8 Part 14
   export to include Joint Workout and Sports Match participation, closing
   the gap that session had explicitly disclosed as cut.
7. **Part 8 — Google/Apple sign-in backend + account linking.** Real
   verifier architecture (`GoogleTokenVerifier`/`AppleTokenVerifier`)
   against the pre-existing `AuthIdentity` model; honestly rejects with
   "not configured" — no live `GOOGLE_OAUTH_CLIENT_ID`/`APPLE_CLIENT_ID`
   in this environment.
8. **Part 9 — Real on-device workout reminder notifications.** Local
   scheduled notifications (not push) respecting per-category preferences
   from Session 8 Part 9's notification center.
9. **Part 10 — True active-session background cardio continuation.**
   Android foreground service (`FOREGROUND_SERVICE_LOCATION`) and iOS
   "Always"-authorized background location updates, both requested only
   once a live GPS session has actually started, never at launch.
10. **Part 11/12/13 — Vision Form Coach, Progress Scan, Food Scan V1.**
    Three of the six Premium Vision modules gained genuine (non-simulated)
    V1 assists built entirely on existing plumbing: side-by-side gallery
    photo comparison, capture-then-log-via-search, and capture-then-static-
    checklist review. No ML/pose/food-recognition model exists anywhere —
    Rep Counter, Sport Capture, and Outfit Guidance remain capture-only.
11. **Part 14 — Atlas/Nova voice V1.** On-device `speech_to_text` input and
    `flutter_tts` output around the existing deterministic dialogue
    pipeline; no audio ever leaves the phone; both require explicit
    per-session activation.
12. **Part 15/16 — Live AI provider routing + research mode V1.** A new
    `AssistantModule` (`POST /assistant/reply`) proxies to Anthropic via
    `@anthropic-ai/sdk` when `ANTHROPIC_API_KEY` is configured;
    `LiveAiProvider extends AiProvider` directly (never wraps the local
    provider, so the safety gate stays structurally un-bypassable),
    falling back to the free deterministic companion on any error.
    Research Mode's live, source-verified answers remain deliberately
    unavailable — an LLM call alone can't satisfy Scenario 19's
    no-fabricated-citation rule.
13. **Part 17/18 — Store purchases + affordability review.** Real Apple
    (`verifyReceipt`, prod→sandbox fallback) and Google (Play Developer
    API) purchase verifiers behind `PurchasesModule`; only a verified
    purchase ever flips `UserSubscription.tier` to PREMIUM. Mobile wired
    to the official `in_app_purchase` plugin.
14. **Part 19 — Granular admin RBAC.** A new `AdminPermission` enum/grant
    model and `AdminPermissionGuard` layer on top of the existing binary
    `UserRole.ADMIN` floor; self-service grant/revoke UI in the admin web
    app, gated by a `MANAGE_ADMINS` permission.
15. **Part 20/21 — Trainer Groups expanded (Premium) tier + UX audit.**
    Larger owned-group/member limits, a distinct `MODERATOR` role, and
    owner/moderator broadcast announcements, all resolved against the
    group *owner's* subscription tier. UX audit corrected two stale
    `parking-lot.md` claims (native share, achievement celebrations were
    both already shipped but still listed as open).
16. **Part 22/23 — Integration tests + release configuration audit.** A
    new e2e spec proves the real purchase→Premium→cross-module-feature
    cascade using a DI-substituted fake Apple verifier (the only piece
    needing live credentials) driving genuine `PurchasesService` →
    `CapabilityService` → `TrainerGroupsService` code. Release audit: fixed
    a real `.env.example` gap (seven undocumented `MEDIA_S3_*` variables),
    added `.github/dependabot.yml` (no dependency-update automation
    existed for any of the four ecosystems), and corrected two more stale
    `parking-lot.md` claims (Trainer Groups Premium tier, data export).

**Descoped, not touched this session** (outside the directive's explicit
Parts 4–23 priority order): no items were skipped from that list — every
named part shipped in some real form, each with an honest disclosure of
what remains architecture-only where full delivery wasn't possible without
external credentials this environment doesn't have.

---

## New user-facing functionality

- A consolidated **Account & Security Center**: change password, resend
  verification, view linked Google/Apple identities, sign out of every
  device at once, delete account.
- A **private gallery** and richer **profile customization** (bio, avatar,
  cover image, privacy controls).
- **Native sharing** of achievements and Community posts via the device's
  own share sheet.
- **Password recovery** and **email verification** via real emailed links
  (console-logged by default in this environment).
- **Google/Apple sign-in** buttons and account-linking UI (inert until a
  live OAuth client id is configured).
- **Local workout reminder notifications** honoring per-category
  preferences.
- **Live GPS cardio sessions now survive backgrounding** on both platforms
  via a real foreground service / background-location authorization.
- **Vision Form Coach, Progress Scan, and Food Scan** now do something
  real (comparison, search-assisted logging, checklist review) instead of
  capture-only.
- **Voice input/output** for the Atlas/Nova companion, entirely on-device.
- **A real "Buy Premium" flow** in `SubscriptionScreen`, showing the live
  store price and driving an actual purchase when a store connection
  exists.
- **Trainer Group announcements** and a promotable **Moderator** role,
  both gated on the group owner holding Premium.
- **Admins page** (`apps/admin`) for self-service permission grant/revoke
  among admin accounts.

---

## Premium functionality advanced

- Real, verifiable purchase → entitlement pipeline (`POST
  /purchases/verify`) — the only path that ever writes a PREMIUM
  `UserSubscription` row, now proven end-to-end by Part 22/23's
  integration test against a substituted-but-real verifier chain.
- Live AI companion replies (Anthropic-backed) gated behind
  `AppCapability.advancedAiConversations`, with a hard, structurally
  un-bypassable safety gate shared with the free deterministic path.
- Premium voice I/O (`AppCapability.premiumCompanionVoices`).
- Trainer Groups expanded tier: larger limits, Moderator role, owner/
  moderator announcements — all resolved against the group owner's tier,
  confirmed by both a unit-level and a live-HTTP-cascade e2e test.
- Vision module V1 assists remain free-shell/Premium-capability-gated as
  established in Session 7/8; no change to that gate this session.

---

## Account/security changes

- Password reset and email verification are now real, token-based flows
  (previously architecture-only).
- Google/Apple `AuthIdentity` linking has a real verifier layer (still
  inert without a live OAuth client id).
- Sign-out-everywhere (all refresh-token families) and account deletion
  are real, reachable actions.
- Admin access is no longer a single binary floor: `AdminPermission`
  grants (`MODERATE_COMMUNITY`, `REVIEW_ELIGIBILITY`, `MANAGE_SUPPORT`,
  `REVIEW_PROMOTIONS`, `MANAGE_ADMINS`) scope each of the four admin
  surfaces independently; existing ADMIN accounts were backfilled with
  every permission except `MANAGE_ADMINS` at migration time so nobody
  already trusted lost access.
- **Known, disclosed gap** (see Remaining Founder requirements): there is
  still no per-device session listing / single-session revoke — only
  all-at-once sign-out-everywhere exists, even though `RefreshToken`
  already records a `deviceName` at issuance.

---

## Vision/AI progress

- `AssistantModule` gives the companion a real LLM-backed reply path,
  additive to (never replacing) the free deterministic dialogue.
- Voice I/O is genuine on-device speech-to-text/text-to-speech, not a
  simulated stub.
- Three Premium Vision modules (Form Coach, Progress Scan, Food Scan) do
  real, non-fabricated work; the other three (Rep Counter, Sport Capture,
  Outfit Guidance) remain honest capture-only placeholders — no ML model
  exists anywhere in this codebase for any of the six.
- Research Mode's citation-verified live answers remain deliberately
  unshipped — the one item in this session's AI scope kept unavailable on
  purpose, per Scenario 19's anti-fabrication rule.

---

## Commits and pushes

Every part above was committed on `claude/session-9-completion-intelligence`,
pushed, merged into `main` with `--no-ff`, re-verified, and pushed to
`main` before the next part began. Merge commits on `main`, in order:

- `a498bdc` Merge Build Session 9 Part 1: connect Dashboard to real Rankings/Friends/Messages
- `1a6e00a` Merge Build Session 9 Part 2: profile media and private gallery
- `d9513e7` Merge Build Session 9 Part 3: universal Ascend share system
- `93874c6` Merge Build Session 9 Part 4: password recovery + email verification
- `690cab1` Merge Build Session 9 Part 5/6: Account & Security Center + account deletion
- `60ee1cc` Merge Build Session 9 Part 7: complete data export
- `39e5b22` Merge Build Session 9 Part 8: Google/Apple sign-in backend + account linking
- `d4039eb` Merge Build Session 9 Part 9: real on-device workout reminder notifications
- `77c9e71` Merge Build Session 9 Part 10: true active-session background cardio tracking
- `153c450` Merge Build Session 9 Part 11-13: Vision Form Coach, Progress Scan, Food Scan V1
- `8bb9450` Merge Build Session 9 Part 14: Atlas/Nova voice V1
- `f379f6a` Merge Build Session 9 Part 15/16: live AI provider routing + research mode V1
- `5818745` Merge Build Session 9 Part 17/18: store purchase verification + affordability review
- `e93065c` Merge Build Session 9 Part 19: granular admin RBAC
- `7cb8470` Merge Build Session 9 Part 20/21: Trainer Groups expanded tier + UX audit
- `225c1c7` Merge Build Session 9 Part 22/23: integration tests + release config audit

---

## Migrations

Five new Prisma migrations this session (most parts reused existing
models/columns and needed none):

- `20260807213311_profile_media_and_gallery` (Part 2)
- `20260807221021_password_reset_and_email_verification` (Part 4)
- `20260808144543_store_purchases` — `Purchase` model,
  `PurchasePlatform`/`PurchaseStatus` enums (Part 17/18)
- `20260808151047_admin_permission_grants` — `AdminPermission` enum,
  `AdminPermissionGrant` model, plus a hand-written backfill INSERT
  granting every non-`MANAGE_ADMINS` permission to existing ADMIN
  accounts (Part 19)
- `20260808153000_trainer_groups_expanded` — adds `MODERATOR` to
  `TrainerGroupMemberRole` (a positional enum insert, which needed a
  hand-written migration — Prisma's CLI can't do this non-interactively),
  plus the new `TrainerGroupAnnouncement` model (Part 20)

All five apply cleanly via `prisma migrate deploy` from a clean database
(confirmed as part of every part's verification pass, and again in the
Part 22/23 final check on merged `main`).

---

## Backend verification

Run against a real local Postgres 16 cluster for every check this
session (never mocked):

- `npx tsc --noEmit` — clean.
- `pnpm test` (unit) — **536 passed**, 51 suites.
- `pnpm test:e2e` — **254 passed**, 30 suites (was 224/28 at the start of
  this session; +30 tests / +2 suites added this session, including the
  new `purchase-premium-cascade.e2e-spec.ts`,
  `trainer-groups-expanded.e2e-spec.ts`, and `admin-rbac.e2e-spec.ts`).
- `npx prisma validate` / `prisma migrate deploy` — clean, no pending
  migrations, on merged `main`.
- `eslint --fix` was run after most multi-file edits (standard workflow
  this session); the only unreviewed-looking diff it produced (a
  631-line reformat of `prisma/seed.ts` plus a small one in
  `assistant-prompt.ts` during Part 22/23) was verified byte-for-byte
  semantically identical to its pre-formatting content (whitespace-
  stripped diff showed zero token changes beyond trailing commas and
  quote-style normalization) before being committed.

---

## Flutter verification

- `flutter analyze` — clean.
- `dart format --output=none --set-exit-if-changed .` — clean (CI-
  enforced).
- `flutter test` — **539 passed**, run fresh at the end of this session
  (headless, no device/simulator).
- **No physical device or simulator run was performed this session** —
  every mobile-facing part (background cardio, Vision modules, voice I/O,
  purchases, Trainer Groups UI) rests on widget/unit tests and static
  analysis only. This is the same disclosed limitation as every prior
  session; nothing here claims live on-device behavior that wasn't
  actually exercised.

---

## Admin verification

- `apps/admin`: `pnpm test` — **29 passed**, 9 files, run fresh at the end
  of this session (Vitest + Testing Library, jsdom — no live browser).
- Part 19's RBAC UI (`AdminsPage`, permission-filtered nav/routes) is
  covered by these automated tests; unlike Session 8 Part 17's admin app
  delivery, this session did not additionally drive it through a live
  headless-browser Playwright run — that deeper verification exists only
  for the original admin app build, not for this session's RBAC layer on
  top of it.

---

## External credentials still required

None of the following exist in this environment; every feature that
needs them was built to honestly reject/degrade rather than fabricate
success, and is disclosed as such in `parking-lot.md`:

- `APPLE_IAP_SHARED_SECRET`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`,
  `GOOGLE_PLAY_PACKAGE_NAME` — real App Store Connect / Google Play
  Console accounts and store product configuration.
- `GOOGLE_OAUTH_CLIENT_ID`, `APPLE_CLIENT_ID` — real OAuth client
  registrations for Google/Apple sign-in.
- `ANTHROPIC_API_KEY` — a live key to exercise `AssistantModule` against
  a real model (the integration was built and unit/e2e-tested against the
  honest "not configured" path only).
- `SMTP_HOST`/`SMTP_USER`/`SMTP_PASSWORD` — real SMTP credentials to
  actually deliver password-reset/verification email (the `console`
  provider logs instead, which is what every test exercises).
- A release Android keystore — `apps/mobile/android/app/build.gradle.kts`
  currently signs the release build config with the **debug** key
  (`signingConfig = signingConfigs.getByName("debug")`); this is expected
  given no Play Console account/keystore exists, but is now explicitly
  called out here as a release-readiness blocker rather than left
  implicit. iOS `CODE_SIGN_STYLE = Automatic` similarly has no real Apple
  Developer Team configured.
- No production secrets/credentials of any kind were found committed to
  the repository (checked this session via a pattern scan for private
  keys, AWS/Google API key shapes, and `.env`-shaped files — none found;
  `.gitignore` already excludes every `.env`/`.env.local` variant per
  service).

---

## Physical-device checks still required

- Live GPS background-continuation (Part 10): foreground service /
  background location authorization code is written and native-config-
  complete (`AndroidManifest.xml`, `Info.plist`), but never exercised on
  a real Android/iOS device this session.
- Voice I/O (Part 14): `speech_to_text`/`flutter_tts` integration is real
  code, untested on a physical microphone/speaker.
- Camera-based Vision modules (Part 11-13): capture flows are real,
  unexercised against a live device camera.
- In-app purchase flow (Part 17/18): the `in_app_purchase` plugin
  integration has never talked to a real App Store/Play Store sandbox.
- All of the above were already-disclosed limitations carried in from
  Session 8; nothing changed about physical-device access this session.

---

## Remaining Founder requirements

1. **Store accounts and credentials** — an App Store Connect account (+
   shared secret) and a Google Play Console account (+ service-account
   JSON, package name) are required before Part 17/18's purchase flow can
   be exercised for real, and before a release keystore can be generated
   for Android.
2. **OAuth client registrations** — Google and Apple sign-in client ids,
   to activate Part 8's account-linking flow.
3. **An Anthropic API key** — to exercise Part 15/16's live AI companion
   against a real model rather than only its honest fallback path.
4. **SMTP credentials** (or a transactional email provider) — to actually
   deliver Part 4's password-reset/verification emails outside of the
   console-logging default.
5. **A decision on per-device session management** — whether the
   parking-lot.md gap (list individual sessions/devices, revoke just one,
   distinct from today's sign-out-everywhere) is worth a dedicated future
   part.
6. **Physical devices** (Android + iOS) for the accumulated backlog of
   device-only verification above — none of it can be closed further
   without hardware access.

---

## Recommended Build Session 10

With the Parts 4–23 priority list now fully delivered in some real form,
the highest-value remaining work is credential activation and physical
verification rather than new architecture:

1. **Store & OAuth credential activation**, once the Founder has App
   Store Connect / Google Play Console / Google & Apple OAuth
   registrations: flip the honest "not configured" paths built across
   Parts 8 and 17/18 to real ones, and generate a real Android release
   keystore.
2. **First physical-device verification pass** — Android and iOS, working
   through the backlog above (background GPS, voice I/O, camera Vision
   modules, a real store sandbox purchase) now that months of
   device-only-feature backlog exists across Sessions 8 and 9.
3. **Per-device session listing and single-session revoke** — the one
   concretely-scoped account-security gap identified this session;
   `RefreshToken.deviceName` already exists, so this is a comparatively
   small addition (list + a targeted revoke endpoint/UI) rather than new
   architecture.
4. **A dedicated full-screen vertical-swipe Reel viewer** — flagged by
   Part 20/21's UX audit as the next well-scoped Community polish item
   (Reels currently only play inline in the feed).
5. **Live AI activation follow-through**, once a key exists: exercise
   `AssistantModule` against real conversations to validate the shared
   safety-prompt layer actually holds up against live model output, not
   just the deterministic fallback tested this session.
