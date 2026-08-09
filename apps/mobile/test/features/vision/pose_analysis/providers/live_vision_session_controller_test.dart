import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/vision/pose/domain/pose_confidence.dart';
import 'package:mobile/features/vision/pose_analysis/domain/supported_exercise.dart';
import 'package:mobile/features/vision/pose_analysis/presentation/providers/live_vision_session_controller.dart';

import '../pose_frame_fixtures.dart';

/// Feeds enough good-visibility frames to clear calibration and land the
/// controller in `running` — mirrors what a real session does
/// automatically once the subject is in frame (Build Session 11 Part 7).
/// Every pre-existing rep-counting test calls this right after `start()`
/// so it keeps exercising the analyzer behavior it was written for,
/// rather than the calibration gate itself.
void _calibrate(LiveVisionSessionController controller) {
  for (var i = 0; i < 5; i++) {
    controller.processFrame(squatFrame(170));
  }
}

void main() {
  group('LiveVisionSessionController calibration', () {
    test('start() enters calibrating, not running', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();

      expect(controller.state.status, LiveVisionSessionStatus.calibrating);
    });

    test(
      'frames during calibration never advance the rep count, even ones that would complete a rep',
      () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.start();
        // Only 2 of the 5 required good frames — still calibrating.
        controller.processFrame(squatFrame(170));
        controller.processFrame(squatFrame(90));

        expect(controller.state.status, LiveVisionSessionStatus.calibrating);
        expect(controller.state.autoRepCount, 0);
      },
    );

    test('calibrationProgress reports partial progress before completing', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();
      controller.processFrame(squatFrame(170));
      controller.processFrame(squatFrame(170));

      expect(controller.state.calibrationProgress, closeTo(2 / 5, 0.001));
    });

    test('a low-confidence frame resets the calibration streak', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();
      controller.processFrame(squatFrame(170));
      controller.processFrame(squatFrame(170));
      controller.processFrame(squatFrame(170, confidence: 0.1));

      expect(controller.state.calibrationProgress, 0);
      expect(controller.state.status, LiveVisionSessionStatus.calibrating);
    });

    test('transitions to running once enough good frames arrive', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();
      _calibrate(controller);

      expect(controller.state.status, LiveVisionSessionStatus.running);
      expect(controller.state.calibrationProgress, 1);
    });
  });

  group('LiveVisionSessionController', () {
    test(
      'is idle until start() is called, and processFrame is a no-op before then',
      () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.processFrame(squatFrame(90));

        expect(controller.state.status, LiveVisionSessionStatus.idle);
        expect(controller.state.repCount, 0);
      },
    );

    test('counts a full rep once running', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();
      _calibrate(controller);

      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(170));
      }
      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(90));
      }
      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(170));
      }

      expect(controller.state.autoRepCount, 1);
      expect(controller.state.repCount, 1);
    });

    test('frames delivered while paused do not advance the rep count', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();
      _calibrate(controller);
      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(170));
      }
      controller.pause();

      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(90));
      }
      expect(controller.state.autoRepCount, 0);

      controller.resume();
      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(90));
      }
      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(170));
      }
      expect(controller.state.autoRepCount, 1);
    });

    test(
      'manual correction is layered on top of the auto count without touching it',
      () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.start();
        _calibrate(controller);
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(170));
        }
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(90));
        }
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(170));
        }
        expect(controller.state.autoRepCount, 1);

        controller.incrementManually();
        expect(controller.state.repCount, 2);
        expect(controller.state.autoRepCount, 1);

        controller.decrementManually();
        controller.decrementManually();
        expect(controller.state.repCount, 0); // floors at zero, never negative
        expect(controller.state.autoRepCount, 1);
      },
    );

    test(
      'resetCounts clears both auto and manual counts and the analyzer state',
      () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.start();
        _calibrate(controller);
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(170));
        }
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(90));
        }
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(170));
        }
        controller.incrementManually();
        expect(controller.state.repCount, 2);

        controller.resetCounts();
        expect(controller.state.repCount, 0);
        expect(controller.state.cues, isEmpty);

        // The underlying analyzer was reset too — a fresh full cycle
        // counts exactly one rep, not a continuation of prior progress.
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(90));
        }
        for (var i = 0; i < 3; i++) {
          controller.processFrame(squatFrame(170));
        }
        expect(controller.state.autoRepCount, 1);
      },
    );

    test('surfaces cues emitted by the analyzer', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();
      _calibrate(controller);
      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(170));
      }
      for (var i = 0; i < 3; i++) {
        controller.processFrame(asymmetricSquatFrame(90, 30));
      }
      for (var i = 0; i < 3; i++) {
        controller.processFrame(squatFrame(170));
      }

      expect(controller.state.cues, isNotEmpty);
      expect(controller.state.latestCue, isNotNull);
    });

    test('tracks elapsed time from start, freezing it while paused', () {
      var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      withClock(Clock(() => now), () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.start();
        // Calibration frames processed at the same instant `now` already
        // is, so the timer effectively starts here — matching the elapsed
        // assertions below exactly as they were before calibration
        // existed.
        _calibrate(controller);

        now = now.add(const Duration(seconds: 5));
        controller.processFrame(squatFrame(170));
        expect(controller.state.elapsed, const Duration(seconds: 5));

        controller.pause();
        now = now.add(const Duration(seconds: 30));
        // Paused time must not count toward elapsed.
        expect(controller.state.elapsed, const Duration(seconds: 5));

        controller.resume();
        now = now.add(const Duration(seconds: 2));
        controller.processFrame(squatFrame(170));
        expect(controller.state.elapsed, const Duration(seconds: 7));
      });
    });

    test('stop() moves to completed and freezes state', () {
      final controller = LiveVisionSessionController(
        exercise: SupportedExercise.bodyweightSquat,
      );
      controller.start();
      _calibrate(controller);
      controller.processFrame(squatFrame(170));
      controller.stop();

      expect(controller.state.status, LiveVisionSessionStatus.completed);

      // Frames after stop must not change anything.
      final before = controller.state.autoRepCount;
      for (var i = 0; i < 5; i++) {
        controller.processFrame(squatFrame(90));
      }
      expect(controller.state.autoRepCount, before);
    });

    test(
      'a low-confidence frame during calibration updates confidence without completing calibration',
      () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.start();
        controller.processFrame(lowConfidenceFrame());

        expect(controller.state.status, LiveVisionSessionStatus.calibrating);
        expect(controller.state.confidence, PoseConfidence.insufficient);
        expect(controller.state.autoRepCount, 0);
      },
    );

    test(
      'a low-confidence frame once running still updates confidence/lastFrameAccepted without counting a rep',
      () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.start();
        _calibrate(controller);
        controller.processFrame(lowConfidenceFrame());

        expect(controller.state.status, LiveVisionSessionStatus.running);
        expect(controller.state.lastFrameAccepted, isFalse);
        expect(controller.state.confidence, PoseConfidence.insufficient);
        expect(controller.state.autoRepCount, 0);
      },
    );
  });
}
