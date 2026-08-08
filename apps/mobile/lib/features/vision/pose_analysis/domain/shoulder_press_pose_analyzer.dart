import '../../../../core/vision/pose/domain/pose_confidence.dart';
import '../../../../core/vision/pose/domain/pose_frame.dart';
import '../../../../core/vision/pose/domain/pose_geometry.dart';
import '../../../../core/vision/pose/domain/pose_landmark_type.dart';
import 'exercise_pose_analyzer.dart';
import 'form_observation.dart';
import 'supported_exercise.dart';

enum ShoulderPressPhase { lowered, pressing, overhead, lowering }

/// Shoulder press rep counting from elbow angle (shoulder-elbow-wrist)
/// combined with a wrist-above-shoulder check — elbow angle alone can't
/// distinguish "arm pressed overhead" from "arm extended out to the
/// side," so [ShoulderPressPhase.overhead] additionally requires the
/// wrist to be above the shoulder in the image. Build Session 10 Part 3;
/// see [SquatPoseAnalyzer] for the shared debounce/no-double-count FSM
/// shape this mirrors.
class ShoulderPressPoseAnalyzer implements ExercisePoseAnalyzer {
  ShoulderPressPoseAnalyzer({
    this.loweredAngleThreshold = 100,
    this.overheadAngleThreshold = 160,
    this.minConfidence = 0.5,
    this.debounceFrames = 3,
    this.armAsymmetryThreshold = 20,
    this.shallowOverheadMargin = 15,
  });

  final double loweredAngleThreshold;
  final double overheadAngleThreshold;
  final double minConfidence;
  final int debounceFrames;
  final double armAsymmetryThreshold;
  final double shallowOverheadMargin;

  @override
  SupportedExercise get exercise => SupportedExercise.shoulderPress;

  ShoulderPressPhase _phase = ShoulderPressPhase.lowered;
  bool _hasReachedOverhead = false;
  double _maxElbowAngleThisRep = 0;
  bool _armAsymmetryFlaggedThisRep = false;
  ShoulderPressPhase? _pendingPhase;
  int _pendingFrames = 0;
  bool _lowVisibilityFlagged = false;

  @override
  void reset() {
    _phase = ShoulderPressPhase.lowered;
    _hasReachedOverhead = false;
    _maxElbowAngleThisRep = 0;
    _armAsymmetryFlaggedThisRep = false;
    _pendingPhase = null;
    _pendingFrames = 0;
    _lowVisibilityFlagged = false;
  }

  @override
  ExercisePoseAnalysisUpdate onFrame(PoseFrame frame) {
    final leftElbow = PoseGeometry.angleAt(
      frame: frame,
      vertex: PoseLandmarkType.leftElbow,
      a: PoseLandmarkType.leftShoulder,
      b: PoseLandmarkType.leftWrist,
    );
    final rightElbow = PoseGeometry.angleAt(
      frame: frame,
      vertex: PoseLandmarkType.rightElbow,
      a: PoseLandmarkType.rightShoulder,
      b: PoseLandmarkType.rightWrist,
    );
    final elbowAngle = PoseGeometry.higherConfidence(leftElbow, rightElbow);

    if (elbowAngle == null || elbowAngle.confidence < minConfidence) {
      final observations = <FormObservation>[];
      if (!_lowVisibilityFlagged) {
        _lowVisibilityFlagged = true;
        observations.add(
          FormObservation(
            type: 'insufficient_visibility',
            message:
                "Ascend can't see your arms clearly right now — check your "
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

    final usingLeft =
        leftElbow != null &&
        leftElbow.confidence >= (rightElbow?.confidence ?? -1);
    final wrist = frame.landmark(
      usingLeft ? PoseLandmarkType.leftWrist : PoseLandmarkType.rightWrist,
    );
    final shoulder = frame.landmark(
      usingLeft
          ? PoseLandmarkType.leftShoulder
          : PoseLandmarkType.rightShoulder,
    );
    final isOverheadPosition =
        wrist != null && shoulder != null && wrist.y < shoulder.y;

    // Tracked by angle threshold rather than confirmed (debounced) phase
    // so the first frame that rises above "lowered" is never missed —
    // see SquatPoseAnalyzer's equivalent comment. Larger angle means
    // more extended for this exercise, the opposite direction from
    // squat/curl, so this tracks a maximum rather than a minimum.
    if (elbowAngle.degrees > loweredAngleThreshold) {
      if (elbowAngle.degrees > _maxElbowAngleThisRep) {
        _maxElbowAngleThisRep = elbowAngle.degrees;
      }
      if (!_armAsymmetryFlaggedThisRep &&
          leftElbow != null &&
          rightElbow != null &&
          (leftElbow.degrees - rightElbow.degrees).abs() >
              armAsymmetryThreshold) {
        _armAsymmetryFlaggedThisRep = true;
      }
    }

    final observed = _classify(elbowAngle.degrees, isOverheadPosition);
    final result = _advance(observed, frame.timestamp);

    return ExercisePoseAnalysisUpdate(
      phase: _phase.name,
      repCompleted: result.repCompleted,
      confidence: poseConfidenceFromValue(elbowAngle.confidence),
      frameAccepted: true,
      observations: result.observations,
    );
  }

  ShoulderPressPhase _classify(double elbowDegrees, bool isOverheadPosition) {
    if (elbowDegrees <= loweredAngleThreshold) {
      return ShoulderPressPhase.lowered;
    }
    if (elbowDegrees >= overheadAngleThreshold && isOverheadPosition) {
      return ShoulderPressPhase.overhead;
    }
    final pressing =
        _phase == ShoulderPressPhase.lowered ||
        _phase == ShoulderPressPhase.pressing;
    return pressing ? ShoulderPressPhase.pressing : ShoulderPressPhase.lowering;
  }

  _AdvanceResult _advance(ShoulderPressPhase observed, DateTime timestamp) {
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

    if (observed == ShoulderPressPhase.overhead) {
      _hasReachedOverhead = true;
    }

    if (observed != ShoulderPressPhase.lowered) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }
    if (!_hasReachedOverhead ||
        (previousPhase != ShoulderPressPhase.lowering &&
            previousPhase != ShoulderPressPhase.overhead)) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    final observations = <FormObservation>[];
    if (_maxElbowAngleThisRep <
        overheadAngleThreshold + shallowOverheadMargin) {
      observations.add(
        FormObservation(
          type: 'overhead_range',
          message:
              'Your overhead range appears incomplete on that rep — '
              'pressing a bit further may help, if comfortable for you.',
          confidence: 0.6,
          severity: FormObservationSeverity.coachingCue,
          timestamp: timestamp,
        ),
      );
    }
    if (_armAsymmetryFlaggedThisRep) {
      observations.add(
        FormObservation(
          type: 'arm_asymmetry',
          message:
              'Your left and right arm positions appeared different on '
              'that rep — worth checking your press is even on both sides.',
          confidence: 0.5,
          severity: FormObservationSeverity.checkForm,
          timestamp: timestamp,
        ),
      );
    }

    _hasReachedOverhead = false;
    _maxElbowAngleThisRep = 0;
    _armAsymmetryFlaggedThisRep = false;

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
