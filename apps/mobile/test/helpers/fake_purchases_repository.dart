import 'package:mobile/features/purchases/data/purchases_repository.dart';

/// In-memory stand-in for [PurchasesRepository].
class FakePurchasesRepository implements PurchasesRepository {
  FakePurchasesRepository({this.shouldFail = false});

  bool shouldFail;
  int verifyCallCount = 0;
  StorePurchasePlatform? lastPlatform;
  String? lastProductId;
  String? lastReceipt;

  @override
  Future<void> verify({
    required StorePurchasePlatform platform,
    required String productId,
    required String receipt,
  }) async {
    verifyCallCount++;
    lastPlatform = platform;
    lastProductId = productId;
    lastReceipt = receipt;
    if (shouldFail) {
      throw Exception('Purchase verification failed.');
    }
  }
}
