import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/purchases/data/purchase_service.dart';
import 'package:mobile/features/purchases/domain/store_product.dart';
import 'package:mobile/features/purchases/presentation/providers/purchase_controller.dart';

import '../../helpers/fake_purchase_service.dart';
import '../../helpers/fake_purchases_repository.dart';
import '../../helpers/test_provider_scope.dart';

const _product = StoreProduct(
  id: PurchaseProductIds.premiumStandard,
  title: 'Ascend Premium (Monthly)',
  description: 'Full Premium access.',
  price: '\$12.99',
);

void main() {
  test(
    'reports the store unavailable rather than fabricating a catalog',
    () async {
      final service = FakePurchaseService(available: false);
      final container = await createTestContainer(purchaseService: service);
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);

      await Future<void>.delayed(Duration.zero);
      final state = container.read(purchaseControllerProvider);

      expect(state.isStoreAvailable, isFalse);
      expect(state.isLoadingProducts, isFalse);
      expect(state.products, isEmpty);
    },
  );

  test('loads the real catalog once the store is available', () async {
    final service = FakePurchaseService(
      available: true,
      products: const [_product],
    );
    final container = await createTestContainer(purchaseService: service);
    addTearDown(container.dispose);
    container.read(purchaseControllerProvider);

    await Future<void>.delayed(Duration.zero);
    final state = container.read(purchaseControllerProvider);

    expect(state.isStoreAvailable, isTrue);
    expect(state.products, contains(_product));
  });

  test(
    'buy() delegates to the platform purchase service and tracks the pending product',
    () async {
      final service = FakePurchaseService(
        available: true,
        products: const [_product],
      );
      final container = await createTestContainer(purchaseService: service);
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(purchaseControllerProvider.notifier).buy(_product);

      expect(service.buyCallCount, 1);
      expect(
        container.read(purchaseControllerProvider).purchasingProductId,
        _product.id,
      );
    },
  );

  test(
    'a purchased update verifies with the backend, acknowledges the store, and unlocks Premium',
    () async {
      final service = FakePurchaseService(
        available: true,
        products: const [_product],
      );
      final repository = FakePurchasesRepository();
      final container = await createTestContainer(
        purchaseService: service,
        purchasesRepository: repository,
      );
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);
      await Future<void>.delayed(Duration.zero);

      service.emit(
        const PurchaseUpdate(
          productId: PurchaseProductIds.premiumStandard,
          status: PurchaseUpdateStatus.purchased,
          receiptData: 'receipt-blob',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.verifyCallCount, 1);
      expect(repository.lastProductId, PurchaseProductIds.premiumStandard);
      expect(repository.lastReceipt, 'receipt-blob');
      expect(service.acknowledgeCallCount, 1);
      final state = container.read(purchaseControllerProvider);
      expect(state.justUnlockedPremium, isTrue);
      expect(state.purchasingProductId, isNull);
    },
  );

  test(
    'a canceled update clears the pending purchase without contacting the backend',
    () async {
      final service = FakePurchaseService(
        available: true,
        products: const [_product],
      );
      final repository = FakePurchasesRepository();
      final container = await createTestContainer(
        purchaseService: service,
        purchasesRepository: repository,
      );
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);
      await container.read(purchaseControllerProvider.notifier).buy(_product);

      service.emit(
        const PurchaseUpdate(
          productId: PurchaseProductIds.premiumStandard,
          status: PurchaseUpdateStatus.canceled,
          receiptData: '',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.verifyCallCount, 0);
      expect(
        container.read(purchaseControllerProvider).purchasingProductId,
        isNull,
      );
    },
  );

  test(
    'an error update surfaces the store message without unlocking Premium',
    () async {
      final service = FakePurchaseService(
        available: true,
        products: const [_product],
      );
      final container = await createTestContainer(purchaseService: service);
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);
      await Future<void>.delayed(Duration.zero);

      service.emit(
        const PurchaseUpdate(
          productId: PurchaseProductIds.premiumStandard,
          status: PurchaseUpdateStatus.error,
          receiptData: '',
          errorMessage: 'Payment declined.',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(purchaseControllerProvider);
      expect(state.error, 'Payment declined.');
      expect(state.justUnlockedPremium, isFalse);
    },
  );

  test(
    'restore() delegates to the platform purchase service and reports it is in progress',
    () async {
      final service = FakePurchaseService(available: true);
      final container = await createTestContainer(purchaseService: service);
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final future = container
          .read(purchaseControllerProvider.notifier)
          .restore();

      expect(container.read(purchaseControllerProvider).isRestoring, isTrue);
      await future;

      expect(service.restoreCallCount, 1);
      expect(container.read(purchaseControllerProvider).isRestoring, isFalse);
    },
  );

  test(
    'restore() surfaces an error and clears isRestoring when the store call itself fails',
    () async {
      final service = FakePurchaseService(available: true)
        ..restoreError = Exception('No store connection');
      final container = await createTestContainer(purchaseService: service);
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(purchaseControllerProvider.notifier).restore();

      final state = container.read(purchaseControllerProvider);
      expect(state.isRestoring, isFalse);
      expect(state.error, contains('No store connection'));
    },
  );

  test(
    'a restored update verifies with the backend and unlocks Premium, same as a fresh purchase',
    () async {
      final service = FakePurchaseService(
        available: true,
        products: const [_product],
      );
      final repository = FakePurchasesRepository();
      final container = await createTestContainer(
        purchaseService: service,
        purchasesRepository: repository,
      );
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);
      await Future<void>.delayed(Duration.zero);

      service.emit(
        const PurchaseUpdate(
          productId: PurchaseProductIds.premiumStandard,
          status: PurchaseUpdateStatus.restored,
          receiptData: 'receipt-blob',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.verifyCallCount, 1);
      expect(
        container.read(purchaseControllerProvider).justUnlockedPremium,
        isTrue,
      );
    },
  );

  test(
    'a failed backend verification surfaces an error instead of unlocking Premium',
    () async {
      final service = FakePurchaseService(
        available: true,
        products: const [_product],
      );
      final repository = FakePurchasesRepository(shouldFail: true);
      final container = await createTestContainer(
        purchaseService: service,
        purchasesRepository: repository,
      );
      addTearDown(container.dispose);
      container.read(purchaseControllerProvider);
      await Future<void>.delayed(Duration.zero);

      service.emit(
        const PurchaseUpdate(
          productId: PurchaseProductIds.premiumStandard,
          status: PurchaseUpdateStatus.purchased,
          receiptData: 'receipt-blob',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(purchaseControllerProvider);
      expect(state.justUnlockedPremium, isFalse);
      expect(state.error, isNotNull);
      expect(service.acknowledgeCallCount, 0);
    },
  );
}
