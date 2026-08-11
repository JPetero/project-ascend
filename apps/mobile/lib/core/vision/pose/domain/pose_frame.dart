import 'pose_landmark.dart';
import 'pose_landmark_type.dart';

/// One analyzed camera frame's full set of detected landmarks — the unit
/// every [PoseDetectorAdapter] implementation produces and every
/// `ExercisePoseAnalyzer` consumes. Analyzers never see a raw ML Kit
/// `Pose`/camera image, only this normalized type.
class PoseFrame {
  const PoseFrame({required this.timestamp, required this.landmarks});

  final DateTime timestamp;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;

  PoseLandmark? landmark(PoseLandmarkType type) => landmarks[type];

  /// Mean confidence across every reported landmark — a coarse overall
  /// visibility signal used for the "insufficient frame visibility" cue,
  /// distinct from the per-joint confidence used to gate rep counting.
  double get overallConfidence {
    if (landmarks.isEmpty) return 0;
    final total = landmarks.values.fold<double>(
      0,
      (sum, l) => sum + l.confidence,
    );
    return total / landmarks.length;
  }
}

/// What a [PoseDetectorAdapter] returns for one processed camera image —
/// ML Kit can report zero or more detected people; Ascend only ever
/// analyzes a single subject, so this wraps "no person detected" as
/// `frame == null` rather than an empty list the caller must re-check.
class PoseDetectorResult {
  const PoseDetectorResult({required this.frame, this.error});

  final PoseFrame? frame;

  /// Set only when the underlying detector call itself failed (e.g. a
  /// platform exception because the on-device model isn't available) —
  /// distinct from `frame == null`, which is the normal "nobody in view"
  /// case. Every existing caller ignores this field, so its addition (S14
  /// Part 19, for the Vision release diagnostics self-test) changes no
  /// existing rep-counting/cue behavior; only the diagnostics screen
  /// reads it, since it's the one place that needs to tell a genuine
  /// detector failure apart from an empty frame.
  final String? error;

  bool get hasPose => frame != null;
}
