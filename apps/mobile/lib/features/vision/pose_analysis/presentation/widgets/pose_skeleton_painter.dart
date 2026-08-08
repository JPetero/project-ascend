import 'package:flutter/material.dart';

import '../../../../../core/vision/pose/domain/pose_frame.dart';
import '../../../../../core/vision/pose/domain/pose_landmark_type.dart';

/// Bone connections drawn as the live skeleton overlay — deliberately a
/// small, exercise-relevant subset (not all 33 BlazePose points), so the
/// overlay reads as a clear stick figure rather than visual noise.
const _skeletonBones = <(PoseLandmarkType, PoseLandmarkType)>[
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
  (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
  (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
  (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
  (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
  (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
];

/// Maps one landmark's image-space coordinates to canvas-space, given
/// the source image size and the destination canvas size — pure
/// geometry, kept separate from [PoseSkeletonPainter] so the scaling
/// math is unit-testable without a real `Canvas`.
Offset scalePoint({
  required double x,
  required double y,
  required Size imageSize,
  required Size canvasSize,
}) {
  if (imageSize.width == 0 || imageSize.height == 0) return Offset.zero;
  final scaleX = canvasSize.width / imageSize.width;
  final scaleY = canvasSize.height / imageSize.height;
  return Offset(x * scaleX, y * scaleY);
}

/// Draws a static (non-animated) stick-figure overlay from the latest
/// [PoseFrame] — deliberately no animation/motion beyond the frame data
/// itself changing, per Part 5's "reduced-motion users must not receive
/// excessive animated overlays" requirement. Landmarks below
/// [minConfidence] are skipped rather than drawn with false certainty.
class PoseSkeletonPainter extends CustomPainter {
  PoseSkeletonPainter({
    required this.frame,
    required this.imageSize,
    this.minConfidence = 0.5,
  });

  final PoseFrame? frame;
  final Size imageSize;
  final double minConfidence;

  @override
  void paint(Canvas canvas, Size size) {
    final currentFrame = frame;
    if (currentFrame == null) return;

    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final jointPaint = Paint()..color = Colors.greenAccent;

    for (final (a, b) in _skeletonBones) {
      final landmarkA = currentFrame.landmark(a);
      final landmarkB = currentFrame.landmark(b);
      if (landmarkA == null || landmarkB == null) continue;
      if (landmarkA.confidence < minConfidence ||
          landmarkB.confidence < minConfidence) {
        continue;
      }
      final pointA = scalePoint(
        x: landmarkA.x,
        y: landmarkA.y,
        imageSize: imageSize,
        canvasSize: size,
      );
      final pointB = scalePoint(
        x: landmarkB.x,
        y: landmarkB.y,
        imageSize: imageSize,
        canvasSize: size,
      );
      canvas.drawLine(pointA, pointB, linePaint);
      canvas.drawCircle(pointA, 4, jointPaint);
      canvas.drawCircle(pointB, 4, jointPaint);
    }
  }

  @override
  bool shouldRepaint(PoseSkeletonPainter oldDelegate) =>
      oldDelegate.frame != frame;
}
