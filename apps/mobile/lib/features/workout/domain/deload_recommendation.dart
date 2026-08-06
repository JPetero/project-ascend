/// A deload suggestion — see packages/docs/product/user-scenario-bible.md
/// Scenario 10. Always optional, dismissible, and postponable; never an
/// auto-applied change and never a diagnosis.
class DeloadRecommendation {
  const DeloadRecommendation({
    required this.id,
    required this.reason,
    required this.suggestedAt,
    this.dismissedAt,
    this.postponedUntil,
  });

  final String id;
  final String reason;
  final DateTime suggestedAt;
  final DateTime? dismissedAt;
  final DateTime? postponedUntil;

  factory DeloadRecommendation.fromJson(Map<String, dynamic> json) {
    return DeloadRecommendation(
      id: json['id'] as String,
      reason: json['reason'] as String,
      suggestedAt: DateTime.parse(json['suggestedAt'] as String),
      dismissedAt: json['dismissedAt'] == null
          ? null
          : DateTime.parse(json['dismissedAt'] as String),
      postponedUntil: json['postponedUntil'] == null
          ? null
          : DateTime.parse(json['postponedUntil'] as String),
    );
  }
}
