class LastPerformance {
  const LastPerformance({
    required this.performedAt,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
  });

  final DateTime performedAt;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;

  factory LastPerformance.fromJson(Map<String, dynamic> json) {
    return LastPerformance(
      performedAt: DateTime.parse(json['performedAt'] as String),
      reps: json['reps'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durationSeconds: json['durationSeconds'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }
}

class SuggestedSet {
  const SuggestedSet({
    required this.rationale,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
  });

  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final String rationale;

  factory SuggestedSet.fromJson(Map<String, dynamic> json) {
    return SuggestedSet(
      reps: json['reps'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durationSeconds: json['durationSeconds'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      rationale: json['rationale'] as String,
    );
  }
}

/// A deterministic progressive-overload suggestion based on the user's own
/// last completed performance of an exercise — not an AI recommendation.
class ProgressionSuggestion {
  const ProgressionSuggestion({
    required this.hasPreviousPerformance,
    this.lastPerformance,
    this.suggestion,
  });

  final bool hasPreviousPerformance;
  final LastPerformance? lastPerformance;
  final SuggestedSet? suggestion;

  factory ProgressionSuggestion.fromJson(Map<String, dynamic> json) {
    return ProgressionSuggestion(
      hasPreviousPerformance: json['hasPreviousPerformance'] as bool,
      lastPerformance: json['lastPerformance'] == null
          ? null
          : LastPerformance.fromJson(
              json['lastPerformance'] as Map<String, dynamic>,
            ),
      suggestion: json['suggestion'] == null
          ? null
          : SuggestedSet.fromJson(json['suggestion'] as Map<String, dynamic>),
    );
  }
}
