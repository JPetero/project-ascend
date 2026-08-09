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

/// Inverse of [_categoryFromJson] — needed only by
/// `POST /assistant/memory/confirm` (Build Session 12 Part 4), which
/// re-sends the exact category the server offered rather than an id.
String categoryToJson(CompanionMemoryCategory category) {
  switch (category) {
    case CompanionMemoryCategory.workoutPreference:
      return 'WORKOUT_PREFERENCE';
    case CompanionMemoryCategory.equipment:
      return 'EQUIPMENT';
    case CompanionMemoryCategory.schedulePreference:
      return 'SCHEDULE_PREFERENCE';
    case CompanionMemoryCategory.foodPreference:
      return 'FOOD_PREFERENCE';
    case CompanionMemoryCategory.dietaryRestriction:
      return 'DIETARY_RESTRICTION';
    case CompanionMemoryCategory.goal:
      return 'GOAL';
    case CompanionMemoryCategory.coachingStyle:
      return 'COACHING_STYLE';
    case CompanionMemoryCategory.companionPreference:
      return 'COMPANION_PREFERENCE';
    case CompanionMemoryCategory.unitPreference:
      return 'UNIT_PREFERENCE';
    case CompanionMemoryCategory.accessibilityPreference:
      return 'ACCESSIBILITY_PREFERENCE';
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

/// A SENSITIVE-category fact (Build Session 12 Part 4) the assistant
/// noticed but did not auto-save — surfaced by `POST /assistant/reply`'s
/// `pendingMemory` field so the client can show a non-blocking "remember
/// this?" prompt before `CompanionMemoryRepository.confirmPendingMemory`
/// actually persists it. Unlike [CompanionMemoryNote] this never has an
/// id — nothing exists server-side for it yet.
class PendingCompanionMemory {
  const PendingCompanionMemory({required this.category, required this.value});

  factory PendingCompanionMemory.fromJson(Map<String, dynamic> json) {
    return PendingCompanionMemory(
      category: _categoryFromJson(json['category'] as String),
      value: json['value'] as String,
    );
  }

  final CompanionMemoryCategory category;
  final String value;

  /// Same category+value pair are equal — used to recognize "the user
  /// already said not now to this exact fact" so it isn't re-prompted
  /// within the same chat session.
  String get dedupeKey => '${categoryToJson(category)}|$value';

  @override
  bool operator ==(Object other) =>
      other is PendingCompanionMemory && other.dedupeKey == dedupeKey;

  @override
  int get hashCode => dedupeKey.hashCode;
}
