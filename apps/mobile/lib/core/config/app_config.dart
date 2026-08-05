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
}
