import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../networking/api_client.dart';
import '../storage/app_database.dart';
import '../storage/local_preferences.dart';
import '../storage/secure_token_storage.dart';

/// Overridden in `main.dart` with the awaited [SharedPreferences] instance
/// before the app widget tree is built.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

final localPreferencesProvider = Provider<LocalPreferences>((ref) {
  return LocalPreferences(ref.watch(sharedPreferencesProvider));
});

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

/// Bumped whenever the session is forcibly invalidated (e.g. a refresh
/// failure) so [apiClientProvider] can notify listeners without a direct
/// dependency on the auth feature.
final sessionExpiredNotifierProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  return ApiClient(
    tokenStorage: tokenStorage,
    onSessionExpired: () async {
      ref.read(sessionExpiredNotifierProvider.notifier).state++;
    },
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
