import 'app_config.dart';

/// The outcome of validating [AppConfig]'s environment/API URL pair —
/// S14 Part 2. `dev` is always valid (10.0.2.2 is a genuinely correct
/// default there, see [AppConfig.apiBaseUrl]'s doc comment); `staging`
/// and `prod` must be given a real, explicit HTTPS backend host, never
/// a local-development address a build happened to inherit by omission.
class AppConfigValidationResult {
  const AppConfigValidationResult({
    required this.isValid,
    this.violations = const [],
  });

  final bool isValid;
  final List<String> violations;
}

abstract final class AppConfigValidation {
  /// Hosts that are only ever correct for a developer's own machine or
  /// the Android emulator — never a real backend, so never acceptable
  /// once a build claims to be `staging`/`prod`.
  static const Set<String> unsafeHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  static AppConfigValidationResult validate({
    required AppEnvironment environment,
    required String apiBaseUrl,
  }) {
    if (environment == AppEnvironment.dev) {
      return const AppConfigValidationResult(isValid: true);
    }

    final environmentName = environment.name;

    if (apiBaseUrl.trim().isEmpty) {
      return AppConfigValidationResult(
        isValid: false,
        violations: [
          'API_BASE_URL is not set. A $environmentName build must be given '
              'its real backend host explicitly via '
              '--dart-define=API_BASE_URL=https://... — there is no safe '
              'default to fall back to.',
        ],
      );
    }

    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.host.isEmpty) {
      return AppConfigValidationResult(
        isValid: false,
        violations: ['API_BASE_URL "$apiBaseUrl" is not a valid URL.'],
      );
    }

    final violations = <String>[];
    if (uri.scheme != 'https') {
      violations.add(
        'API_BASE_URL must use https:// in $environmentName — got '
        '"${uri.scheme.isEmpty ? '(none)' : uri.scheme}://".',
      );
    }
    if (unsafeHosts.contains(uri.host.toLowerCase())) {
      violations.add(
        'API_BASE_URL host "${uri.host}" is a local-development-only '
        'address (emulator/localhost alias) and must never be used in '
        '$environmentName.',
      );
    }

    return AppConfigValidationResult(
      isValid: violations.isEmpty,
      violations: violations,
    );
  }
}
