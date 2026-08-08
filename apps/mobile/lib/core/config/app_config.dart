/// Build-time configuration. Override at build/run time with
/// `--dart-define=API_BASE_URL=https://...`.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  // 10.0.2.2 is the Android emulator's alias for the host machine's
  // localhost; see the "Android emulator & localhost" note in the root
  // README for iOS simulator / physical device alternatives.
  static const String _defaultApiBaseUrl = 'http://10.0.2.2:3000';

  static const bool isDevelopment =
      bool.fromEnvironment('dart.vm.product') == false;

  // Real Google sign-in (Build Session 10 Part 9) needs a real Google
  // Cloud OAuth client, which this repository does not (and cannot)
  // provision — override with `--dart-define=GOOGLE_CLIENT_ID=...` (and
  // optionally GOOGLE_SERVER_CLIENT_ID, if the backend ever needs a
  // server auth code) once one exists. Left blank, GoogleAuthProvider
  // fails honestly with a real "not configured" error instead of
  // pretending to work.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
}
