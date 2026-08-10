enum TrainerVerificationDecision { pending, approved, rejected }

TrainerVerificationDecision trainerVerificationDecisionFromJson(String value) =>
    TrainerVerificationDecision.values.firstWhere(
      (s) => s.name.toUpperCase() == value,
      orElse: () => TrainerVerificationDecision.pending,
    );

/// A member's own trainer-verification application status (Build
/// Session 12 Part 25-26) — distinct from `CommunityProfile.isTrainer`
/// (self-declared, no review) and from `CommunityProfile.verifiedTrainer`
/// (the public-facing result once an admin approves this application).
class TrainerVerificationApplicationStatus {
  const TrainerVerificationApplicationStatus({
    required this.status,
    required this.submittedAt,
  });

  final TrainerVerificationDecision status;
  final DateTime submittedAt;

  factory TrainerVerificationApplicationStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    return TrainerVerificationApplicationStatus(
      status: trainerVerificationDecisionFromJson(json['status'] as String),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }
}
