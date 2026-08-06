/// Shared, dependency-free progress calculations — the Flutter-side
/// counterpart to `services/api/src/common/progress/progress.util.ts`.
/// Kept as plain functions over primitives so any domain (workout today,
/// nutrition later) can reuse the exact same definitions rather than each
/// screen inventing its own percentage math. See
/// packages/docs/product/user-scenario-bible.md Scenario 9 for the
/// specific percentage definitions this backs.
library;

/// Rounded to one decimal place, clamped to [0, 100] — mirrors the backend
/// helper so a percentage never renders past full or negative even if
/// `completed` exceeds `target`.
double calculateCompletionPercentage(num completed, num target) {
  if (target <= 0) return 0;
  final percentage = (completed / target) * 100;
  final clamped = percentage.clamp(0, 100);
  return (clamped * 10).round() / 10;
}
