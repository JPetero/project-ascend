# Vision Pose Engine — Physical Device Validation Checklist

Build Session 11 Part 7. This checklist exists because the entire Vision
live-camera + on-device pose-detection pipeline (`camera` +
`google_mlkit_pose_detection`, built across Build Session 10 Parts 2-6 and
extended in Build Session 11 Part 7) has **never been exercised on real
hardware or an emulator** — this sandboxed environment has no Android
SDK, no Xcode, and no camera device. Every status below is honest about
that: nothing here may be marked `PASS` without someone actually running
it on a physical Android or iOS device and observing the real behavior.

## Status vocabulary

Use exactly one of these per row — never anything else, and never `PASS`
without having actually run the check:

- `NOT_RUN` — not attempted yet.
- `PASS` — run on a real device, behaved as described.
- `FAIL` — run on a real device, did not behave as described. Note what
  happened.
- `BLOCKED` — cannot be attempted right now (e.g. no device available,
  needs a signed build).

## Before you start: the diagnostics screen

S14 Part 19 added a Vision release diagnostics screen — tap the bug icon
in the app bar of any Vision mode with live camera analysis (Form Coach/
Rep Counter). It shows exactly the device/build identity to note against
each row below, plus a one-tap self-test that opens the camera and runs
one frame through the real on-device pose detector — run it first; a
failure there explains most of the rows below failing too, rather than
each needing separate diagnosis.

## Prerequisites

- A physical Android device (API 26+, camera-equipped) or iOS device
  (iOS 15+, camera-equipped) — the `camera`/ML Kit plugins are not
  reliably testable on desktop emulators for live camera streams.
- A signed or debug build with `VISION_ACCESS` entitlement available
  (Premium tier, or a test account upgraded via the same out-of-band
  `UserSubscription` write the e2e tests use).
- A quiet, well-lit space with room to stand back from the camera.

## Checklist

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Camera permission prompt appears on first "Start live session" tap, with the in-app explanation shown beforehand | NOT_RUN | |
| 2 | Denying permission shows the "camera access is needed" retry state, not a crash | NOT_RUN | |
| 3 | Permanently denying (Android "don't ask again" / iOS Settings-only) shows the "permanently denied" state with a path to Settings | NOT_RUN | |
| 4 | Camera preview renders live video within ~1s of granting permission | NOT_RUN | |
| 5 | **Calibration**: standing in frame, the "Getting you in frame…" overlay shows and its progress bar advances, then the screen transitions to the live rep-counting view automatically — no manual "I'm ready" tap needed | NOT_RUN | |
| 6 | Calibration does not complete while the frame is empty (camera pointed at a wall/ceiling) or only partially shows a person | NOT_RUN | |
| 7 | Skeleton overlay (`PoseSkeletonPainter`) aligns visually with the real body position, not offset/mirrored/rotated | NOT_RUN | Especially check device rotation (portrait vs. any auto-rotate) |
| 8 | A full squat rep is counted correctly for `bodyweight_squat` | NOT_RUN | |
| 9 | A full curl rep is counted correctly for `biceps_curl` | NOT_RUN | |
| 10 | A full press rep is counted correctly for `shoulder_press` | NOT_RUN | |
| 11 | Manual +1/-1 correction works during a session and after stopping | NOT_RUN | |
| 12 | Coaching cues (depth-limited, knee-tracking, elbow-drift, incomplete-range) appear when the corresponding form issue is actually performed | NOT_RUN | |
| 13 | Pause/Resume correctly freezes and resumes the elapsed timer and the camera preview | NOT_RUN | |
| 14 | Backgrounding the app (home button / app switcher) during a live session pauses tracking and tears down the camera — resuming the app returns to a safe state, not a crash or a stuck camera | NOT_RUN | |
| 15 | Stopping a session shows the summary screen with an accurate rep count and cue list | NOT_RUN | |
| 16 | Saving a session succeeds and the result appears in Vision results history | NOT_RUN | |
| 17 | Frame throttling (~200ms) keeps the UI responsive — no visible stutter/frame drops in the camera preview itself | NOT_RUN | |
| 18 | Battery/thermal: a 5+ minute continuous session does not cause the device to overheat-throttle or the app to be killed | NOT_RUN | |
| 19 | Front-camera behavior: currently the app always selects the **back** camera (see `vision_live_session_screen.dart`'s `_startSession`) — confirm this is the intended production behavior, or file a follow-up if front-camera self-view is expected | NOT_RUN | Known gap, see below |
| 20 | Low-light behavior: confidence correctly drops and the "can't see you clearly" state is communicated rather than silently miscounting reps | NOT_RUN | |

## Known gaps not covered by this session's changes

Documented honestly rather than silently fixed, since each needs either a
product decision or more validation time than this session had:

- **No temporal smoothing.** Each frame's landmark positions/joint angles
  are used as ML Kit reports them, frame to frame — no moving-average/
  exponential/one-euro filtering. The debounce in each exercise analyzer
  (require N consecutive frames to agree before flipping rep phase)
  reduces jitter's effect on *rep counting*, but a skeleton overlay or
  angle readout could still visibly jitter frame to frame. Worth
  revisiting once real-device footage shows whether this matters in
  practice.
- **Mirror handling is untested.** The live session always requests the
  back camera (`CameraLensDirection.back`), which sidesteps the classic
  "front camera mirrors the image" problem rather than solving it. If a
  future session adds front-camera support (e.g. so the user can see
  themselves while training solo), the landmark left/right mapping and
  `PoseSkeletonPainter` will need an explicit mirror transform — neither
  exists today.
- **No per-session aggregate quality metadata.** `VisionAnalysisSession`
  stores `analysisVersion` (now validated against a known allow-list —
  Build Session 11 Part 8) but no device model, camera resolution, or
  session-level average confidence. Per-observation `confidence` exists
  on `VisionFormObservation`, but there's no single "how reliable was
  this whole session" number to show a user or to filter low-quality
  results out of trend analytics later.
