import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vision/pose_analysis/domain/shoulder_press_pose_analyzer.dart';

import 'pose_frame_fixtures.dart';

void main() {
  group('ShoulderPressPoseAnalyzer', () {
    late ShoulderPressPoseAnalyzer analyzer;

    setUp(() {
      analyzer = ShoulderPressPoseAnalyzer(debounceFrames: 3);
    });

    test('counts one rep for a full lowered-to-overhead-to-lowered cycle', () {
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressLoweredFrame());
      }
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressMidFrame());
      }
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressOverheadFrame());
      }
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressMidFrame());
      }

      var repCounted = false;
      for (var i = 0; i < 5; i++) {
        if (analyzer.onFrame(shoulderPressLoweredFrame()).repCompleted) {
          repCounted = true;
        }
      }

      expect(repCounted, isTrue);
    });

    test('does not count a rep that never reaches overhead', () {
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressLoweredFrame());
      }
      for (var i = 0; i < 6; i++) {
        analyzer.onFrame(shoulderPressMidFrame());
      }

      var repCounted = false;
      for (var i = 0; i < 3; i++) {
        if (analyzer.onFrame(shoulderPressLoweredFrame()).repCompleted) {
          repCounted = true;
        }
      }

      expect(repCounted, isFalse);
    });

    test('does not double-count while holding lowered afterward', () {
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressLoweredFrame());
      }
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressOverheadFrame());
      }

      var repCount = 0;
      for (var i = 0; i < 10; i++) {
        if (analyzer.onFrame(shoulderPressLoweredFrame()).repCompleted) {
          repCount++;
        }
      }

      expect(repCount, 1);
    });

    test('low-confidence frames are not accepted', () {
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressLoweredFrame());
      }
      final update = analyzer.onFrame(shoulderPressLowConfidenceFrame());
      expect(update.frameAccepted, isFalse);
    });

    test('reset clears overhead-reached state', () {
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressLoweredFrame());
      }
      for (var i = 0; i < 3; i++) {
        analyzer.onFrame(shoulderPressOverheadFrame());
      }
      analyzer.reset();

      var repCounted = false;
      for (var i = 0; i < 5; i++) {
        if (analyzer.onFrame(shoulderPressLoweredFrame()).repCompleted) {
          repCounted = true;
        }
      }
      expect(repCounted, isFalse);
    });
  });
}
