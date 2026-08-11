/// The outcome of one genuine, one-shot round trip through the real
/// camera and on-device pose detector (S14 Part 19) — distinct from a
/// live session's ongoing rep-counting: this only ever checks "does the
/// camera open and does the pose engine actually run on this device,"
/// which a `qa/vision-physical-device-checklist.md` tester or a bug
/// report needs to know before troubleshooting anything else.
class PoseEngineSelfTestResult {
  const PoseEngineSelfTestResult({
    required this.succeeded,
    required this.message,
    this.elapsed,
  });

  final bool succeeded;

  /// Always human-readable and actionable — never a raw stack trace, even
  /// on failure, though it may include the underlying error's `toString`.
  final String message;

  /// Wall-clock time from starting the camera to getting a detector
  /// result — a rough on-device latency signal for row 17/18 of the
  /// physical-device checklist ("frame throttling keeps the UI
  /// responsive" / thermal behavior), not a precise per-frame benchmark.
  final Duration? elapsed;
}
