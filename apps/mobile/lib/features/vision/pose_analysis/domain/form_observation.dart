/// How urgently a [FormObservation] should be presented — deliberately
/// not a medical severity scale (see `wellness-ethics-bible.md` and
/// Scenario 17: never diagnose an injury from an image, never claim
/// medical-grade accuracy). `checkForm` is the ceiling; nothing above it
/// exists in this feature.
enum FormObservationSeverity { info, coachingCue, checkForm }

/// One uncertainty-aware observation about a single rep, produced by an
/// `ExercisePoseAnalyzer`. Never a diagnosis, never a claim about injury
/// risk — see the analyzer base class's doc comment for the required
/// phrasing register. The presentation layer renders this as a "form
/// cue" banner (see `FormCueBanner`); this class is the data, that
/// widget is the display.
class FormObservation {
  const FormObservation({
    required this.type,
    required this.message,
    required this.confidence,
    required this.severity,
    required this.timestamp,
  });

  /// A short machine-stable identifier for this observation kind (e.g.
  /// `'squat_depth'`, `'knee_tracking'`) — stable across app versions so
  /// saved `VisionFormObservation` rows remain meaningful after the
  /// wording changes.
  final String type;

  final String message;

  /// 0.0-1.0 — how confident the analyzer is in this specific
  /// observation, independent of the frame's overall pose-detection
  /// confidence.
  final double confidence;

  final FormObservationSeverity severity;

  final DateTime timestamp;
}
