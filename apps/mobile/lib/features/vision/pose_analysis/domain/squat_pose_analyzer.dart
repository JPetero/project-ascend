import '../../../../core/vision/pose/domain/pose_confidence.dart';
import '../../../../core/vision/pose/domain/pose_frame.dart';
import '../../../../core/vision/pose/domain/pose_geometry.dart';
import '../../../../core/vision/pose/domain/pose_landmark_type.dart';
import 'exercise_pose_analyzer.dart';
import 'form_observation.dart';
import 'supported_exercise.dart';

enum SquatPhase { standing, descending, bottom, ascending }

/// Bodyweight squat rep counting from knee angle (hip-knee-ankle) — Build
/// Session 10 Part 3. A full rep is standing → descending → a confirmed
/// depth threshold → ascending → back to standing; only a return to
/// standing *after* depth was reached counts, so a shallow dip or a
/// stumble that never reaches depth is never counted (Part 3's "reject
/// obviously incomplete movement" requirement). Debouncing requires
/// [debounceFrames] consecutive frames agreeing on a new phase before it
/// takes effect, so single-frame landmark jitter can't flip state or
/// double-count a rep.
class SquatPoseAnalyzer implements ExercisePoseAnalyzer {
  SquatPoseAnalyzer({
    this.standingAngleThreshold = 160,
    this.bottomAngleThreshold = 110,
    this.minConfidence = 0.5,
    this.debounceFrames = 3,
    this.kneeAsymmetryThreshold = 20,
    this.shallowDepthMargin = 20,
  });

  final double standingAngleThreshold;
  final double bottomAngleThreshold;
  final double minConfidence;
  final int debounceFrames;
  final double kneeAsymmetryThreshold;
  final double shallowDepthMargin;

  @override
  SupportedExercise get exercise => SupportedExercise.bodyweightSquat;

  SquatPhase _phase = SquatPhase.standing;
  bool _hasReachedDepth = false;
  double _minKneeAngleThisRep = 180;
  bool _kneeAsymmetryFlaggedThisRep = false;
  SquatPhase? _pendingPhase;
  int _pendingFrames = 0;
  bool _lowVisibilityFlagged = false;

  @override
  void reset() {
    _phase = SquatPhase.standing;
    _hasReachedDepth = false;
    _minKneeAngleThisRep = 180;
    _kneeAsymmetryFlaggedThisRep = false;
    _pendingPhase = null;
    _pendingFrames = 0;
    _lowVisibilityFlagged = false;
  }

  @override
  ExercisePoseAnalysisUpdate onFrame(PoseFrame frame) {
    final leftKnee = PoseGeometry.angleAt(
      frame: frame,
      vertex: PoseLandmarkType.leftKnee,
      a: PoseLandmarkType.leftHip,
      b: PoseLandmarkType.leftAnkle,
    );
    final rightKnee = PoseGeometry.angleAt(
      frame: frame,
      vertex: PoseLandmarkType.rightKnee,
      a: PoseLandmarkType.rightHip,
      b: PoseLandmarkType.rightAnkle,
    );
    final kneeAngle = PoseGeometry.higherConfidence(leftKnee, rightKnee);

    if (kneeAngle == null || kneeAngle.confidence < minConfidence) {
      final observations = <FormObservation>[];
      if (!_lowVisibilityFlagged) {
        _lowVisibilityFlagged = true;
        observations.add(
          FormObservation(
            type: 'insufficient_visibility',
            message:
                "Ascend can't see your legs clearly right now — check your "
                'framing and lighting.',
            confidence: 1,
            severity: FormObservationSeverity.info,
            timestamp: frame.timestamp,
          ),
        );
      }
      return ExercisePoseAnalysisUpdate(
        phase: _phase.name,
        repCompleted: false,
        confidence: PoseConfidence.insufficient,
        frameAccepted: false,
        observations: observations,
      );
    }
    _lowVisibilityFlagged = false;

    // Tracked by angle threshold rather than confirmed (debounced) phase
    // so the very first frame that dips below standing is never missed —
    // confirmed `_phase` lags a few frames behind the raw observation by
    // design (that's what debouncing means).
    if (kneeAngle.degrees < standingAngleThreshold) {
      if (kneeAngle.degrees < _minKneeAngleThisRep) {
        _minKneeAngleThisRep = kneeAngle.degrees;
      }
      if (!_kneeAsymmetryFlaggedThisRep &&
          leftKnee != null &&
          rightKnee != null &&
          (leftKnee.degrees - rightKnee.degrees).abs() >
              kneeAsymmetryThreshold) {
        _kneeAsymmetryFlaggedThisRep = true;
      }
    }

    final observed = _classify(kneeAngle.degrees);
    final result = _advance(observed, frame.timestamp);

    return ExercisePoseAnalysisUpdate(
      phase: _phase.name,
      repCompleted: result.repCompleted,
      confidence: poseConfidenceFromValue(kneeAngle.confidence),
      frameAccepted: true,
      observations: result.observations,
    );
  }

  SquatPhase _classify(double kneeDegrees) {
    if (kneeDegrees >= standingAngleThreshold) return SquatPhase.standing;
    if (kneeDegrees <= bottomAngleThreshold) return SquatPhase.bottom;
    final movingDown =
        _phase == SquatPhase.standing || _phase == SquatPhase.descending;
    return movingDown ? SquatPhase.descending : SquatPhase.ascending;
  }

  _AdvanceResult _advance(SquatPhase observed, DateTime timestamp) {
    if (observed == _phase) {
      _pendingPhase = null;
      _pendingFrames = 0;
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    if (_pendingPhase == observed) {
      _pendingFrames++;
    } else {
      _pendingPhase = observed;
      _pendingFrames = 1;
    }
    if (_pendingFrames < debounceFrames) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    _pendingPhase = null;
    _pendingFrames = 0;
    final previousPhase = _phase;
    _phase = observed;

    if (observed == SquatPhase.bottom) {
      _hasReachedDepth = true;
    }

    if (observed != SquatPhase.standing) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    if (!_hasReachedDepth ||
        (previousPhase != SquatPhase.ascending &&
            previousPhase != SquatPhase.bottom)) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    final observations = <FormObservation>[];
    if (_minKneeAngleThisRep > bottomAngleThreshold - shallowDepthMargin) {
      observations.add(
        FormObservation(
          type: 'squat_depth',
          message:
              'Your depth appears limited on that rep — descending a bit '
              'further may help, if comfortable for you.',
          confidence: 0.6,
          severity: FormObservationSeverity.coachingCue,
          timestamp: timestamp,
        ),
      );
    }
    if (_kneeAsymmetryFlaggedThisRep) {
      observations.add(
        FormObservation(
          type: 'knee_tracking',
          message:
              'Your left and right knee angles appeared different during '
              'that rep — worth checking that both knees are tracking '
              'evenly.',
          confidence: 0.5,
          severity: FormObservationSeverity.checkForm,
          timestamp: timestamp,
        ),
      );
    }

    _hasReachedDepth = false;
    _minKneeAngleThisRep = 180;
    _kneeAsymmetryFlaggedThisRep = false;

    return _AdvanceResult(repCompleted: true, observations: observations);
  }
}

class _AdvanceResult {
  const _AdvanceResult({
    required this.repCompleted,
    required this.observations,
  });

  final bool repCompleted;
  final List<FormObservation> observations;
}
