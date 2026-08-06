import 'package:mobile/features/achievements/data/achievement_repository.dart';
import 'package:mobile/features/achievements/domain/achievement.dart';

const sampleAchievement = Achievement(
  id: 'achievement-1',
  key: 'first_workout',
  title: 'First Steps',
  description: 'Complete your first workout.',
  iconAsset: 'fitness_center',
  category: AchievementCategory.workout,
  targetSteps: 1,
  progress: 0,
  earnedAt: null,
);

/// In-memory stand-in for the achievement catalog + progress list.
class FakeAchievementRepository implements AchievementRepository {
  FakeAchievementRepository({List<Achievement>? achievements})
    : _achievements = achievements ?? [sampleAchievement];

  final List<Achievement> _achievements;

  @override
  Future<List<Achievement>> list() async => List.unmodifiable(_achievements);
}
