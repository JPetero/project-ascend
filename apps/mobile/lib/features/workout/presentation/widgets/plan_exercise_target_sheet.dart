import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/plan_exercise_draft.dart';

/// Edits one exercise row's targets (sets/reps/duration/weight/distance/
/// rest/notes) in place. All fields but sets are optional — a plan doesn't
/// know in advance which measurement type each exercise will use, so the
/// editor offers all of them rather than guessing.
Future<void> showPlanExerciseTargetSheet(
  BuildContext context,
  PlanExerciseDraft draft,
) {
  return showAscendBottomSheet<void>(
    context: context,
    title: draft.exerciseName,
    child: _TargetForm(draft: draft),
  );
}

class _TargetForm extends StatefulWidget {
  const _TargetForm({required this.draft});

  final PlanExerciseDraft draft;

  @override
  State<_TargetForm> createState() => _TargetFormState();
}

class _TargetFormState extends State<_TargetForm> {
  late final _sets = TextEditingController(
    text: '${widget.draft.targetSets}',
  );
  late final _reps = TextEditingController(
    text: widget.draft.targetReps?.toString() ?? '',
  );
  late final _duration = TextEditingController(
    text: widget.draft.targetDurationSeconds?.toString() ?? '',
  );
  late final _weight = TextEditingController(
    text: widget.draft.targetWeightKg?.toString() ?? '',
  );
  late final _distance = TextEditingController(
    text: widget.draft.targetDistanceMeters?.toString() ?? '',
  );
  late final _rest = TextEditingController(text: '${widget.draft.restSeconds}');
  late final _notes = TextEditingController(text: widget.draft.notes ?? '');

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _duration.dispose();
    _weight.dispose();
    _distance.dispose();
    _rest.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    widget.draft
      ..targetSets = int.tryParse(_sets.text)?.clamp(1, 20) ?? 1
      ..targetReps = int.tryParse(_reps.text)
      ..targetDurationSeconds = int.tryParse(_duration.text)
      ..targetWeightKg = double.tryParse(_weight.text)
      ..targetDistanceMeters = double.tryParse(_distance.text)
      ..restSeconds = int.tryParse(_rest.text)?.clamp(0, 900) ?? 60
      ..notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AscendTextField(
          label: 'Target sets',
          controller: _sets,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AscendSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AscendTextField(
                label: 'Target reps',
                controller: _reps,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AscendSpacing.sm),
            Expanded(
              child: AscendTextField(
                label: 'Target weight (kg)',
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AscendSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AscendTextField(
                label: 'Duration (seconds)',
                controller: _duration,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AscendSpacing.sm),
            Expanded(
              child: AscendTextField(
                label: 'Distance (meters)',
                controller: _distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AscendSpacing.sm),
        AscendTextField(
          label: 'Rest between sets (seconds)',
          controller: _rest,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AscendSpacing.sm),
        AscendTextField(label: 'Notes', controller: _notes),
        const SizedBox(height: AscendSpacing.md),
        AscendPrimaryButton(label: 'Done', onPressed: _save),
      ],
    );
  }
}
