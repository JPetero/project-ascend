import 'dart:ui';

import '../../../../core/vision/pose/domain/pose_frame.dart';

/// A single directional hint for getting well-positioned during a live
/// Vision session's calibration phase (S13 Part 13-15) — computed purely
/// from the latest [PoseFrame]'s landmark bounding box relative to the
/// camera image, so it's unit-testable with synthetic frames and never
/// depends on a real camera or ML Kit.
///
/// Left/right guidance is deliberately not attempted: a front camera's
/// preview is typically mirrored while a rear camera's is not, so "move
/// left" would be correct for one lens direction and backwards for the
/// other without extra bookkeeping this module has no reliable way to
/// verify on a real device. [centerYourself] stays direction-neutral —
/// still useful paired with the live skeleton overlay, which does show
/// the user exactly which way they're off — without risking wrong
/// guidance.
enum PositionGuidanceHint { none, moveCloser, stepBack, centerYourself }

String positionGuidanceLabel(PositionGuidanceHint hint) {
  switch (hint) {
    case PositionGuidanceHint.none:
      return '';
    case PositionGuidanceHint.moveCloser:
      return 'Move closer — step in so more of your body fills the frame.';
    case PositionGuidanceHint.stepBack:
      return "Step back — you're too close to the camera.";
    case PositionGuidanceHint.centerYourself:
      return 'Center yourself in the middle of the frame.';
  }
}

const _minConfidentLandmarksForGuidance = 4;
const _smallSubjectHeightRatio = 0.35;
const _largeSubjectHeightRatio = 0.95;
const _offCenterRatio = 0.15;

/// Returns [PositionGuidanceHint.none] whenever there isn't enough
/// confident landmark data to say anything useful, matching
/// [PoseFrame.overallConfidence]'s existing "not enough signal" handling
/// elsewhere in this module rather than guessing from a near-empty frame.
PositionGuidanceHint computePositionGuidance({
  required PoseFrame? frame,
  required Size imageSize,
  double minConfidence = 0.5,
}) {
  if (frame == null || imageSize.width <= 0 || imageSize.height <= 0) {
    return PositionGuidanceHint.none;
  }
  final confident = frame.landmarks.values
      .where((landmark) => landmark.confidence >= minConfidence)
      .toList();
  if (confident.length < _minConfidentLandmarksForGuidance) {
    return PositionGuidanceHint.none;
  }

  var minX = confident.first.x;
  var maxX = confident.first.x;
  var minY = confident.first.y;
  var maxY = confident.first.y;
  for (final landmark in confident) {
    if (landmark.x < minX) minX = landmark.x;
    if (landmark.x > maxX) maxX = landmark.x;
    if (landmark.y < minY) minY = landmark.y;
    if (landmark.y > maxY) maxY = landmark.y;
  }

  final heightRatio = (maxY - minY) / imageSize.height;
  if (heightRatio < _smallSubjectHeightRatio) {
    return PositionGuidanceHint.moveCloser;
  }
  if (heightRatio > _largeSubjectHeightRatio) {
    return PositionGuidanceHint.stepBack;
  }

  final centerX = (minX + maxX) / 2;
  final imageCenterX = imageSize.width / 2;
  final offCenterRatio = (centerX - imageCenterX).abs() / imageSize.width;
  if (offCenterRatio > _offCenterRatio) {
    return PositionGuidanceHint.centerYourself;
  }

  return PositionGuidanceHint.none;
}
