import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('renders the signed-in user\'s first name in the greeting', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: const ProfileModel(
        firstName: 'Jordan',
        languageCode: 'en',
        timezone: 'UTC',
        unitSystem: UnitSystem.metric,
        sexForCalculations: SexForCalculations.unspecified,
        onboardingCompleted: true,
        onboardingStep: 8,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeDashboardScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.textContaining('Jordan'), findsOneWidget);
    expect(find.text("Today's Workout"), findsOneWidget);
  });
}
