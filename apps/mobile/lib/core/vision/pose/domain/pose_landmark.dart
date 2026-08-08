import 'pose_landmark_type.dart';

/// A single normalized landmark position for one frame. `x`/`y` are in
/// image pixel space (not 0-1 normalized) so angle math in [PoseGeometry]
/// is unaffected by aspect ratio; `confidence` is ML Kit's per-landmark
/// `likelihood` (0.0-1.0), renamed so no analyzer or UI code needs to know
/// which underlying pose SDK produced it.
class PoseLandmark {
  const PoseLandmark({
    required this.type,
    required this.x,
    required this.y,
    required this.confidence,
  });

  final PoseLandmarkType type;
  final double x;
  final double y;
  final double confidence;
}
