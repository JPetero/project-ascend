import '../../../core/entitlements/capability.dart';

/// Founder Scenario 27's pricing hypotheses — non-final business
/// assumptions, not live store prices (no billing integration exists
/// yet). Mirrors services/api/src/common/config/pricing.config.ts.
class PricingPoint {
  const PricingPoint({
    required this.currency,
    required this.standardAmount,
    required this.eligibleAmount,
  });

  final String currency;
  final num standardAmount;
  final num eligibleAmount;

  factory PricingPoint.fromJson(Map<String, dynamic> json) {
    return PricingPoint(
      currency: json['currency'] as String,
      standardAmount: json['standardAmount'] as num,
      eligibleAmount: json['eligibleAmount'] as num,
    );
  }
}

enum AffordabilityProgram { student, accessibility, senior, regional }

String affordabilityProgramToJson(AffordabilityProgram program) =>
    program.name.toUpperCase();

AffordabilityProgram affordabilityProgramFromJson(String value) =>
    AffordabilityProgram.values.firstWhere(
      (p) => p.name.toUpperCase() == value,
      orElse: () => AffordabilityProgram.regional,
    );

enum AffordabilityStatus { pending, approved, rejected }

AffordabilityStatus affordabilityStatusFromJson(String value) =>
    AffordabilityStatus.values.firstWhere(
      (s) => s.name.toUpperCase() == value,
      orElse: () => AffordabilityStatus.pending,
    );

/// Eligibility status is never included on a public-facing profile —
/// see services/api/prisma/schema.prisma's AffordabilityEligibility
/// comment.
class EligibilityStatus {
  const EligibilityStatus({required this.program, required this.status});

  final AffordabilityProgram program;
  final AffordabilityStatus status;

  factory EligibilityStatus.fromJson(Map<String, dynamic> json) {
    return EligibilityStatus(
      program: affordabilityProgramFromJson(json['program'] as String),
      status: affordabilityStatusFromJson(json['status'] as String),
    );
  }
}

class SubscriptionStatus {
  const SubscriptionStatus({required this.tier, this.eligibility});

  final PlanTier tier;
  final EligibilityStatus? eligibility;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: (json['tier'] as String) == 'PREMIUM'
          ? PlanTier.premium
          : PlanTier.free,
      eligibility: json['eligibility'] == null
          ? null
          : EligibilityStatus.fromJson(
              json['eligibility'] as Map<String, dynamic>,
            ),
    );
  }
}
