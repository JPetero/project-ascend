import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/subscriptions/domain/subscription_status.dart';

void main() {
  group('SubscriptionStatus.fromJson', () {
    test('parses expiresAt and willRenew for a PREMIUM subscription', () {
      final status = SubscriptionStatus.fromJson({
        'tier': 'PREMIUM',
        'expiresAt': '2026-09-09T00:00:00.000Z',
        'willRenew': true,
        'eligibility': null,
      });

      expect(status.tier, PlanTier.premium);
      expect(status.expiresAt, DateTime.parse('2026-09-09T00:00:00.000Z'));
      expect(status.willRenew, isTrue);
    });

    test('leaves expiresAt/willRenew null for a FREE user (Build Session 10 '
        'Part 26)', () {
      final status = SubscriptionStatus.fromJson({
        'tier': 'FREE',
        'expiresAt': null,
        'willRenew': null,
        'eligibility': null,
      });

      expect(status.tier, PlanTier.free);
      expect(status.expiresAt, isNull);
      expect(status.willRenew, isNull);
    });
  });
}
