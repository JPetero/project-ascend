import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/subscriptions/domain/subscription_status.dart';
import 'package:mobile/features/subscriptions/presentation/providers/subscription_controller.dart';

import '../../helpers/fake_subscriptions_repository.dart';

void main() {
  test('loads status and pricing on construction', () async {
    final repository = FakeSubscriptionsRepository();
    final controller = SubscriptionController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status?.tier, PlanTier.free);
    expect(controller.state.pricing, hasLength(2));
    expect(controller.state.isLoading, isFalse);
  });

  test('applying for eligibility records a PENDING application', () async {
    final repository = FakeSubscriptionsRepository();
    final controller = SubscriptionController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.applyForEligibility(
      program: AffordabilityProgram.student,
    );

    expect(ok, isTrue);
    expect(
      controller.state.status?.eligibility?.program,
      AffordabilityProgram.student,
    );
    expect(
      controller.state.status?.eligibility?.status,
      AffordabilityStatus.pending,
    );
  });
}
