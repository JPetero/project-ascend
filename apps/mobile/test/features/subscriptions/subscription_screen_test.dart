import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/subscriptions/domain/subscription_status.dart';
import 'package:mobile/features/subscriptions/presentation/screens/subscription_screen.dart';

import '../../helpers/fake_subscriptions_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows the Free plan and centralized pricing', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SubscriptionScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Free plan'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('PHP'), findsOneWidget);
  });

  testWidgets('shows a pending eligibility application instead of the form', (
    tester,
  ) async {
    final repository = FakeSubscriptionsRepository(
      status: const SubscriptionStatus(
        tier: PlanTier.free,
        eligibility: EligibilityStatus(
          program: AffordabilityProgram.student,
          status: AffordabilityStatus.pending,
        ),
      ),
    );
    final container = await createTestContainer(
      signedIn: true,
      subscriptionsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SubscriptionScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.textContaining('Student Access'), findsOneWidget);
    expect(find.text('Apply'), findsNothing);
  });
}
