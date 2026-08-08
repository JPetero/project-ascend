import '../../../core/networking/api_client.dart';

enum StorePurchasePlatform { ios, android }

String storePurchasePlatformToJson(StorePurchasePlatform platform) =>
    platform == StorePurchasePlatform.ios ? 'IOS' : 'ANDROID';

/// Thin client for `POST /purchases/verify` — the only call that can
/// ever move an account onto the PREMIUM tier, and only after the
/// backend has checked the receipt/purchase token against Apple/Google
/// itself (see services/api/src/modules/purchases/purchases.service.ts).
class PurchasesRepository {
  PurchasesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> verify({
    required StorePurchasePlatform platform,
    required String productId,
    required String receipt,
  }) async {
    await _apiClient.post(
      '/purchases/verify',
      (data) => data,
      data: {
        'platform': storePurchasePlatformToJson(platform),
        'productId': productId,
        'receipt': receipt,
      },
    );
  }
}
