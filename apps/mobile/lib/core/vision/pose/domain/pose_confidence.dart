/// A coarse, user-facing bucketing of a raw 0.0-1.0 confidence value —
/// UI shows this instead of a raw decimal, matching the "always show
/// confidence" requirement from Scenario 17's camera safety rules.
enum PoseConfidence { high, medium, low, insufficient }

PoseConfidence poseConfidenceFromValue(double value) {
  if (value >= 0.8) return PoseConfidence.high;
  if (value >= 0.5) return PoseConfidence.medium;
  if (value >= 0.3) return PoseConfidence.low;
  return PoseConfidence.insufficient;
}

String poseConfidenceLabel(PoseConfidence confidence) {
  switch (confidence) {
    case PoseConfidence.high:
      return 'Good visibility';
    case PoseConfidence.medium:
      return 'Fair visibility';
    case PoseConfidence.low:
      return 'Limited visibility';
    case PoseConfidence.insufficient:
      return "Can't see you clearly";
  }
}
