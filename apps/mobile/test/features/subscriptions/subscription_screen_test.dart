import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/purchases/data/purchase_service.dart';
import 'package:mobile/features/purchases/domain/store_product.dart';
import 'package:mobile/features/subscriptions/domain/subscription_status.dart';
import 'package:mobile/features/subscriptions/presentation/screens/subscription_screen.dart';

import '../../helpers/fake_feature_flags_repository.dart';
import '../../helpers/fake_purchase_service.dart';
import '../../helpers/fake_purchases_repository.dart';
import '../../helpers/fake_subscriptions_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

/// STORE_PURCHASES defaults closed (Build Session 13 Part 1) — every
/// test below that exercises the real purchase flow opts in explicitly,
/// same as production requires an admin to.
FakeFeatureFlagsRepository _purchasesEnabled() =>
    FakeFeatureFlagsRepository(flags: const {'STORE_PURCHASES': true});

const _standardProduct = StoreProduct(
  id: PurchaseProductIds.premiumStandard,
  title: 'Ascend Premium (Monthly)',
  description: 'Full Premium access.',
  price: '\$12.99',
);

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

  testWidgets(
    'honestly explains when in-app purchases are unavailable rather than faking an Upgrade flow',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        purchaseService: FakePurchaseService(available: false),
        featureFlagsRepository: _purchasesEnabled(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SubscriptionScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(
        find.text("In-app purchases aren't available on this device or build."),
        findsOneWidget,
      );
      expect(find.text('Upgrade to Premium'), findsNothing);
    },
  );

  testWidgets(
    'shows the real store price and lets the caller start a purchase',
    (tester) async {
      final purchaseService = FakePurchaseService(
        available: true,
        products: const [_standardProduct],
      );
      final container = await createTestContainer(
        signedIn: true,
        purchaseService: purchaseService,
        featureFlagsRepository: _purchasesEnabled(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SubscriptionScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Ascend Premium (Monthly)'), findsOneWidget);
      expect(find.text('\$12.99'), findsOneWidget);

      await tester.tap(find.text('Upgrade to Premium'));
      await pumpForAsyncSettle(tester);

      expect(purchaseService.buyCallCount, 1);
    },
  );

  testWidgets('refreshes the caller onto Premium once a purchase verifies', (
    tester,
  ) async {
    final purchaseService = FakePurchaseService(
      available: true,
      products: const [_standardProduct],
    );
    final subscriptionsRepository = FakeSubscriptionsRepository();
    final container = await createTestContainer(
      signedIn: true,
      purchaseService: purchaseService,
      purchasesRepository: FakePurchasesRepository(),
      subscriptionsRepository: subscriptionsRepository,
      featureFlagsRepository: _purchasesEnabled(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SubscriptionScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    subscriptionsRepository.status = const SubscriptionStatus(
      tier: PlanTier.premium,
    );
    purchaseService.emit(
      const PurchaseUpdate(
        productId: PurchaseProductIds.premiumStandard,
        status: PurchaseUpdateStatus.purchased,
        receiptData: 'receipt-blob',
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Premium plan'), findsOneWidget);
    expect(find.text('Upgrade to Premium'), findsNothing);
  });

  testWidgets('shows the store-stated renewal date for a Premium plan set to '
      'auto-renew (Build Session 10 Part 26)', (tester) async {
    final repository = FakeSubscriptionsRepository(
      status: SubscriptionStatus(
        tier: PlanTier.premium,
        expiresAt: DateTime.utc(2026, 9, 9),
        willRenew: true,
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

    expect(find.textContaining('Renews'), findsOneWidget);
    expect(find.textContaining('Expires'), findsNothing);
  });

  testWidgets(
    'honestly shows an expiring, non-renewing Premium plan instead of a '
    'static badge',
    (tester) async {
      final repository = FakeSubscriptionsRepository(
        status: SubscriptionStatus(
          tier: PlanTier.premium,
          expiresAt: DateTime.utc(2026, 9, 9),
          willRenew: false,
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

      expect(find.textContaining('Expires'), findsOneWidget);
      expect(find.textContaining('auto-renew is off'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a neutral period-end date when willRenew is unknown, without '
    'guessing either way',
    (tester) async {
      final repository = FakeSubscriptionsRepository(
        status: SubscriptionStatus(
          tier: PlanTier.premium,
          expiresAt: DateTime.utc(2026, 9, 9),
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

      expect(find.textContaining('Current period ends'), findsOneWidget);
    },
  );

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
