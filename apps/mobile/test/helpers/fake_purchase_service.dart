import 'dart:async';

import 'package:mobile/features/purchases/data/purchase_service.dart';
import 'package:mobile/features/purchases/domain/store_product.dart';

/// In-memory stand-in for [PurchaseService] — defaults to an unavailable
/// store (matching this repository's own Linux CI/dev environment) so
/// existing tests don't need to opt into IAP behavior explicitly.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({bool available = false, List<StoreProduct>? products})
    : available = available,
      products = products ?? const [];

  bool available;
  List<StoreProduct> products;
  final _controller = StreamController<PurchaseUpdate>.broadcast();
  int buyCallCount = 0;
  int acknowledgeCallCount = 0;
  int disposeCallCount = 0;
  int restoreCallCount = 0;
  String? lastAcknowledgedProductId;
  Object? restoreError;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<StoreProduct>> queryProducts(Set<String> productIds) async {
    return products
        .where((product) => productIds.contains(product.id))
        .toList();
  }

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => _controller.stream;

  @override
  Future<void> buy(StoreProduct product) async {
    buyCallCount++;
  }

  @override
  Future<void> acknowledgePurchase(String productId) async {
    acknowledgeCallCount++;
    lastAcknowledgedProductId = productId;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCallCount++;
    if (restoreError != null) throw restoreError!;
  }

  @override
  void dispose() {
    disposeCallCount++;
  }

  void emit(PurchaseUpdate update) => _controller.add(update);
}
