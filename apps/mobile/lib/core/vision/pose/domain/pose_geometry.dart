import 'dart:math' as math;

import 'joint_angle.dart';
import 'pose_frame.dart';
import 'pose_landmark.dart';
import 'pose_landmark_type.dart';

/// Pure 2D trigonometry over a [PoseFrame] — no exercise-specific
/// knowledge lives here, only "what angle does this vertex form between
/// these two other landmarks." Every `ExercisePoseAnalyzer` builds on
/// this instead of computing angles inline, so the one place that could
/// get the math wrong is tested once.
class PoseGeometry {
  const PoseGeometry._();

  /// The angle at [vertex] between rays to [a] and [b], in degrees
  /// (0-180). Returns null if any of the three landmarks is missing from
  /// the frame — callers must treat that as "can't evaluate this angle
  /// this frame," not as a zero angle.
  static JointAngle? angleAt({
    required PoseFrame frame,
    required PoseLandmarkType vertex,
    required PoseLandmarkType a,
    required PoseLandmarkType b,
  }) {
    final v = frame.landmark(vertex);
    final pa = frame.landmark(a);
    final pb = frame.landmark(b);
    if (v == null || pa == null || pb == null) return null;

    final degrees = _angleBetween(v, pa, pb);
    if (degrees == null) return null;

    final confidence = math.min(
      v.confidence,
      math.min(pa.confidence, pb.confidence),
    );
    return JointAngle(vertex: vertex, degrees: degrees, confidence: confidence);
  }

  /// Whichever of two candidate angles (typically the left/right side of
  /// a bilateral joint) has higher confidence — analyzers use this so a
  /// partially-occluded side doesn't block detection when the other side
  /// is clearly visible.
  static JointAngle? higherConfidence(JointAngle? a, JointAngle? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.confidence >= b.confidence ? a : b;
  }

  static double? _angleBetween(
    PoseLandmark vertex,
    PoseLandmark a,
    PoseLandmark b,
  ) {
    final v1x = a.x - vertex.x;
    final v1y = a.y - vertex.y;
    final v2x = b.x - vertex.x;
    final v2y = b.y - vertex.y;

    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (mag1 == 0 || mag2 == 0) return null;

    final cosAngle = ((v1x * v2x + v1y * v2y) / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }
}
