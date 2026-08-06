/// The user's daily macro targets — either a safe, clearly-labelled
/// estimate (`isEstimatedDefault`) computed server-side from profile data,
/// or explicit values the user entered themselves. See
/// services/api/src/modules/macro-targets/macro-targets.service.ts for how
/// the estimate is derived and why it's bounded.
class MacroTarget {
  const MacroTarget({
    required this.calorieTarget,
    required this.proteinGramsTarget,
    required this.carbGramsTarget,
    required this.fatGramsTarget,
    this.fiberGramsTarget,
    required this.isEstimatedDefault,
    required this.disclaimer,
    required this.updatedAt,
  });

  final int calorieTarget;
  final int proteinGramsTarget;
  final int carbGramsTarget;
  final int fatGramsTarget;
  final int? fiberGramsTarget;
  final bool isEstimatedDefault;
  final String disclaimer;
  final DateTime updatedAt;

  factory MacroTarget.fromJson(Map<String, dynamic> json) {
    return MacroTarget(
      calorieTarget: json['calorieTarget'] as int,
      proteinGramsTarget: json['proteinGramsTarget'] as int,
      carbGramsTarget: json['carbGramsTarget'] as int,
      fatGramsTarget: json['fatGramsTarget'] as int,
      fiberGramsTarget: json['fiberGramsTarget'] as int?,
      isEstimatedDefault: json['isEstimatedDefault'] as bool,
      disclaimer: json['disclaimer'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
