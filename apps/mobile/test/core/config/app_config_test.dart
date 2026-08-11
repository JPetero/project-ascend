import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';

void main() {
  group('AppConfig.environment', () {
    // ENVIRONMENT is a compile-time --dart-define, so this test binary
    // (built without one) always resolves the same branch this test
    // asserts — the dev/staging/prod ternary itself is exercised
    // directly in environment_banner_test.dart via
    // `environmentBannerLabel`, which takes an AppEnvironment value
    // rather than re-reading the dart-define.
    test('defaults to dev when ENVIRONMENT is not set at build time', () {
      expect(AppConfig.environment, AppEnvironment.dev);
    });

    test('has exactly one value per Android product flavor', () {
      expect(AppEnvironment.values, [
        AppEnvironment.dev,
        AppEnvironment.staging,
        AppEnvironment.prod,
      ]);
    });
  });

  group('AppConfig.apiBaseUrl', () {
    test(
      'defaults to the Android emulator localhost alias, never a fabricated staging/prod host',
      () {
        expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:3000');
      },
    );
  });
}
