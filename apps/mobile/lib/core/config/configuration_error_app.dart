import 'package:flutter/material.dart';

/// S14 Part 2 — shown instead of the real app when
/// [AppConfigValidation] rejects the running build's environment/API
/// URL combination. Deliberately a standalone `MaterialApp`, not routed
/// through [AscendApp]: the real app's providers (API client, storage,
/// ...) should never even construct against a configuration this
/// screen has already judged unsafe to talk to.
class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.violations});

  final List<String> violations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Configuration error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This build cannot start safely.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                for (final violation in violations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '•  $violation',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
