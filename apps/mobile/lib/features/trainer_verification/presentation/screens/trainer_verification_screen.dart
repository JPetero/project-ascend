import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/trainer_verification_status.dart';
import '../providers/trainer_verification_controller.dart';

/// Applies for real trainer verification and shows the caller's own
/// application status (Build Session 12 Part 25-26) — distinct from the
/// self-declared "Trainer badge" toggle on the Edit Community profile
/// screen, which this screen links out to for context.
class TrainerVerificationScreen extends ConsumerWidget {
  const TrainerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerVerificationControllerProvider);
    final controller = ref.read(trainerVerificationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Trainer verification')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    const Text(
                      'Verified Trainer is a badge an Ascend admin grants '
                      'after reviewing your certifications and experience. '
                      "It's separate from the self-declared Trainer badge "
                      'you can turn on in your profile.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: AscendSpacing.lg),
                    if (state.status != null)
                      AscendCard(
                        child: Row(
                          children: [
                            Icon(
                              _statusIcon(state.status!.status),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AscendSpacing.sm),
                            Expanded(
                              child: Text(_statusLabel(state.status!.status)),
                            ),
                          ],
                        ),
                      )
                    else
                      _ApplicationForm(
                        isApplying: state.isApplying,
                        onApply: controller.apply,
                      ),
                    if (state.error != null) ...[
                      const SizedBox(height: AscendSpacing.sm),
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

IconData _statusIcon(TrainerVerificationDecision status) {
  switch (status) {
    case TrainerVerificationDecision.pending:
      return Icons.hourglass_empty;
    case TrainerVerificationDecision.approved:
      return Icons.verified;
    case TrainerVerificationDecision.rejected:
      return Icons.cancel_outlined;
  }
}

String _statusLabel(TrainerVerificationDecision status) {
  switch (status) {
    case TrainerVerificationDecision.pending:
      return 'Application pending review';
    case TrainerVerificationDecision.approved:
      return 'Verified — your profile now shows the Verified Trainer badge';
    case TrainerVerificationDecision.rejected:
      return 'Not approved — you can apply again below';
  }
}

class _ApplicationForm extends StatefulWidget {
  const _ApplicationForm({required this.isApplying, required this.onApply});

  final bool isApplying;
  final Future<bool> Function({required String credentials}) onApply;

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _credentialsController = TextEditingController();

  @override
  void dispose() {
    _credentialsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AscendTextField(
            controller: _credentialsController,
            label: 'Certifications and experience',
            maxLines: 5,
            maxLength: 1000,
            validator: (value) => (value == null || value.trim().length < 10)
                ? 'Add at least 10 characters describing your credentials'
                : null,
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendPrimaryButton(
            label: 'Apply',
            isLoading: widget.isApplying,
            onPressed: widget.isApplying
                ? null
                : () {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    widget.onApply(
                      credentials: _credentialsController.text.trim(),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
