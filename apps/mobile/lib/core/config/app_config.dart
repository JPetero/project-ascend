/// Which build variant this binary is — matches the Android Gradle
/// product flavor it was built with (S13 Part 16-27; see
/// `android/app/build.gradle.kts`'s `productFlavors`). Purely a label:
/// it never selects a default API URL on its own (that stays
/// `API_BASE_URL`-driven, see [AppConfig.apiBaseUrl]'s doc comment for
/// why a real staging/prod host is never guessed at). Its only current
/// consumer is [EnvironmentBanner], so testers can tell at a glance
/// which build they're running.
enum AppEnvironment { dev, staging, prod }

/// Build-time configuration. Override at build/run time with
/// `--dart-define=API_BASE_URL=https://...`.
///
/// [apiBaseUrl] deliberately has only one real default — the Android
/// emulator's localhost alias, a value that's always genuinely correct
/// for local development. Staging/prod don't get invented
/// `staging-api.example.com`-style defaults here: unlike [environment],
/// which is safe to guess ('dev' when unset, matching every build
/// before flavors existed), silently pointing an unconfigured build at
/// a fabricated host would be the same "pretend it works" failure mode
/// [googleClientId] below is careful to avoid. A staging/prod build
/// must always pass its real API host explicitly via
/// `--dart-define=API_BASE_URL=...`.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  // Set to 'dev'/'staging'/'prod' via `--dart-define=ENVIRONMENT=...`,
  // matching the Android flavor a given build was assembled with.
  // Defaults to 'dev' — the same default every build had before this
  // existed, so omitting it changes nothing.
  static const String _environmentName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static const AppEnvironment environment = _environmentName == 'staging'
      ? AppEnvironment.staging
      : _environmentName == 'prod'
      ? AppEnvironment.prod
      : AppEnvironment.dev;

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
