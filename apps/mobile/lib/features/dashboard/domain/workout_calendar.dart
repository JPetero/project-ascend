/// Reduces a list of completion timestamps down to the distinct calendar
/// days they fall on — the shape the dashboard's month calendar needs to
/// mark "you worked out this day" without caring about time-of-day.
Set<DateTime> workoutDaysFrom(Iterable<DateTime> completedAtDates) {
  return completedAtDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
}
