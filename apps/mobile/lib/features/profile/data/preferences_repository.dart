import '../../../core/networking/api_client.dart';
import '../../../core/storage/app_database.dart';
import '../domain/preferences_model.dart';

class PreferencesRepository {
  PreferencesRepository({
    required ApiClient apiClient,
    required AppDatabase database,
  }) : _apiClient = apiClient,
       _database = database;

  final ApiClient _apiClient;
  final AppDatabase _database;

  Future<PreferencesModel> fetchPreferences(String userId) async {
    try {
      final envelope = await _apiClient.get(
        '/preferences',
        (data) => data as Map<String, dynamic>,
      );
      final json = envelope.data!;
      await _database.cachePreferences(userId, json);
      return PreferencesModel.fromJson(json);
    } catch (error) {
      final cached = await _database.readCachedPreferences(userId);
      if (cached != null) {
        return PreferencesModel.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<PreferencesModel> updatePreferences(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    final envelope = await _apiClient.patch(
      '/preferences',
      (data) => data as Map<String, dynamic>,
      data: patch,
    );
    final json = envelope.data!;
    await _database.cachePreferences(userId, json);
    return PreferencesModel.fromJson(json);
  }
}
