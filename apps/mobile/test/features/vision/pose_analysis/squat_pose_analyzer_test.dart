import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vision/pose_analysis/domain/form_observation.dart';
import 'package:mobile/features/vision/pose_analysis/domain/squat_pose_analyzer.dart';

import 'pose_frame_fixtures.dart';

void main() {
  group('SquatPoseAnalyzer', () {
    late SquatPoseAnalyzer analyzer;

    setUp(() {
      analyzer = SquatPoseAnalyzer(debounceFrames: 3);
    });

    void feed(double angle, {int times = 1}) {
      for (var i = 0; i < times; i++) {
        analyzer.onFrame(squatFrame(angle));
      }
    }

    test('counts one rep for a full standing-to-bottom-to-standing cycle', () {
      feed(170, times: 3); // standing
      feed(130, times: 3); // descending
      feed(90, times: 3); // bottom (below 110 threshold)
      feed(130, times: 3); // ascending
      final last = analyzer.onFrame(squatFrame(170));
      // Need debounceFrames consecutive `standing` frames to confirm.
      analyzer.onFrame(squatFrame(170));
      final confirmed = analyzer.onFrame(squatFrame(170));

      expect([last, confirmed].any((u) => u.repCompleted), isTrue);
    });

    test('does not count a rep that never reaches depth', () {
      feed(170, times: 3); // standing
      feed(
        140,
        times: 5,
      ); // shallow dip, never crosses bottomAngleThreshold (110)
      final results = <bool>[];
      for (var i = 0; i < 3; i++) {
        results.add(analyzer.onFrame(squatFrame(170)).repCompleted);
      }

      expect(results.any((r) => r), isFalse);
    });

    test(
      'does not double-count a single rep while holding standing afterward',
      () {
        feed(170, times: 3);
        feed(90, times: 3);
        var repCount = 0;
        for (var i = 0; i < 10; i++) {
          if (analyzer.onFrame(squatFrame(170)).repCompleted) repCount++;
        }

        expect(repCount, 1);
      },
    );

    test('a single noisy frame does not flip phase (debounce)', () {
      feed(170, times: 5);
      // One single stray low-angle frame, then back to standing.
      final noisy = analyzer.onFrame(squatFrame(100));
      final after = analyzer.onFrame(squatFrame(170));

      expect(noisy.repCompleted, isFalse);
      expect(after.repCompleted, isFalse);
      expect(after.phase, 'standing');
    });

    test(
      'low-confidence frames are not accepted and do not reset progress',
      () {
        feed(170, times: 3);
        feed(90, times: 3); // reach depth
        final lowConfidenceUpdate = analyzer.onFrame(lowConfidenceFrame());
        expect(lowConfidenceUpdate.frameAccepted, isFalse);

        // Recovery: still counts the rep once visibility returns.
        feed(130, times: 3);
        var repCounted = false;
        for (var i = 0; i < 5; i++) {
          if (analyzer.onFrame(squatFrame(170)).repCompleted) repCounted = true;
        }
        expect(repCounted, isTrue);
      },
    );

    test('reset clears phase and depth-reached state', () {
      feed(170, times: 3);
      feed(90, times: 3);
      analyzer.reset();

      // After reset, standing-only frames must not spuriously count a rep.
      var repCounted = false;
      for (var i = 0; i < 5; i++) {
        if (analyzer.onFrame(squatFrame(170)).repCompleted) repCounted = true;
      }
      expect(repCounted, isFalse);
    });

    test(
      'emits a depth-limited coaching cue when depth is only barely reached',
      () {
        feed(170, times: 3);
        // bottomAngleThreshold defaults to 110, shallowDepthMargin defaults
        // to 20 -> a min angle of 125 is within the "barely reached" band
        // (below 110 to register as bottom, but above 130 to be flagged).
        feed(109, times: 3);
        feed(130, times: 3);
        final updates = <FormObservation>[];
        for (var i = 0; i < 3; i++) {
          updates.addAll(analyzer.onFrame(squatFrame(170)).observations);
        }

        expect(updates.any((o) => o.type == 'squat_depth'), isTrue);
      },
    );

    test(
      'emits a knee-tracking cue when left/right knee angles diverge at depth',
      () {
        feed(170, times: 3);
        for (var i = 0; i < 3; i++) {
          analyzer.onFrame(asymmetricSquatFrame(90, 30));
        }
        feed(130, times: 3);
        final updates = <FormObservation>[];
        for (var i = 0; i < 3; i++) {
          updates.addAll(analyzer.onFrame(squatFrame(170)).observations);
        }

        expect(updates.any((o) => o.type == 'knee_tracking'), isTrue);
      },
    );

    test(
      'manual correction is a controller-level concern, not analyzer state',
      () {
        // The analyzer only ever reports auto-detected reps via
        // repCompleted; +1/-1 correction lives in the controller that
        // tracks a separate manual offset — see
        // LiveVisionSessionController.
        feed(170, times: 3);
        final update = analyzer.onFrame(squatFrame(170));
        expect(update.repCompleted, isFalse);
      },
    );
  });
}
