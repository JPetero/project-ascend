enum AchievementCategory { workout, nutrition, consistency, cardio, recovery }

AchievementCategory achievementCategoryFromJson(String value) =>
    AchievementCategory.values.firstWhere(
      (c) => c.name.toUpperCase() == value,
      orElse: () => AchievementCategory.workout,
    );

String achievementCategoryLabel(AchievementCategory category) =>
    switch (category) {
      AchievementCategory.workout => 'Workout',
      AchievementCategory.nutrition => 'Nutrition',
      AchievementCategory.consistency => 'Consistency',
      AchievementCategory.cardio => 'Cardio',
      AchievementCategory.recovery => 'Recovery',
    };

/// The full catalog merged with the current user's progress — see
/// services/api/src/modules/achievements/achievements.service.ts's
/// `listForUser`. `progress`/`earnedAt` are always present (0/null for an
/// achievement never triggered yet) so every achievement, locked or not,
/// renders from one list with no separate "what exists" call.
class Achievement {
  const Achievement({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.category,
    required this.targetSteps,
    required this.progress,
    required this.earnedAt,
  });

  final String id;
  final String key;
  final String title;
  final String description;
  final String iconAsset;
  final AchievementCategory category;
  final int targetSteps;
  final int progress;
  final DateTime? earnedAt;

  bool get isEarned => earnedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      key: json['key'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconAsset: json['iconAsset'] as String,
      category: achievementCategoryFromJson(json['category'] as String),
      targetSteps: json['targetSteps'] as int,
      progress: json['progress'] as int,
      earnedAt: json['earnedAt'] == null
          ? null
          : DateTime.parse(json['earnedAt'] as String),
    );
  }
}
