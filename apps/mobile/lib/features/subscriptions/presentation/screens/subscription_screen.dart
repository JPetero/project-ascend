import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entitlements/capability.dart';
import '../../domain/subscription_status.dart';
import '../providers/subscription_controller.dart';

/// Membership/pricing screen — Founder Scenario 27. Shows the caller's
/// real tier, centralized (non-final) pricing, and lets them apply for
/// an affordability program. There is deliberately no "Upgrade" button
/// here: no billing integration exists this session, and a fake one
/// would mean either a fabricated success or a fabricated payment flow.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionControllerProvider);
    final controller = ref.read(subscriptionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    AscendCard(
                      child: Row(
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
                    ),
                    const SizedBox(height: AscendSpacing.lg),
                    Text(
                      'Pricing',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Text(
                      'Non-final hypotheses — not live store prices. Billing '
                      'is not yet available in this build.',
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
