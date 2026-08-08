import '../../../../core/vision/pose/domain/pose_confidence.dart';
import '../../../../core/vision/pose/domain/pose_frame.dart';
import 'form_observation.dart';
import 'supported_exercise.dart';

/// What one processed [PoseFrame] produced. `phase` is the analyzer's
/// exercise-specific state name (e.g. `'STANDING'`, `'BOTTOM'`) rendered
/// as-is by the UI — see each concrete analyzer's phase enum.
class ExercisePoseAnalysisUpdate {
  const ExercisePoseAnalysisUpdate({
    required this.phase,
    required this.repCompleted,
    required this.confidence,
    required this.frameAccepted,
    this.observations = const [],
  });

  final String phase;

  /// True only on the exact frame a full repetition was confirmed —
  /// callers add 1 to their own running count, they never re-derive it
  /// from `phase` alone.
  final bool repCompleted;

  final PoseConfidence confidence;

  /// False when the frame's relevant landmarks were missing or below
  /// the analyzer's minimum-confidence threshold — the analyzer did not
  /// update its state machine this frame. The UI should show "can't see
  /// you clearly" rather than a stale rep count silently frozen.
  final bool frameAccepted;

  final List<FormObservation> observations;
}

/// A deterministic, per-exercise temporal state machine over a stream of
/// [PoseFrame]s (Build Session 10 Part 3). Every implementation must:
///
/// - require a minimum landmark confidence before trusting an angle;
/// - debounce phase transitions across several consecutive frames
///   (never flip state on one noisy frame);
/// - only count a repetition once the full expected range of motion was
///   actually observed (reject shallow/incomplete movement rather than
///   counting it);
/// - guard against double-counting a single repetition;
/// - tolerate a short run of low-confidence/missing frames without
///   losing the current rep count or forcing a reset.
///
/// This is 2D estimation from a single camera view, not biomechanics —
/// no implementation may claim to measure a joint angle exactly, only to
/// estimate exercise phase and rep count from it. Any [FormObservation]
/// an analyzer emits must stay uncertainty-aware ("appears to," "may
/// be") and must never diagnose an injury, grade risk on a medical
/// scale, or claim to replace a qualified coach or spotter — see
/// `wellness-ethics-bible.md` and Scenario 17.
abstract class ExercisePoseAnalyzer {
  SupportedExercise get exercise;

  ExercisePoseAnalysisUpdate onFrame(PoseFrame frame);

  /// Clears all internal state (phase, debounce counters, depth-reached
  /// flags) back to the exercise's starting phase — used both for
  /// "Reset" and when starting a fresh session.
  void reset();
}
