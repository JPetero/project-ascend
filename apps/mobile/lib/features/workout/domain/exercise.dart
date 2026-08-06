enum ExerciseDifficulty { beginner, intermediate, advanced }

ExerciseDifficulty exerciseDifficultyFromJson(String value) =>
    ExerciseDifficulty.values.firstWhere(
      (e) => e.name.toUpperCase() == value,
      orElse: () => ExerciseDifficulty.beginner,
    );

String exerciseDifficultyLabel(ExerciseDifficulty difficulty) {
  switch (difficulty) {
    case ExerciseDifficulty.beginner:
      return 'Beginner';
    case ExerciseDifficulty.intermediate:
      return 'Intermediate';
    case ExerciseDifficulty.advanced:
      return 'Advanced';
  }
}

class ExerciseCategory {
  const ExerciseCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

class MuscleGroup {
  const MuscleGroup({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory MuscleGroup.fromJson(Map<String, dynamic> json) {
    return MuscleGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

class EquipmentType {
  const EquipmentType({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory EquipmentType.fromJson(Map<String, dynamic> json) {
    return EquipmentType(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

/// The trimmed shape used wherever an exercise is referenced from another
/// entity (a plan's exercise list, an alternative, a logged set) — not the
/// full library-detail payload.
class ExerciseSummary {
  const ExerciseSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.difficulty,
    this.category,
  });

  final String id;
  final String name;
  final String slug;
  final ExerciseDifficulty? difficulty;
  final ExerciseCategory? category;

  factory ExerciseSummary.fromJson(Map<String, dynamic> json) {
    return ExerciseSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      difficulty: json['difficulty'] == null
          ? null
          : exerciseDifficultyFromJson(json['difficulty'] as String),
      category: json['category'] == null
          ? null
          : ExerciseCategory.fromJson(json['category'] as Map<String, dynamic>),
    );
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.difficulty,
    required this.instructions,
    required this.safetyTips,
    required this.commonMistakes,
    required this.category,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.alternatives,
    this.imageUrl,
    this.videoUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final ExerciseDifficulty difficulty;
  final String instructions;
  final String safetyTips;
  final String commonMistakes;
  final String? imageUrl;
  final String? videoUrl;
  final ExerciseCategory category;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final List<EquipmentType> equipment;
  final List<ExerciseSummary> alternatives;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      difficulty: exerciseDifficultyFromJson(json['difficulty'] as String),
      instructions: json['instructions'] as String,
      safetyTips: json['safetyTips'] as String,
      commonMistakes: json['commonMistakes'] as String,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      category: ExerciseCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      primaryMuscles: (json['primaryMuscles'] as List<dynamic>)
          .map((m) => MuscleGroup.fromJson(m as Map<String, dynamic>))
          .toList(),
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>)
          .map((m) => MuscleGroup.fromJson(m as Map<String, dynamic>))
          .toList(),
      equipment: (json['equipment'] as List<dynamic>)
          .map((e) => EquipmentType.fromJson(e as Map<String, dynamic>))
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((a) => ExerciseSummary.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
