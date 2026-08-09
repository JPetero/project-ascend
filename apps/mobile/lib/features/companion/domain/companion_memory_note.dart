/// One of `CompanionMemoryCategory`'s ten allowed categories
/// (services/api/prisma/schema.prisma) — never a free-form "other"
/// bucket, matching the server-side extractor's category allowlist
/// (Build Session 11 Part 4).
enum CompanionMemoryCategory {
  workoutPreference,
  equipment,
  schedulePreference,
  foodPreference,
  dietaryRestriction,
  goal,
  coachingStyle,
  companionPreference,
  unitPreference,
  accessibilityPreference,
}

CompanionMemoryCategory _categoryFromJson(String raw) {
  switch (raw) {
    case 'WORKOUT_PREFERENCE':
      return CompanionMemoryCategory.workoutPreference;
    case 'EQUIPMENT':
      return CompanionMemoryCategory.equipment;
    case 'SCHEDULE_PREFERENCE':
      return CompanionMemoryCategory.schedulePreference;
    case 'FOOD_PREFERENCE':
      return CompanionMemoryCategory.foodPreference;
    case 'DIETARY_RESTRICTION':
      return CompanionMemoryCategory.dietaryRestriction;
    case 'GOAL':
      return CompanionMemoryCategory.goal;
    case 'COACHING_STYLE':
      return CompanionMemoryCategory.coachingStyle;
    case 'COMPANION_PREFERENCE':
      return CompanionMemoryCategory.companionPreference;
    case 'UNIT_PREFERENCE':
      return CompanionMemoryCategory.unitPreference;
    case 'ACCESSIBILITY_PREFERENCE':
      return CompanionMemoryCategory.accessibilityPreference;
    default:
      return CompanionMemoryCategory.goal;
  }
}

/// Short, human-readable label for [CompanionMemoryScreen] — never the
/// raw enum name.
extension CompanionMemoryCategoryLabel on CompanionMemoryCategory {
  String get label {
    switch (this) {
      case CompanionMemoryCategory.workoutPreference:
        return 'Workout preference';
      case CompanionMemoryCategory.equipment:
        return 'Equipment';
      case CompanionMemoryCategory.schedulePreference:
        return 'Schedule preference';
      case CompanionMemoryCategory.foodPreference:
        return 'Food preference';
      case CompanionMemoryCategory.dietaryRestriction:
        return 'Dietary restriction';
      case CompanionMemoryCategory.goal:
        return 'Goal';
      case CompanionMemoryCategory.coachingStyle:
        return 'Coaching style';
      case CompanionMemoryCategory.companionPreference:
        return 'Companion preference';
      case CompanionMemoryCategory.unitPreference:
        return 'Unit preference';
      case CompanionMemoryCategory.accessibilityPreference:
        return 'Accessibility preference';
    }
  }
}

/// One structured fact Atlas/Nova remembers (Build Session 11 Part 4) —
/// replaces the original raw-sentence `notes: List<String>` shape.
/// [value] is still the user's own words / a direct restatement of them,
/// never an invented summary — only [category] is new structure on top.
class CompanionMemoryNote {
  const CompanionMemoryNote({
    required this.id,
    required this.category,
    required this.value,
    required this.createdAt,
  });

  factory CompanionMemoryNote.fromJson(Map<String, dynamic> json) {
    return CompanionMemoryNote(
      id: json['id'] as String,
      category: _categoryFromJson(json['category'] as String),
      value: json['value'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final CompanionMemoryCategory category;
  final String value;
  final DateTime createdAt;
}
