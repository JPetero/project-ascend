import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_validation.dart';
import 'core/config/configuration_error_app.dart';
import 'core/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // S14 Part 2 — checked before anything else touches the network or
  // persistent storage: a staging/prod build pointed at an unsafe or
  // missing API host must never quietly start talking to it.
  final configValidation = AppConfigValidation.validate(
    environment: AppConfig.environment,
    apiBaseUrl: AppConfig.apiBaseUrl,
  );
  if (!configValidation.isValid) {
    runApp(ConfigurationErrorApp(violations: configValidation.violations));
    return;
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AscendApp(),
    ),
  );
}
