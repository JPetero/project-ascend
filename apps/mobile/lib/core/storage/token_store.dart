/// The minimal key-value contract [SecureTokenStorage] needs. Exists so
/// tests can swap in an in-memory double instead of touching the platform's
/// keychain/keystore through a method channel.
abstract class TokenStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}
