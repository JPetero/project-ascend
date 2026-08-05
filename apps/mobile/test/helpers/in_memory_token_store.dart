import 'package:mobile/core/storage/token_store.dart';

/// A [TokenStore] test double that never touches a platform channel.
class InMemoryTokenStore implements TokenStore {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
