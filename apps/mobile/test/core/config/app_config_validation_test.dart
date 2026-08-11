import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/config/app_config_validation.dart';

void main() {
  group('AppConfigValidation.validate', () {
    test('dev + the emulator alias is accepted', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.dev,
        apiBaseUrl: 'http://10.0.2.2:3000',
      );

      expect(result.isValid, isTrue);
    });

    test('dev accepts even an empty API URL — nothing to guess wrong', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.dev,
        apiBaseUrl: '',
      );

      expect(result.isValid, isTrue);
    });

    test('staging + a missing API URL is rejected', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.staging,
        apiBaseUrl: '',
      );

      expect(result.isValid, isFalse);
      expect(result.violations, isNotEmpty);
    });

    test('prod + a missing API URL is rejected', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.prod,
        apiBaseUrl: '',
      );

      expect(result.isValid, isFalse);
      expect(result.violations.single, contains('API_BASE_URL is not set'));
    });

    test('prod + the emulator alias is rejected', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'https://10.0.2.2:3000',
      );

      expect(result.isValid, isFalse);
      expect(result.violations.join(), contains('10.0.2.2'));
    });

    test('prod + localhost is rejected', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'https://localhost:3000',
      );

      expect(result.isValid, isFalse);
    });

    test('prod + 127.0.0.1 is rejected', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'https://127.0.0.1:3000',
      );

      expect(result.isValid, isFalse);
    });

    test('prod + a plain http:// URL is rejected', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'http://api.projectascend.com',
      );

      expect(result.isValid, isFalse);
      expect(result.violations.join(), contains('https://'));
    });

    test('prod + a real https:// API URL is accepted', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'https://api.projectascend.com',
      );

      expect(result.isValid, isTrue);
      expect(result.violations, isEmpty);
    });

    test('staging + a real https:// API URL is accepted', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.staging,
        apiBaseUrl: 'https://staging-api.projectascend.com',
      );

      expect(result.isValid, isTrue);
    });

    test('prod + an unparseable URL is rejected with a clear reason', () {
      final result = AppConfigValidation.validate(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'not a url at all',
      );

      expect(result.isValid, isFalse);
    });

    test(
      'reports every violation at once rather than stopping at the first',
      () {
        final result = AppConfigValidation.validate(
          environment: AppEnvironment.prod,
          apiBaseUrl: 'http://10.0.2.2:3000',
        );

        expect(result.violations.length, 2);
      },
    );
  });
}
