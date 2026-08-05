import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

/// The production [TokenStore], backed by the platform keychain/keystore.
class SecureTokenStore implements TokenStore {
  SecureTokenStore()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
