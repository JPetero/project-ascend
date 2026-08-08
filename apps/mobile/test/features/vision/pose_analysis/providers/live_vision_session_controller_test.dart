import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/vision/pose/domain/pose_confidence.dart';
import 'package:mobile/features/vision/pose_analysis/domain/supported_exercise.dart';
import 'package:mobile/features/vision/pose_analysis/presentation/providers/live_vision_session_controller.dart';

import '../pose_frame_fixtures.dart';

void main() {
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
      'low-confidence frames still update confidence/lastFrameAccepted without counting a rep',
      () {
        final controller = LiveVisionSessionController(
          exercise: SupportedExercise.bodyweightSquat,
        );
        controller.start();
        controller.processFrame(lowConfidenceFrame());

        expect(controller.state.lastFrameAccepted, isFalse);
        expect(controller.state.confidence, PoseConfidence.insufficient);
        expect(controller.state.autoRepCount, 0);
      },
    );
  });
}
