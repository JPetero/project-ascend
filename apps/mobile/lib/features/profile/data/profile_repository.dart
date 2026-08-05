import '../../../core/networking/api_client.dart';
import '../../../core/storage/app_database.dart';
import '../domain/profile_model.dart';

class ProfileRepository {
  ProfileRepository({
    required ApiClient apiClient,
    required AppDatabase database,
  }) : _apiClient = apiClient,
       _database = database;

  final ApiClient _apiClient;
  final AppDatabase _database;

  Future<ProfileModel> fetchProfile(String userId) async {
    try {
      final envelope = await _apiClient.get(
        '/profile',
        (data) => data as Map<String, dynamic>,
      );
      final json = envelope.data!;
      await _database.cacheProfile(userId, json);
      return ProfileModel.fromJson(json);
    } catch (error) {
      final cached = await _database.readCachedProfile(userId);
      if (cached != null) {
        return ProfileModel.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<ProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    final envelope = await _apiClient.patch(
      '/profile',
      (data) => data as Map<String, dynamic>,
      data: patch,
    );
    final json = envelope.data!;
    await _database.cacheProfile(userId, json);
    return ProfileModel.fromJson(json);
  }

  Future<ProfileModel> updateOnboarding(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    final envelope = await _apiClient.patch(
      '/profile/onboarding',
      (data) => data as Map<String, dynamic>,
      data: patch,
    );
    final json = envelope.data!;
    await _database.cacheProfile(userId, json);
    return ProfileModel.fromJson(json);
  }
}
