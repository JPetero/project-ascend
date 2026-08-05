import '../../profile/domain/equipment_item.dart';
import '../../profile/domain/preferences_model.dart';
import '../../profile/domain/profile_model.dart';

/// The 9 onboarding pages, in order. The index doubles as the backend
/// `Profile.onboardingStep` value.
enum OnboardingPage {
  companion,
  personalDetails,
  bodyMeasurements,
  goal,
  experienceAndEquipment,
  schedule,
  wearables,
  privacySummary,
  completion,
}

/// Local, mutable onboarding form state. Persisted to Drift after every
/// change so the flow survives an app restart mid-onboarding, and flushed
/// to the backend (as partial PATCH /profile/onboarding calls) whenever
/// the user advances a page.
class OnboardingFormDraft {
  const OnboardingFormDraft({
    this.companion,
    this.firstName,
    this.dateOfBirth,
    this.countryCode,
    this.languageCode,
    this.unitSystem,
    this.sexForCalculations,
    this.heightCm,
    this.weightKg,
    this.primaryGoal,
    this.experienceLevel,
    this.equipment = const [],
    this.durationMinutes,
    this.preferredTime,
    this.daysOfWeek = const [],
  });

  final Companion? companion;
  final String? firstName;
  final DateTime? dateOfBirth;
  final String? countryCode;
  final String? languageCode;
  final UnitSystem? unitSystem;
  final SexForCalculations? sexForCalculations;
  final double? heightCm;
  final double? weightKg;
  final String? primaryGoal;
  final String? experienceLevel;
  final List<EquipmentItem> equipment;
  final int? durationMinutes;
  final String? preferredTime;
  final List<String> daysOfWeek;

  factory OnboardingFormDraft.fromProfile(
    ProfileModel? profile,
    Companion? companion,
  ) {
    if (profile == null) return OnboardingFormDraft(companion: companion);
    return OnboardingFormDraft(
      companion: companion,
      firstName: profile.firstName,
      dateOfBirth: profile.dateOfBirth,
      countryCode: profile.countryCode,
      languageCode: profile.languageCode,
      unitSystem: profile.unitSystem,
      sexForCalculations: profile.sexForCalculations,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      primaryGoal: profile.primaryGoal,
      experienceLevel: profile.experienceLevel,
      equipment: profile.equipment,
      durationMinutes: profile.workoutSchedule?.durationMinutes,
      preferredTime: profile.workoutSchedule?.preferredTime,
      daysOfWeek: profile.workoutSchedule?.daysOfWeek ?? const [],
    );
  }

  factory OnboardingFormDraft.fromJson(Map<String, dynamic> json) {
    return OnboardingFormDraft(
      companion: json['companion'] == null
          ? null
          : companionFromJson(json['companion'] as String),
      firstName: json['firstName'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      countryCode: json['countryCode'] as String?,
      languageCode: json['languageCode'] as String?,
      unitSystem: json['unitSystem'] == null
          ? null
          : unitSystemFromJson(json['unitSystem'] as String),
      sexForCalculations: json['sexForCalculations'] == null
          ? null
          : sexForCalculationsFromJson(json['sexForCalculations'] as String),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      primaryGoal: json['primaryGoal'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      equipment: (json['equipment'] as List<dynamic>? ?? [])
          .map((e) => EquipmentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      durationMinutes: json['durationMinutes'] as int?,
      preferredTime: json['preferredTime'] as String?,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  /// Full local snapshot (including [companion], which lives on
  /// `Preference`, not `Profile`) — used only for the Drift resilience
  /// cache, never sent directly to the backend.
  Map<String, dynamic> toJson() => {
    if (companion != null) 'companion': companion!.name.toUpperCase(),
    if (firstName != null) 'firstName': firstName,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    if (countryCode != null) 'countryCode': countryCode,
    if (languageCode != null) 'languageCode': languageCode,
    if (unitSystem != null) 'unitSystem': unitSystem!.name.toUpperCase(),
    if (sexForCalculations != null)
      'sexForCalculations': sexForCalculations!.name.toUpperCase(),
    if (heightCm != null) 'heightCm': heightCm,
    if (weightKg != null) 'weightKg': weightKg,
    if (primaryGoal != null) 'primaryGoal': primaryGoal,
    if (experienceLevel != null) 'experienceLevel': experienceLevel,
    'equipment': equipment.map((e) => e.toJson()).toList(),
    if (durationMinutes != null) 'durationMinutes': durationMinutes,
    if (preferredTime != null) 'preferredTime': preferredTime,
    'daysOfWeek': daysOfWeek,
  };

  /// The exact shape `PATCH /profile/onboarding` accepts. Deliberately
  /// excludes [companion] (that's a `Preference`, saved separately) and
  /// only nests `workoutSchedule` once a duration has actually been
  /// chosen, since the backend's `WorkoutScheduleDto.durationMinutes` is
  /// required whenever the key is present at all.
  Map<String, dynamic> toOnboardingPatch({
    required int onboardingStep,
    bool onboardingCompleted = false,
  }) {
    return {
      'onboardingStep': onboardingStep,
      if (onboardingCompleted) 'onboardingCompleted': true,
      if (firstName != null) 'firstName': firstName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (countryCode != null) 'countryCode': countryCode,
      if (languageCode != null) 'languageCode': languageCode,
      if (unitSystem != null) 'unitSystem': unitSystem!.name.toUpperCase(),
      if (sexForCalculations != null)
        'sexForCalculations': sexForCalculations!.name.toUpperCase(),
      if (heightCm != null) 'heightCm': heightCm,
      if (weightKg != null) 'weightKg': weightKg,
      if (primaryGoal != null) 'primaryGoal': primaryGoal,
      if (experienceLevel != null) 'experienceLevel': experienceLevel,
      'equipment': equipment.map((e) => e.toJson()).toList(),
      if (durationMinutes != null)
        'workoutSchedule': {
          'durationMinutes': durationMinutes,
          if (preferredTime != null) 'preferredTime': preferredTime,
          'daysOfWeek': daysOfWeek,
        },
    };
  }

  OnboardingFormDraft copyWith({
    Companion? companion,
    String? firstName,
    DateTime? dateOfBirth,
    String? countryCode,
    String? languageCode,
    UnitSystem? unitSystem,
    SexForCalculations? sexForCalculations,
    double? heightCm,
    double? weightKg,
    String? primaryGoal,
    String? experienceLevel,
    List<EquipmentItem>? equipment,
    int? durationMinutes,
    String? preferredTime,
    List<String>? daysOfWeek,
  }) {
    return OnboardingFormDraft(
      companion: companion ?? this.companion,
      firstName: firstName ?? this.firstName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      countryCode: countryCode ?? this.countryCode,
      languageCode: languageCode ?? this.languageCode,
      unitSystem: unitSystem ?? this.unitSystem,
      sexForCalculations: sexForCalculations ?? this.sexForCalculations,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      equipment: equipment ?? this.equipment,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      preferredTime: preferredTime ?? this.preferredTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }
}
