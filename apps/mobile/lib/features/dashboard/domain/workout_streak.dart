/// Computes the user's current workout streak: the number of consecutive
/// calendar days (most recent first) that include at least one completed
/// workout session.
///
/// "Current" means the streak is still allowed to be alive today even if
/// today doesn't have a completed workout yet — a user who worked out
/// yesterday and hasn't yet today shouldn't see their streak reset to 0
/// before the day is even over. If neither today nor yesterday has a
/// completed workout, the streak is 0.
int computeWorkoutStreak(List<DateTime> completedAtDates, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final days = completedAtDates.map(_dateOnly).toSet();

  var cursor = today;
  if (!days.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
