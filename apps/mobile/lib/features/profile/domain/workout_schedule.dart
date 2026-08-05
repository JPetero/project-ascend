class WorkoutSchedule {
  const WorkoutSchedule({
    required this.durationMinutes,
    this.preferredTime,
    this.daysOfWeek = const [],
  });

  final int durationMinutes;
  final String? preferredTime;
  final List<String> daysOfWeek;

  factory WorkoutSchedule.fromJson(Map<String, dynamic> json) {
    return WorkoutSchedule(
      durationMinutes: json['durationMinutes'] as int,
      preferredTime: json['preferredTime'] as String?,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'durationMinutes': durationMinutes,
    if (preferredTime != null) 'preferredTime': preferredTime,
    'daysOfWeek': daysOfWeek,
  };
}
