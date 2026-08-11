import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/vision/pose/domain/pose_landmark.dart';
import 'package:mobile/core/vision/pose/domain/pose_landmark_type.dart';
import 'package:mobile/features/vision/pose_analysis/domain/position_guidance.dart';

import 'pose_frame_fixtures.dart';

const _imageSize = Size(1000, 1000);

/// A landmark bounding box roughly centered and appropriately sized in a
/// 1000x1000 image — the "well framed, say nothing" baseline every other
/// case in this file perturbs one way or another.
List<PoseLandmark> _wellFramedLandmarks({double confidence = 0.9}) => [
  PoseLandmark(
    type: PoseLandmarkType.leftShoulder,
    x: 400,
    y: 200,
    confidence: confidence,
  ),
  PoseLandmark(
    type: PoseLandmarkType.rightShoulder,
    x: 600,
    y: 200,
    confidence: confidence,
  ),
  PoseLandmark(
    type: PoseLandmarkType.leftAnkle,
    x: 400,
    y: 800,
    confidence: confidence,
  ),
  PoseLandmark(
    type: PoseLandmarkType.rightAnkle,
    x: 600,
    y: 800,
    confidence: confidence,
  ),
];

void main() {
  group('computePositionGuidance', () {
    test('returns none when there is no frame yet', () {
      final hint = computePositionGuidance(frame: null, imageSize: _imageSize);

      expect(hint, PositionGuidanceHint.none);
    });

    test('returns none when the image size is not yet known', () {
      final frame = frameFromLandmarks(_wellFramedLandmarks());

      final hint = computePositionGuidance(frame: frame, imageSize: Size.zero);

      expect(hint, PositionGuidanceHint.none);
    });

    test('returns none when too few landmarks are confident', () {
      final frame = frameFromLandmarks([
        PoseLandmark(
          type: PoseLandmarkType.leftShoulder,
          x: 500,
          y: 500,
          confidence: 0.9,
        ),
      ]);

      final hint = computePositionGuidance(frame: frame, imageSize: _imageSize);

      expect(hint, PositionGuidanceHint.none);
    });

    test('returns none for a well-centered, appropriately sized subject', () {
      final frame = frameFromLandmarks(_wellFramedLandmarks());

      final hint = computePositionGuidance(frame: frame, imageSize: _imageSize);

      expect(hint, PositionGuidanceHint.none);
    });

    test('returns moveCloser when the subject is small in frame', () {
      final frame = frameFromLandmarks([
        PoseLandmark(
          type: PoseLandmarkType.leftShoulder,
          x: 480,
          y: 480,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.rightShoulder,
          x: 520,
          y: 480,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.leftAnkle,
          x: 480,
          y: 520,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.rightAnkle,
          x: 520,
          y: 520,
          confidence: 0.9,
        ),
      ]);

      final hint = computePositionGuidance(frame: frame, imageSize: _imageSize);

      expect(hint, PositionGuidanceHint.moveCloser);
    });

    test('returns stepBack when the subject overflows the frame', () {
      final frame = frameFromLandmarks([
        PoseLandmark(
          type: PoseLandmarkType.leftShoulder,
          x: 450,
          y: 0,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.rightShoulder,
          x: 550,
          y: 0,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.leftAnkle,
          x: 450,
          y: 1000,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.rightAnkle,
          x: 550,
          y: 1000,
          confidence: 0.9,
        ),
      ]);

      final hint = computePositionGuidance(frame: frame, imageSize: _imageSize);

      expect(hint, PositionGuidanceHint.stepBack);
    });

    test('returns centerYourself when the subject is off to one side', () {
      final frame = frameFromLandmarks([
        PoseLandmark(
          type: PoseLandmarkType.leftShoulder,
          x: 50,
          y: 200,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.rightShoulder,
          x: 150,
          y: 200,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.leftAnkle,
          x: 50,
          y: 800,
          confidence: 0.9,
        ),
        PoseLandmark(
          type: PoseLandmarkType.rightAnkle,
          x: 150,
          y: 800,
          confidence: 0.9,
        ),
      ]);

      final hint = computePositionGuidance(frame: frame, imageSize: _imageSize);

      expect(hint, PositionGuidanceHint.centerYourself);
    });

    test(
      'ignores low-confidence landmarks when computing the bounding box',
      () {
        final frame = frameFromLandmarks([
          ..._wellFramedLandmarks(),
          // Should be excluded from the bounding box, or this would shift
          // it far off-center and wrongly trigger centerYourself.
          PoseLandmark(
            type: PoseLandmarkType.nose,
            x: 5,
            y: 5,
            confidence: 0.1,
          ),
        ]);

        final hint = computePositionGuidance(
          frame: frame,
          imageSize: _imageSize,
        );

        expect(hint, PositionGuidanceHint.none);
      },
    );
  });

  group('positionGuidanceLabel', () {
    test('the none hint has an empty label', () {
      expect(positionGuidanceLabel(PositionGuidanceHint.none), isEmpty);
    });

    test('every non-none hint has a non-empty, distinct label', () {
      final nonNoneHints = PositionGuidanceHint.values.where(
        (hint) => hint != PositionGuidanceHint.none,
      );
      final labels = nonNoneHints.map(positionGuidanceLabel).toList();

      expect(labels, everyElement(isNotEmpty));
      expect(labels.toSet().length, labels.length);
    });
  });
}
