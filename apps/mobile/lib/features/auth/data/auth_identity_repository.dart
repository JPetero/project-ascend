import '../../../core/networking/api_client.dart';
import '../domain/auth_identity.dart';

class AuthIdentityRepository {
  AuthIdentityRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<AuthIdentity>> listMine() async {
    final envelope = await _apiClient.get(
      '/auth-identities/me',
      (data) => data as List<dynamic>,
    );
    return (envelope.data ?? [])
        .map((r) => AuthIdentity.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
