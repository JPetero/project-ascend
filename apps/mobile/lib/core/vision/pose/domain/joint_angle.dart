import 'pose_landmark_type.dart';

/// The angle at one joint (the vertex) formed by two adjacent bones —
/// e.g. the knee angle formed by the hip-knee and knee-ankle segments.
/// This is 2D-only geometry from a single camera view, not true 3D
/// biomechanics: camera angle, lens distortion, and limb rotation toward/
/// away from the camera all affect the measured degrees. Every analyzer
/// and UI surface using this must treat it as an estimate, never an exact
/// joint angle — see `ExercisePoseAnalyzer`'s doc comment.
class JointAngle {
  const JointAngle({
    required this.vertex,
    required this.degrees,
    required this.confidence,
  });

  final PoseLandmarkType vertex;
  final double degrees;
  final double confidence;
}
