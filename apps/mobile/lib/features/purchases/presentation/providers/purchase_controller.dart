import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/purchase_service.dart';
import '../../data/purchases_repository.dart';
import '../../domain/store_product.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PluginPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(apiClient: ref.watch(apiClientProvider));
});

StorePurchasePlatform currentStorePlatform() {
  if (Platform.isIOS) return StorePurchasePlatform.ios;
  return StorePurchasePlatform.android;
}

class PurchaseState {
  const PurchaseState({
    this.isStoreAvailable = false,
    this.isLoadingProducts = true,
    this.products = const [],
    this.purchasingProductId,
    this.isRestoring = false,
    this.error,
    this.justUnlockedPremium = false,
  });

  final bool isStoreAvailable;
  final bool isLoadingProducts;
  final List<StoreProduct> products;
  final String? purchasingProductId;
  final bool isRestoring;
  final String? error;
  final bool justUnlockedPremium;

  PurchaseState copyWith({
    bool? isStoreAvailable,
    bool? isLoadingProducts,
    List<StoreProduct>? products,
    String? purchasingProductId,
    bool clearPurchasingProductId = false,
    bool? isRestoring,
    String? error,
    bool clearError = false,
    bool? justUnlockedPremium,
  }) {
    return PurchaseState(
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      products: products ?? this.products,
      purchasingProductId: clearPurchasingProductId
          ? null
          : (purchasingProductId ?? this.purchasingProductId),
      isRestoring: isRestoring ?? this.isRestoring,
      error: clearError ? null : (error ?? this.error),
      justUnlockedPremium: justUnlockedPremium ?? this.justUnlockedPremium,
    );
  }
}

/// Drives the real Store purchase flow shown on SubscriptionScreen —
/// query the live catalog, start a purchase, and hand the resulting
/// receipt/purchase token to PurchasesRepository for real backend
/// verification. Never marks an account Premium itself; that only
/// happens once `POST /purchases/verify` succeeds (Build Session 9 Part
/// 17/18).
class PurchaseController extends StateNotifier<PurchaseState> {
  PurchaseController({
    required PurchaseService purchaseService,
    required PurchasesRepository repository,
    required StorePurchasePlatform platform,
  }) : _purchaseService = purchaseService,
       _repository = repository,
       _platform = platform,
       super(const PurchaseState()) {
    _subscription = _purchaseService.purchaseUpdates.listen(_handleUpdate);
    _init();
  }

  final PurchaseService _purchaseService;
  final PurchasesRepository _repository;
  final StorePurchasePlatform _platform;
  StreamSubscription<PurchaseUpdate>? _subscription;

  Future<void> _init() async {
    final available = await _purchaseService.isAvailable();
    if (!available) {
      state = state.copyWith(isStoreAvailable: false, isLoadingProducts: false);
      return;
    }
    final products = await _purchaseService.queryProducts(
      PurchaseProductIds.all,
    );
    state = state.copyWith(
      isStoreAvailable: true,
      isLoadingProducts: false,
      products: products,
    );
  }

  Future<void> buy(StoreProduct product) async {
    state = state.copyWith(
      purchasingProductId: product.id,
      clearError: true,
      justUnlockedPremium: false,
    );
    try {
      await _purchaseService.buy(product);
    } catch (error) {
      state = state.copyWith(
        clearPurchasingProductId: true,
        error: error.toString(),
      );
    }
  }

  /// Replays every purchase the signed-in Store account already owns —
  /// the required "Restore Purchases" affordance for a reinstall or a
  /// new device where Premium was already bought. This method only
  /// triggers the platform replay and reports whether the *request*
  /// itself failed (e.g. no store connection); a successfully replayed
  /// purchase arrives via [PurchaseService.purchaseUpdates] and is
  /// handled by [_handleUpdate] exactly like a fresh purchase, including
  /// backend verification before Premium unlocks.
  Future<void> restore() async {
    state = state.copyWith(isRestoring: true, clearError: true);
    try {
      await _purchaseService.restorePurchases();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<void> _handleUpdate(PurchaseUpdate update) async {
    switch (update.status) {
      case PurchaseUpdateStatus.pending:
        return;
      case PurchaseUpdateStatus.canceled:
        state = state.copyWith(clearPurchasingProductId: true);
        return;
      case PurchaseUpdateStatus.error:
        state = state.copyWith(
          clearPurchasingProductId: true,
          error: update.errorMessage ?? 'The purchase could not be completed.',
        );
        return;
      case PurchaseUpdateStatus.purchased:
      case PurchaseUpdateStatus.restored:
        try {
          await _repository.verify(
            platform: _platform,
            productId: update.productId,
            receipt: update.receiptData,
          );
          await _purchaseService.acknowledgePurchase(update.productId);
          state = state.copyWith(
            clearPurchasingProductId: true,
            justUnlockedPremium: true,
          );
        } catch (error) {
          state = state.copyWith(
            clearPurchasingProductId: true,
            error: error.toString(),
          );
        }
        return;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final purchaseControllerProvider =
    StateNotifierProvider<PurchaseController, PurchaseState>((ref) {
      return PurchaseController(
        purchaseService: ref.watch(purchaseServiceProvider),
        repository: ref.watch(purchasesRepositoryProvider),
        platform: currentStorePlatform(),
      );
    });
