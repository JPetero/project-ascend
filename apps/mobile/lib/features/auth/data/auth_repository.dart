import '../../../core/networking/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/auth_user.dart';
import '../domain/token_pair.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  Future<AuthUser> register({
    required String firstName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async {
    final envelope = await _apiClient.post(
      '/auth/register',
      (data) => data as Map<String, dynamic>,
      data: {
        'firstName': firstName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'acceptedTerms': acceptedTerms,
      },
    );

    return _persistSessionAndReturnUser(envelope.data!);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final envelope = await _apiClient.post(
      '/auth/login',
      (data) => data as Map<String, dynamic>,
      data: {'email': email, 'password': password},
    );

    return _persistSessionAndReturnUser(envelope.data!);
  }

  Future<AuthUser> me() async {
    final envelope = await _apiClient.get(
      '/auth/me',
      (data) => data as Map<String, dynamic>,
    );
    return AuthUser.fromJson(envelope.data!);
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _apiClient.post(
          '/auth/logout',
          (data) => data,
          data: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // Logout is best-effort server-side; the local session is always cleared.
      }
    }
    await _tokenStorage.clear();
  }

  Future<AuthUser> _persistSessionAndReturnUser(
    Map<String, dynamic> payload,
  ) async {
    final tokens = TokenPair.fromJson(
      payload['tokens'] as Map<String, dynamic>,
    );
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return AuthUser.fromJson(payload['user'] as Map<String, dynamic>);
  }
}
