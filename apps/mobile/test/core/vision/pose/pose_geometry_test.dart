import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/vision/pose/domain/joint_angle.dart';
import 'package:mobile/core/vision/pose/domain/pose_frame.dart';
import 'package:mobile/core/vision/pose/domain/pose_geometry.dart';
import 'package:mobile/core/vision/pose/domain/pose_landmark.dart';
import 'package:mobile/core/vision/pose/domain/pose_landmark_type.dart';

void main() {
  group('PoseGeometry.angleAt', () {
    test('computes a right angle for perpendicular rays', () {
      final frame = PoseFrame(
        timestamp: DateTime.utc(2026),
        landmarks: {
          PoseLandmarkType.leftKnee: const PoseLandmark(
            type: PoseLandmarkType.leftKnee,
            x: 0,
            y: 0,
            confidence: 0.9,
          ),
          PoseLandmarkType.leftHip: const PoseLandmark(
            type: PoseLandmarkType.leftHip,
            x: 1,
            y: 0,
            confidence: 0.9,
          ),
          PoseLandmarkType.leftAnkle: const PoseLandmark(
            type: PoseLandmarkType.leftAnkle,
            x: 0,
            y: 1,
            confidence: 0.9,
          ),
        },
      );

      final angle = PoseGeometry.angleAt(
        frame: frame,
        vertex: PoseLandmarkType.leftKnee,
        a: PoseLandmarkType.leftHip,
        b: PoseLandmarkType.leftAnkle,
      );

      expect(angle, isNotNull);
      expect(angle!.degrees, closeTo(90, 0.01));
    });

    test('computes 180 degrees for a straight line', () {
      final frame = PoseFrame(
        timestamp: DateTime.utc(2026),
        landmarks: {
          PoseLandmarkType.leftKnee: const PoseLandmark(
            type: PoseLandmarkType.leftKnee,
            x: 0,
            y: 0,
            confidence: 0.9,
          ),
          PoseLandmarkType.leftHip: const PoseLandmark(
            type: PoseLandmarkType.leftHip,
            x: -1,
            y: 0,
            confidence: 0.9,
          ),
          PoseLandmarkType.leftAnkle: const PoseLandmark(
            type: PoseLandmarkType.leftAnkle,
            x: 1,
            y: 0,
            confidence: 0.9,
          ),
        },
      );

      final angle = PoseGeometry.angleAt(
        frame: frame,
        vertex: PoseLandmarkType.leftKnee,
        a: PoseLandmarkType.leftHip,
        b: PoseLandmarkType.leftAnkle,
      );

      expect(angle!.degrees, closeTo(180, 0.01));
    });

    test('returns null when a landmark is missing from the frame', () {
      final frame = PoseFrame(
        timestamp: DateTime.utc(2026),
        landmarks: {
          PoseLandmarkType.leftKnee: const PoseLandmark(
            type: PoseLandmarkType.leftKnee,
            x: 0,
            y: 0,
            confidence: 0.9,
          ),
        },
      );

      final angle = PoseGeometry.angleAt(
        frame: frame,
        vertex: PoseLandmarkType.leftKnee,
        a: PoseLandmarkType.leftHip,
        b: PoseLandmarkType.leftAnkle,
      );

      expect(angle, isNull);
    });

    test('confidence is the minimum of the three landmarks involved', () {
      final frame = PoseFrame(
        timestamp: DateTime.utc(2026),
        landmarks: {
          PoseLandmarkType.leftKnee: const PoseLandmark(
            type: PoseLandmarkType.leftKnee,
            x: 0,
            y: 0,
            confidence: 0.9,
          ),
          PoseLandmarkType.leftHip: const PoseLandmark(
            type: PoseLandmarkType.leftHip,
            x: 1,
            y: 0,
            confidence: 0.4,
          ),
          PoseLandmarkType.leftAnkle: const PoseLandmark(
            type: PoseLandmarkType.leftAnkle,
            x: 0,
            y: 1,
            confidence: 0.7,
          ),
        },
      );

      final angle = PoseGeometry.angleAt(
        frame: frame,
        vertex: PoseLandmarkType.leftKnee,
        a: PoseLandmarkType.leftHip,
        b: PoseLandmarkType.leftAnkle,
      );

      expect(angle!.confidence, closeTo(0.4, 0.001));
    });
  });

  group('PoseGeometry.higherConfidence', () {
    test('returns the higher-confidence angle', () {
      const low = JointAngle(
        vertex: PoseLandmarkType.leftKnee,
        degrees: 90,
        confidence: 0.3,
      );
      const high = JointAngle(
        vertex: PoseLandmarkType.leftKnee,
        degrees: 90,
        confidence: 0.8,
      );
      expect(PoseGeometry.higherConfidence(low, high), high);
      expect(PoseGeometry.higherConfidence(high, low), high);
    });

    test('returns whichever argument is non-null', () {
      const only = JointAngle(
        vertex: PoseLandmarkType.leftKnee,
        degrees: 90,
        confidence: 0.5,
      );
      expect(PoseGeometry.higherConfidence(null, only), only);
      expect(PoseGeometry.higherConfidence(only, null), only);
      expect(PoseGeometry.higherConfidence(null, null), isNull);
    });
  });
}
