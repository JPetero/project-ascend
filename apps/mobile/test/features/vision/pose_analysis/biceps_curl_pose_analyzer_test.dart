import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vision/pose_analysis/domain/biceps_curl_pose_analyzer.dart';
import 'package:mobile/features/vision/pose_analysis/domain/form_observation.dart';

import 'pose_frame_fixtures.dart';

void main() {
  group('BicepsCurlPoseAnalyzer', () {
    late BicepsCurlPoseAnalyzer analyzer;

    setUp(() {
      analyzer = BicepsCurlPoseAnalyzer(debounceFrames: 3);
    });

    void feed(double angle, {int times = 1}) {
      for (var i = 0; i < times; i++) {
        analyzer.onFrame(curlFrame(angle));
      }
    }

    test(
      'counts one rep for a full extended-to-contracted-to-extended cycle',
      () {
        feed(170, times: 3); // extended
        feed(100, times: 3); // flexing
        feed(40, times: 3); // contracted (below 60 threshold)
        feed(100, times: 3); // extending
        var repCounted = false;
        for (var i = 0; i < 5; i++) {
          if (analyzer.onFrame(curlFrame(170)).repCompleted) repCounted = true;
        }

        expect(repCounted, isTrue);
      },
    );

    test('does not count a rep that never reaches contraction', () {
      feed(170, times: 3);
      feed(90, times: 5); // never crosses 60
      var repCounted = false;
      for (var i = 0; i < 3; i++) {
        if (analyzer.onFrame(curlFrame(170)).repCompleted) repCounted = true;
      }

      expect(repCounted, isFalse);
    });

    test('does not double-count while holding extended afterward', () {
      feed(170, times: 3);
      feed(40, times: 3);
      var repCount = 0;
      for (var i = 0; i < 10; i++) {
        if (analyzer.onFrame(curlFrame(170)).repCompleted) repCount++;
      }

      expect(repCount, 1);
    });

    test('low-confidence frames are not accepted', () {
      feed(170, times: 3);
      final update = analyzer.onFrame(curlFrame(90, confidence: 0.1));
      expect(update.frameAccepted, isFalse);
    });

    test('reset clears contraction-reached state', () {
      feed(170, times: 3);
      feed(40, times: 3);
      analyzer.reset();

      var repCounted = false;
      for (var i = 0; i < 5; i++) {
        if (analyzer.onFrame(curlFrame(170)).repCompleted) repCounted = true;
      }
      expect(repCounted, isFalse);
    });

    test(
      'emits an incomplete-range cue when contraction is only barely reached',
      () {
        feed(170, times: 3);
        feed(58, times: 3); // barely under contractedAngleThreshold (60)
        feed(100, times: 3);
        final observations = <FormObservation>[];
        for (var i = 0; i < 3; i++) {
          observations.addAll(analyzer.onFrame(curlFrame(170)).observations);
        }

        expect(observations.any((o) => o.type == 'curl_range'), isTrue);
      },
    );

    test(
      'emits an elbow-drift cue when the elbow swings substantially during the rep',
      () {
        feed(170, times: 3);
        // Elbow drifts far from its starting x-offset while flexing.
        analyzer.onFrame(curlFrame(100, elbowXOffset: 0));
        analyzer.onFrame(curlFrame(90, elbowXOffset: 5));
        analyzer.onFrame(curlFrame(80, elbowXOffset: 5));
        for (var i = 0; i < 3; i++) {
          analyzer.onFrame(curlFrame(40, elbowXOffset: 5));
        }
        final observations = <FormObservation>[];
        for (var i = 0; i < 3; i++) {
          observations.addAll(
            analyzer.onFrame(curlFrame(170, elbowXOffset: 0)).observations,
          );
        }

        expect(observations.any((o) => o.type == 'elbow_drift'), isTrue);
      },
    );
  });
}
