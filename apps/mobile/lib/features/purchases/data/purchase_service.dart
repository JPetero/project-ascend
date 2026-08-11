import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/store_product.dart';

enum PurchaseUpdateStatus { pending, purchased, restored, error, canceled }

/// One event off the platform purchase stream, translated into types
/// this feature owns rather than leaking `package:in_app_purchase`
/// types past this file — same reasoning as
/// `core/voice/speech_to_text_service.dart`. [receiptData] is Apple's
/// signed receipt or Google's purchase token (StoreKit/Billing call it
/// "server verification data"); it is only ever sent to Ascend's own
/// backend for verification, never trusted client-side.
class PurchaseUpdate {
  const PurchaseUpdate({
    required this.productId,
    required this.status,
    required this.receiptData,
    this.errorMessage,
  });

  final String productId;
  final PurchaseUpdateStatus status;
  final String receiptData;
  final String? errorMessage;
}

/// On-device store purchase flow for Premium (Build Session 9 Part
/// 17/18) — an interface so tests can supply a fake instead of
/// depending on a real StoreKit/Play Billing connection, same reasoning
/// as `LiveLocationService`/`SpeechToTextService`.
abstract class PurchaseService {
  /// False on any device/build without a live store connection — e.g.
  /// this repository's Linux CI/dev environment, or a device signed out
  /// of the App Store/Play Store. The caller must never assume `true`.
  Future<bool> isAvailable();

  Future<List<StoreProduct>> queryProducts(Set<String> productIds);

  Stream<PurchaseUpdate> get purchaseUpdates;

  Future<void> buy(StoreProduct product);

  /// Tells the store this purchase has been fully handled (verified and
  /// recorded on Ascend's backend) — required by both StoreKit and Play
  /// Billing or the purchase stays pending and can be redelivered
  /// indefinitely. A no-op if this product has no pending purchase.
  Future<void> acknowledgePurchase(String productId);

  /// Asks the store to replay every non-consumable purchase the signed-in
  /// account already owns — required by App Store guidelines whenever a
  /// paywall exists, for a reinstall or a new device where Premium was
  /// already bought. Replayed purchases arrive on [purchaseUpdates] as
  /// [PurchaseUpdateStatus.restored], same as any other update; this
  /// method only triggers that replay, it never resolves with the
  /// purchases themselves.
  Future<void> restorePurchases();

  void dispose();
}

/// Wraps `package:in_app_purchase`. Real StoreKit/Play Billing behavior
/// (a live purchase sheet, a real store connection) is not verifiable
/// from an automated test run in this environment — see
/// build-session-9.md's disclosed physical-device-testing gap.
class PluginPurchaseService implements PurchaseService {
  final _iap = InAppPurchase.instance;
  final _pendingPurchases = <String, PurchaseDetails>{};

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<StoreProduct>> queryProducts(Set<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds);
    return response.productDetails
        .map(
          (details) => StoreProduct(
            id: details.id,
            title: details.title,
            description: details.description,
            price: details.price,
          ),
        )
        .toList();
  }

  @override
  Stream<PurchaseUpdate> get purchaseUpdates {
    return _iap.purchaseStream.expand(
      (batch) => batch.map((details) {
        _pendingPurchases[details.productID] = details;
        return PurchaseUpdate(
          productId: details.productID,
          status: _mapStatus(details.status),
          receiptData: details.verificationData.serverVerificationData,
          errorMessage: details.error?.message,
        );
      }),
    );
  }

  PurchaseUpdateStatus _mapStatus(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.pending:
        return PurchaseUpdateStatus.pending;
      case PurchaseStatus.purchased:
        return PurchaseUpdateStatus.purchased;
      case PurchaseStatus.restored:
        return PurchaseUpdateStatus.restored;
      case PurchaseStatus.error:
        return PurchaseUpdateStatus.error;
      case PurchaseStatus.canceled:
        return PurchaseUpdateStatus.canceled;
    }
  }

  @override
  Future<void> buy(StoreProduct product) async {
    final response = await _iap.queryProductDetails({product.id});
    final details = response.productDetails.firstWhere(
      (p) => p.id == product.id,
    );
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> acknowledgePurchase(String productId) async {
    final details = _pendingPurchases.remove(productId);
    if (details != null && details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  void dispose() {}
}
