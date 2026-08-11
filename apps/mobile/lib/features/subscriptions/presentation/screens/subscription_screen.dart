import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entitlements/capability.dart';
import '../../../../core/entitlements/capability_provider.dart';
import '../../../feature_flags/domain/ascend_feature.dart';
import '../../../feature_flags/presentation/providers/feature_flags_provider.dart';
import '../../../purchases/domain/store_product.dart';
import '../../../purchases/presentation/providers/purchase_controller.dart';
import '../../domain/subscription_status.dart';
import '../providers/subscription_controller.dart';

/// Membership/pricing screen — Founder Scenario 27. Shows the caller's
/// real tier, centralized (non-final) pricing, an "Upgrade to Premium"
/// flow backed by a real Store purchase (Build Session 9 Part 17/18 —
/// see PurchaseController), and lets them apply for an affordability
/// program.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionControllerProvider);
    final controller = ref.read(subscriptionControllerProvider.notifier);
    final purchaseState = ref.watch(purchaseControllerProvider);
    final purchasesEnabled = ref.watch(
      featureEnabledProvider(AscendFeature.storePurchases),
    );

    ref.listen<PurchaseState>(purchaseControllerProvider, (previous, next) {
      if (next.justUnlockedPremium && previous?.justUnlockedPremium != true) {
        ref.invalidate(fetchedPlanTierProvider);
        controller.refresh();
      }
    });

    final failedToLoad = state.status == null && state.error != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : failedToLoad
            ? AscendEmptyState(
                icon: Icons.error_outline,
                title: "Couldn't load your membership",
                message: state.error!,
                actionLabel: 'Try again',
                onAction: controller.refresh,
              )
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    // A refresh failed but earlier data is still on
                    // screen — show it alongside a way to retry rather
                    // than silently discarding what's already loaded.
                    if (state.error != null) ...[
                      AscendCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: AscendSpacing.sm),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AscendSpacing.md),
                    ],
                    AscendCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.workspace_premium_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AscendSpacing.sm),
                              Text(
                                state.status?.tier == PlanTier.premium
                                    ? 'Premium plan'
                                    : 'Free plan',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          if (state.status?.tier == PlanTier.premium &&
                              state.status?.expiresAt != null) ...[
                            const SizedBox(height: AscendSpacing.xs),
                            Text(
                              _renewalLabel(state.status!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (state.status?.tier != PlanTier.premium) ...[
                      const SizedBox(height: AscendSpacing.lg),
                      Text(
                        'Upgrade',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AscendSpacing.sm),
                      if (purchasesEnabled)
                        _UpgradeSection(
                          purchaseState: purchaseState,
                          isEligible:
                              state.status?.eligibility?.status ==
                              AffordabilityStatus.approved,
                          onBuy: (product) => ref
                              .read(purchaseControllerProvider.notifier)
                              .buy(product),
                          onRestore: () => ref
                              .read(purchaseControllerProvider.notifier)
                              .restore(),
                        )
                      else
                        const Text(
                          "Purchases aren't enabled for this build yet.",
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                    const SizedBox(height: AscendSpacing.lg),
                    Text(
                      'Pricing',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Text(
                      'Non-final hypotheses — actual store prices are shown '
                      'above once the Store connection is available.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    for (final point in state.pricing)
                      AscendCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(point.currency),
                            Text(
                              '${point.standardAmount} standard · '
                              '${point.eligibleAmount} eligible',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AscendSpacing.lg),
                    Text(
                      'Affordability programs',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Text(
                      'Student, Accessibility, Senior, and Regional Affordability '
                      'access reduce the standard price. Your eligibility status '
                      'is never shown on your public profile.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    if (state.status?.eligibility != null)
                      AscendCard(
                        child: Text(
                          '${_programLabel(state.status!.eligibility!.program)} — '
                          '${_statusLabel(state.status!.eligibility!.status)}',
                        ),
                      )
                    else
                      _EligibilityForm(
                        isApplying: state.isApplying,
                        onApply: controller.applyForEligibility,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Shows the real Store product/price and a Buy button once a live
/// StoreKit/Play Billing connection exists, or an honest explanation
/// when it doesn't — never a fabricated price or a fake success.
class _UpgradeSection extends StatelessWidget {
  const _UpgradeSection({
    required this.purchaseState,
    required this.isEligible,
    required this.onBuy,
    required this.onRestore,
  });

  final PurchaseState purchaseState;
  final bool isEligible;
  final void Function(StoreProduct product) onBuy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    if (purchaseState.isLoadingProducts) {
      return const AscendLoadingIndicator();
    }
    if (!purchaseState.isStoreAvailable) {
      return const Text(
        "In-app purchases aren't available on this device or build.",
        style: TextStyle(fontSize: 12),
      );
    }

    final wantedId = isEligible
        ? PurchaseProductIds.premiumEligible
        : PurchaseProductIds.premiumStandard;
    StoreProduct? product;
    for (final candidate in purchaseState.products) {
      if (candidate.id == wantedId) {
        product = candidate;
        break;
      }
    }
    product ??= purchaseState.products.isEmpty
        ? null
        : purchaseState.products.first;

    if (product == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No Premium product is configured in the store yet.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: AscendSpacing.sm),
          _RestoreButton(
            isRestoring: purchaseState.isRestoring,
            onPressed: onRestore,
          ),
        ],
      );
    }

    final isPurchasing = purchaseState.purchasingProductId == product.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AscendCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(product.title)),
              Text(
                product.price,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.sm),
        AscendPrimaryButton(
          label: 'Upgrade to Premium',
          isLoading: isPurchasing,
          onPressed: isPurchasing ? null : () => onBuy(product!),
        ),
        const SizedBox(height: AscendSpacing.sm),
        _RestoreButton(
          isRestoring: purchaseState.isRestoring,
          onPressed: onRestore,
        ),
        if (purchaseState.error != null) ...[
          const SizedBox(height: AscendSpacing.sm),
          Text(
            purchaseState.error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Required by App Store guidelines whenever a paywall exists — replays
/// purchases the signed-in Store account already owns, for a reinstall
/// or new device where Premium was already bought (S13 Part 33-49). A
/// secondary/ghost-styled action deliberately: this is a recovery path
/// for existing owners, not the primary call to action above it.
class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.isRestoring, required this.onPressed});

  final bool isRestoring;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AscendGhostButton(
      label: isRestoring ? 'Restoring…' : 'Restore Purchases',
      onPressed: isRestoring ? null : onPressed,
    );
  }
}

/// The store's own stated renewal/expiration for the current period
/// (Build Session 10 Part 26) — honest about what `willRenew` actually
/// tells us: `true` means the store confirmed auto-renew is on,
/// `false` means it's explicitly off (the plan will lapse), and `null`
/// (an older row, or a store response that omitted it) gets a neutral
/// "current period ends" phrasing rather than guessing either way.
String _renewalLabel(SubscriptionStatus status) {
  final date = _formatDate(status.expiresAt!);
  return switch (status.willRenew) {
    true => 'Renews $date',
    false => 'Expires $date — auto-renew is off',
    null => 'Current period ends $date',
  };
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

String _programLabel(AffordabilityProgram program) {
  switch (program) {
    case AffordabilityProgram.student:
      return 'Student Access';
    case AffordabilityProgram.accessibility:
      return 'Accessibility Access';
    case AffordabilityProgram.senior:
      return 'Senior Access';
    case AffordabilityProgram.regional:
      return 'Regional Affordability';
  }
}

String _statusLabel(AffordabilityStatus status) {
  switch (status) {
    case AffordabilityStatus.pending:
      return 'Application pending review';
    case AffordabilityStatus.approved:
      return 'Approved';
    case AffordabilityStatus.rejected:
      return 'Not approved';
  }
}

class _EligibilityForm extends StatefulWidget {
  const _EligibilityForm({required this.isApplying, required this.onApply});

  final bool isApplying;
  final Future<bool> Function({
    required AffordabilityProgram program,
    String? notes,
  })
  onApply;

  @override
  State<_EligibilityForm> createState() => _EligibilityFormState();
}

class _EligibilityFormState extends State<_EligibilityForm> {
  AffordabilityProgram _program = AffordabilityProgram.student;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<AffordabilityProgram>(
          value: _program,
          isExpanded: true,
          items: [
            for (final program in AffordabilityProgram.values)
              DropdownMenuItem(
                value: program,
                child: Text(_programLabel(program)),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _program = value);
          },
        ),
        const SizedBox(height: AscendSpacing.sm),
        AscendTextField(
          controller: _notesController,
          label: 'Notes — optional',
          maxLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: AscendSpacing.md),
        AscendPrimaryButton(
          label: 'Apply',
          isLoading: widget.isApplying,
          onPressed: widget.isApplying
              ? null
              : () => widget.onApply(
                  program: _program,
                  notes: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                ),
        ),
      ],
    );
  }
}
