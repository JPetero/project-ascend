/// Sample/development dashboard data. Clearly labeled as such in the UI —
/// see [HomeDashboardScreen]'s "Sample data" badge — until real workout,
/// nutrition, and wearable-sync data sources exist.
class DashboardFixture {
  const DashboardFixture({
    required this.recoveryScore,
    required this.todayWorkoutTitle,
    required this.todayWorkoutDurationMinutes,
    required this.proteinGrams,
    required this.proteinTargetGrams,
    required this.hydrationMl,
    required this.hydrationTargetMl,
    required this.steps,
    required this.stepsTarget,
    required this.sleepHours,
    required this.streakDays,
  });

  final int recoveryScore;
  final String todayWorkoutTitle;
  final int todayWorkoutDurationMinutes;
  final int proteinGrams;
  final int proteinTargetGrams;
  final int hydrationMl;
  final int hydrationTargetMl;
  final int steps;
  final int stepsTarget;
  final double sleepHours;
  final int streakDays;

  factory DashboardFixture.sample() => const DashboardFixture(
    recoveryScore: 78,
    todayWorkoutTitle: 'Full Body Strength',
    todayWorkoutDurationMinutes: 35,
    proteinGrams: 62,
    proteinTargetGrams: 130,
    hydrationMl: 900,
    hydrationTargetMl: 2500,
    steps: 4210,
    stepsTarget: 8000,
    sleepHours: 6.8,
    streakDays: 4,
  );

  factory DashboardFixture.fromJson(Map<String, dynamic> json) {
    return DashboardFixture(
      recoveryScore: json['recoveryScore'] as int,
      todayWorkoutTitle: json['todayWorkoutTitle'] as String,
      todayWorkoutDurationMinutes: json['todayWorkoutDurationMinutes'] as int,
      proteinGrams: json['proteinGrams'] as int,
      proteinTargetGrams: json['proteinTargetGrams'] as int,
      hydrationMl: json['hydrationMl'] as int,
      hydrationTargetMl: json['hydrationTargetMl'] as int,
      steps: json['steps'] as int,
      stepsTarget: json['stepsTarget'] as int,
      sleepHours: (json['sleepHours'] as num).toDouble(),
      streakDays: json['streakDays'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'recoveryScore': recoveryScore,
    'todayWorkoutTitle': todayWorkoutTitle,
    'todayWorkoutDurationMinutes': todayWorkoutDurationMinutes,
    'proteinGrams': proteinGrams,
    'proteinTargetGrams': proteinTargetGrams,
    'hydrationMl': hydrationMl,
    'hydrationTargetMl': hydrationTargetMl,
    'steps': steps,
    'stepsTarget': stepsTarget,
    'sleepHours': sleepHours,
    'streakDays': streakDays,
  };
}
