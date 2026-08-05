import '../../../core/storage/app_database.dart';
import '../domain/dashboard_fixture.dart';

/// Sprint 1 has no real workout/nutrition backend yet, so this repository
/// serves a deterministic development fixture and demonstrates the offline
/// cache-and-restore path a real endpoint will use later.
class DashboardRepository {
  DashboardRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<DashboardFixture> loadDashboard(String userId) async {
    final cached = await _database.readCachedDashboard(userId);
    if (cached != null) {
      return DashboardFixture.fromJson(cached);
    }

    final fixture = DashboardFixture.sample();
    await _database.cacheDashboard(userId, fixture.toJson());
    return fixture;
  }
}
