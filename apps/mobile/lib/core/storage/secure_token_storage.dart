import 'secure_token_store.dart';
import 'token_store.dart';

/// Persists auth tokens via a [TokenStore] (the platform keychain/keystore
/// in production). Never store tokens in shared_preferences or any other
/// unencrypted storage.
class SecureTokenStorage {
  SecureTokenStorage({TokenStore? store})
    : _store = store ?? SecureTokenStore();

  final TokenStore _store;

  static const _accessTokenKey = 'ascend.access_token';
  static const _refreshTokenKey = 'ascend.refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _store.write(_accessTokenKey, accessToken),
      _store.write(_refreshTokenKey, refreshToken),
    ]);
  }

  Future<String?> readAccessToken() => _store.read(_accessTokenKey);

  Future<String?> readRefreshToken() => _store.read(_refreshTokenKey);

  Future<void> clear() async {
    await Future.wait([
      _store.delete(_accessTokenKey),
      _store.delete(_refreshTokenKey),
    ]);
  }

  Future<bool> hasSession() async {
    final refreshToken = await readRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }
}
