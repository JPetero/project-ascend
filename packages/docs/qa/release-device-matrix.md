# Release QA Device Matrix

Build Session 12 Part 27-32. This is the manual device/OS coverage
matrix for a mobile release candidate — distinct from the automated
`flutter test` suite (789+ widget/unit tests, run against the Flutter
test harness, not real devices) and from
`qa/vision-physical-device-checklist.md` (a deep-dive on the camera/pose
pipeline specifically). This matrix is the release gate: what to
actually run, on what hardware, before a build ships.

This sandboxed environment has no Android SDK, no Xcode, no physical or
virtual devices, and no App Store/Play Console access — every row below
is honestly `NOT_RUN`. Nothing here may be marked `PASS` without someone
actually installing the build on the listed device/OS and observing the
behavior.

## Status vocabulary

Same convention as `qa/vision-physical-device-checklist.md`:

- `NOT_RUN` — not attempted yet.
- `PASS` — run on the real device/OS, behaved as described.
- `FAIL` — run on the real device/OS, did not behave as described. Note what happened in a linked issue.
- `BLOCKED` — cannot be attempted right now (e.g. no device available, needs a signed build, needs a store-sandbox account).

## Device/OS coverage

Pick the *minimum* set that actually exercises the OS-version and
form-factor variance that matters — this is not "test on every device
Apple/Google ever shipped." Prioritize the oldest supported OS version
(most likely to hit a deprecated-API or permission-flow difference) and
the newest (most likely to hit an OS behavior change that shipped after
this app was last tested), plus one mid-range and one small-screen
device on each platform.

| # | Platform | Device class | OS version | Rationale | Status |
|---|---|---|---|---|---|
| 1 | Android | Small/low-end phone (e.g. a budget device, ~4-6GB RAM) | Minimum supported API level (API 26 per `qa/vision-physical-device-checklist.md`'s prerequisites — confirm against `android/app/build.gradle.kts`'s actual `minSdk` before release) | Oldest-OS + weakest-hardware combination is where camera/ML Kit performance (Vision) and background cardio tracking are most likely to degrade or crash | NOT_RUN |
| 2 | Android | Mid-range phone | Latest stable Android at release time | Represents the median real user; also the device most Android users will actually be on | NOT_RUN |
| 3 | Android | Foldable or tablet | Latest stable Android at release time | Layout/responsive-design regressions (text overflow, fixed-width dialogs, the design system's spacing scale) surface here first | NOT_RUN |
| 4 | iOS | Small-screen iPhone (e.g. iPhone SE-class form factor) | Minimum supported iOS version (per `qa/vision-physical-device-checklist.md`'s prerequisites — confirm against `ios/Runner.xcodeproj`'s deployment target before release) | Smallest safe-area/notch-less layout; also the oldest-iOS device most likely to hit a permission-flow or `sign_in_with_apple` difference | NOT_RUN |
| 5 | iOS | Current-generation iPhone | Latest stable iOS at release time | Represents the median real iOS user; also where new OS privacy prompts (e.g. a new permission dialog wording) show up first | NOT_RUN |
| 6 | iOS | iPad | Latest stable iOS at release time | Only relevant if the app is distributed for iPad, not just "runs in compatibility mode" — confirm target device family in App Store Connect before deciding whether this row applies | NOT_RUN |

## Release-gate checklist (run once per device/OS row above)

Organized by subsystem so a partial re-test (e.g. "only Vision changed
this release") can skip unaffected sections — note in the row's Notes
column which sections were actually exercised if not running the full
list.

### Install & first run

| # | Check | Status | Notes |
|---|---|---|---|
| 1 | Fresh install completes and the app launches to the Welcome/onboarding screen, not a crash | NOT_RUN | |
| 2 | Register a new account end-to-end (terms acceptance, password, onboarding profile questions) | NOT_RUN | |
| 3 | Google Sign-In completes end-to-end (real OAuth flow, not the `FakeGoogleAuthProvider` test double) | NOT_RUN | |
| 4 | Apple Sign-In completes end-to-end (iOS only; real `sign_in_with_apple` flow) | NOT_RUN | iOS-only row |
| 5 | Log out and log back in with the same credentials | NOT_RUN | |
| 6 | Force-quit the app mid-onboarding and relaunch — resumes or restarts cleanly, no crash or stuck state | NOT_RUN | |

### Core workout/nutrition loop

| # | Check | Status | Notes |
|---|---|---|---|
| 7 | Start, log sets for, and finish a real workout session | NOT_RUN | |
| 8 | Log a meal via search and via a custom food entry | NOT_RUN | |
| 9 | Airplane-mode mid-session: log a set offline, confirm it's queued (`SyncEngine`'s outbox), then reconnect and confirm it syncs | NOT_RUN | Exercises the offline-first sync engine on real network transitions, not the in-memory fakes the automated suite uses |
| 10 | Background the app mid-workout (home button/app switcher) and return — session state is preserved | NOT_RUN | |

### Camera-dependent features

| # | Check | Status | Notes |
|---|---|---|---|
| 11 | Vision live session — see `qa/vision-physical-device-checklist.md` for the full 20-point checklist; link its result here rather than duplicating | NOT_RUN | Cross-reference, don't re-run inline |
| 12 | Food photo capture (if camera-based food logging is enabled for this build) completes and returns a result | NOT_RUN | |
| 13 | Media upload (gallery/avatar/post) from both camera capture and photo library picker | NOT_RUN | |

### Location & background execution

| # | Check | Status | Notes |
|---|---|---|---|
| 14 | GPS cardio session records a real route outdoors (not a simulator-injected location) | NOT_RUN | |
| 15 | Backgrounding during an active GPS cardio session continues tracking (not silently paused by the OS) | NOT_RUN | |
| 16 | Location permission prompts show the in-app rationale before the OS dialog, and denial is handled gracefully | NOT_RUN | |

### Push notifications

| # | Check | Status | Notes |
|---|---|---|---|
| 17 | A real FCM push notification is received while the app is backgrounded/killed, and tapping it deep-links to the correct screen | NOT_RUN | Requires a real device — FCM does not reliably reach emulators |
| 18 | Notification permission prompt shows the in-app rationale before the OS dialog | NOT_RUN | |

### In-app purchases

| # | Check | Status | Notes |
|---|---|---|---|
| 19 | Google Play Billing: complete a real (sandbox/test-track) Premium purchase and confirm entitlement unlocks immediately | NOT_RUN | Requires a Play Console test track and a licensed tester account |
| 20 | Apple StoreKit: complete a real (sandbox) Premium purchase and confirm entitlement unlocks immediately | NOT_RUN | Requires an App Store Connect sandbox tester account |
| 21 | Restore purchases on a fresh install recovers existing Premium entitlement | NOT_RUN | |

### Accessibility & platform conventions

| # | Check | Status | Notes |
|---|---|---|---|
| 22 | System font-size scaling (largest accessibility text size) does not clip or overlap critical UI | NOT_RUN | |
| 23 | VoiceOver (iOS) / TalkBack (Android) can navigate the primary flows (dashboard, start a workout, log a meal) | NOT_RUN | |
| 24 | System dark mode toggling is reflected immediately without restart | NOT_RUN | |
| 25 | Back-gesture/back-button behavior matches platform convention (Android hardware/gesture back vs iOS swipe-back) on nested screens | NOT_RUN | |

### App lifecycle & store readiness

| # | Check | Status | Notes |
|---|---|---|---|
| 26 | Deep link from a push notification, a shared Ascend link, and an OS-level universal/app link all open the correct in-app screen | NOT_RUN | |
| 27 | App update from the previous released version preserves login session and local data (no forced re-onboarding) | NOT_RUN | Requires a previously-released build to update from |
| 28 | Release build (not debug) — obfuscation/signing configured, no debug banners or `flutter run` dev tooling visible | NOT_RUN | S13 Part 16-27 wired a real `key.properties`-driven signing config into `android/app/build.gradle.kts` (see `android/key.properties.example`), but it still falls back to debug signing whenever `key.properties` is absent — as it is everywhere this app has been built so far, including CI. This row can't pass until a real upload keystore is generated and `key.properties` is populated (Founder setup checklist), and the resulting `prod`-flavor release build is confirmed signingConfig != debug. |

## Known gap: this session has never run any row in this matrix

Every row above is `NOT_RUN` because this sandboxed development
environment has no Android SDK, no Xcode/iOS Simulator, no physical
devices, and no store sandbox accounts (see
`qa/vision-physical-device-checklist.md`'s identical disclosure for the
same underlying reason). This matrix is deliverable as a checklist for
whoever has access to real devices before a release ships — it should
not be read as "these have been verified," only as "these are the
specific things to verify."
