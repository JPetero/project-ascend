import 'equipment_item.dart';
import 'workout_schedule.dart';

enum SexForCalculations { male, female, unspecified }

enum UnitSystem { metric, imperial }

SexForCalculations sexForCalculationsFromJson(String value) {
  return SexForCalculations.values.firstWhere(
    (e) => e.name.toUpperCase() == value,
    orElse: () => SexForCalculations.unspecified,
  );
}

UnitSystem unitSystemFromJson(String value) {
  return UnitSystem.values.firstWhere(
    (e) => e.name.toUpperCase() == value,
    orElse: () => UnitSystem.metric,
  );
}

class ProfileModel {
  const ProfileModel({
    required this.firstName,
    this.dateOfBirth,
    this.countryCode,
    required this.languageCode,
    required this.timezone,
    required this.unitSystem,
    required this.sexForCalculations,
    this.heightCm,
    this.weightKg,
    this.primaryGoal,
    this.experienceLevel,
    required this.onboardingCompleted,
    required this.onboardingStep,
    this.equipment = const [],
    this.workoutSchedule,
  });

  final String firstName;
  final DateTime? dateOfBirth;
  final String? countryCode;
  final String languageCode;
  final String timezone;
  final UnitSystem unitSystem;
  final SexForCalculations sexForCalculations;
  final double? heightCm;
  final double? weightKg;
  final String? primaryGoal;
  final String? experienceLevel;
  final bool onboardingCompleted;
  final int onboardingStep;
  final List<EquipmentItem> equipment;
  final WorkoutSchedule? workoutSchedule;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      firstName: json['firstName'] as String,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      countryCode: json['countryCode'] as String?,
      languageCode: json['languageCode'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'UTC',
      unitSystem: unitSystemFromJson(json['unitSystem'] as String? ?? 'METRIC'),
      sexForCalculations: sexForCalculationsFromJson(
        json['sexForCalculations'] as String? ?? 'UNSPECIFIED',
      ),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      primaryGoal: json['primaryGoal'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      onboardingStep: json['onboardingStep'] as int? ?? 0,
      equipment: (json['equipment'] as List<dynamic>? ?? [])
          .map((e) => EquipmentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      workoutSchedule: json['workoutSchedule'] == null
          ? null
          : WorkoutSchedule.fromJson(
              json['workoutSchedule'] as Map<String, dynamic>,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    if (countryCode != null) 'countryCode': countryCode,
    'languageCode': languageCode,
    'timezone': timezone,
    'unitSystem': unitSystem.name.toUpperCase(),
    'sexForCalculations': sexForCalculations.name.toUpperCase(),
    if (heightCm != null) 'heightCm': heightCm,
    if (weightKg != null) 'weightKg': weightKg,
    if (primaryGoal != null) 'primaryGoal': primaryGoal,
    if (experienceLevel != null) 'experienceLevel': experienceLevel,
    'onboardingCompleted': onboardingCompleted,
    'onboardingStep': onboardingStep,
    'equipment': equipment.map((e) => e.toJson()).toList(),
    if (workoutSchedule != null) 'workoutSchedule': workoutSchedule!.toJson(),
  };
}
