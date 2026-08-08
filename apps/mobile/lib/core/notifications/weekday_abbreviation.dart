/// Maps `WorkoutSchedule.daysOfWeek`'s 3-letter abbreviations (the same
/// `'MON'..'SUN'` set `OnboardingSchedulePage` writes) to
/// `DateTime.monday..DateTime.sunday` (1..7), for local-notification
/// scheduling. Unknown abbreviations are dropped rather than thrown —
/// scheduling with a partial, honest set of days beats crashing.
const _weekdaysByAbbreviation = {
  'MON': DateTime.monday,
  'TUE': DateTime.tuesday,
  'WED': DateTime.wednesday,
  'THU': DateTime.thursday,
  'FRI': DateTime.friday,
  'SAT': DateTime.saturday,
  'SUN': DateTime.sunday,
};

Set<int> weekdaysFromAbbreviations(List<String> abbreviations) {
  return abbreviations
      .map((abbreviation) => _weekdaysByAbbreviation[abbreviation])
      .whereType<int>()
      .toSet();
}
