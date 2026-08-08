/// Registered App Store Connect / Google Play Console product ids — kept
/// centralized so no literal is duplicated between the purchase flow and
/// tests. `.eligible` mirrors the discounted price point an APPROVED
/// affordability application (Founder Scenario 27) unlocks; stores don't
/// support per-user custom pricing, so a reduced-price product is
/// registered as its own SKU, same as any other subscription tier.
class PurchaseProductIds {
  const PurchaseProductIds._();

  static const String premiumStandard =
      'com.projectascend.mobile.premium.monthly';
  static const String premiumEligible =
      'com.projectascend.mobile.premium.monthly.eligible';

  static const Set<String> all = {premiumStandard, premiumEligible};
}

/// A product as returned by the real App Store/Play Store catalog — the
/// price string is already formatted and localized by the platform, so
/// it is never re-derived from `pricing.config.ts`'s non-final
/// hypotheses (see SubscriptionScreen's pricing-hypotheses disclaimer).
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  final String id;
  final String title;
  final String description;
  final String price;
}
