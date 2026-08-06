enum PersonalRecordType {
  maxWeight,
  maxReps,
  maxDuration,
  maxDistance,
  maxVolume,
}

PersonalRecordType personalRecordTypeFromJson(String value) =>
    PersonalRecordType.values.firstWhere(
      (e) => _typeToJson(e) == value,
      orElse: () => PersonalRecordType.maxWeight,
    );

String _typeToJson(PersonalRecordType type) {
  switch (type) {
    case PersonalRecordType.maxWeight:
      return 'MAX_WEIGHT';
    case PersonalRecordType.maxReps:
      return 'MAX_REPS';
    case PersonalRecordType.maxDuration:
      return 'MAX_DURATION';
    case PersonalRecordType.maxDistance:
      return 'MAX_DISTANCE';
    case PersonalRecordType.maxVolume:
      return 'MAX_VOLUME';
  }
}

String personalRecordTypeLabel(PersonalRecordType type) {
  switch (type) {
    case PersonalRecordType.maxWeight:
      return 'Heaviest weight';
    case PersonalRecordType.maxReps:
      return 'Most reps';
    case PersonalRecordType.maxDuration:
      return 'Longest duration';
    case PersonalRecordType.maxDistance:
      return 'Longest distance';
    case PersonalRecordType.maxVolume:
      return 'Highest volume';
  }
}

class PersonalRecordExercise {
  const PersonalRecordExercise({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory PersonalRecordExercise.fromJson(Map<String, dynamic> json) {
    return PersonalRecordExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

class PersonalRecord {
  const PersonalRecord({
    required this.id,
    required this.exercise,
    required this.type,
    required this.value,
    required this.unit,
    required this.achievedAt,
    this.previousValue,
    this.isFirstRecord = false,
  });

  final String id;
  final PersonalRecordExercise exercise;
  final PersonalRecordType type;
  final double value;
  final String unit;
  final DateTime achievedAt;
  final double? previousValue;
  final bool isFirstRecord;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'] as String,
      exercise: PersonalRecordExercise.fromJson(
        json['exercise'] as Map<String, dynamic>,
      ),
      type: personalRecordTypeFromJson(json['type'] as String),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      previousValue: (json['previousValue'] as num?)?.toDouble(),
      isFirstRecord: json['isFirstRecord'] as bool? ?? false,
    );
  }
}
