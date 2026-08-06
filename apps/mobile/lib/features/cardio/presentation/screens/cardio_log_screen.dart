import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/cardio_session_repository.dart';
import '../../domain/cardio_session.dart';
import '../providers/cardio_session_controller.dart';

/// Manual/summary cardio logging — activity type, duration, and optional
/// distance/elevation/calorie estimate. Deliberately not live GPS
/// tracking (see services/api/prisma/schema.prisma's CardioSession
/// comment for why); route/location visibility defaults to hidden and is
/// shown as a privacy control here even though there's no route to expose
/// yet, per packages/docs/product/user-scenario-bible.md Scenario 12.
class CardioLogScreen extends ConsumerStatefulWidget {
  const CardioLogScreen({super.key});

  @override
  ConsumerState<CardioLogScreen> createState() => _CardioLogScreenState();
}

class _CardioLogScreenState extends ConsumerState<CardioLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _duration = TextEditingController();
  final _distance = TextEditingController();
  final _elevation = TextEditingController();
  final _calories = TextEditingController();
  final _region = TextEditingController();
  final _notes = TextEditingController();
  CardioActivityType _activityType = CardioActivityType.run;
  bool _shareRoute = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _duration.dispose();
    _distance.dispose();
    _elevation.dispose();
    _calories.dispose();
    _region.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _requiredMinutes(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final minutes = int.tryParse(value);
    if (minutes == null || minutes <= 0) return 'Enter whole minutes';
    return null;
  }

  String? _optionalPositive(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(cardioSessionRepositoryProvider)
          .create(
            CardioSessionInput(
              activityType: _activityType,
              startedAt: DateTime.now(),
              durationSeconds: int.parse(_duration.text) * 60,
              distanceMeters: _distance.text.trim().isEmpty
                  ? null
                  : double.parse(_distance.text) * 1000,
              elevationGainMeters: _elevation.text.trim().isEmpty
                  ? null
                  : double.parse(_elevation.text),
              estimatedCalories: _calories.text.trim().isEmpty
                  ? null
                  : double.parse(_calories.text),
              regionLabel: _region.text.trim().isEmpty
                  ? null
                  : _region.text.trim(),
              hideRoute: !_shareRoute,
              hideStartLocation: !_shareRoute,
              hideEndLocation: !_shareRoute,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
          );
      ref.invalidate(cardioSessionsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save that session. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log cardio')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              Text(
                'A manual summary of your session — not live GPS tracking.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AscendSpacing.md),
              SegmentedButton<CardioActivityType>(
                segments: const [
                  ButtonSegment(
                    value: CardioActivityType.walk,
                    label: Text('Walk'),
                    icon: Icon(Icons.directions_walk),
                  ),
                  ButtonSegment(
                    value: CardioActivityType.run,
                    label: Text('Run'),
                    icon: Icon(Icons.directions_run),
                  ),
                  ButtonSegment(
                    value: CardioActivityType.cycle,
                    label: Text('Cycle'),
                    icon: Icon(Icons.directions_bike),
                  ),
                  ButtonSegment(
                    value: CardioActivityType.other,
                    label: Text('Other'),
                    icon: Icon(Icons.more_horiz),
                  ),
                ],
                selected: {_activityType},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _activityType = selection.first),
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _duration,
                label: 'Duration (minutes)',
                keyboardType: TextInputType.number,
                validator: _requiredMinutes,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _distance,
                label: 'Distance (km) — optional',
                keyboardType: TextInputType.number,
                validator: _optionalPositive,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _elevation,
                label: 'Elevation gain (m) — optional',
                keyboardType: TextInputType.number,
                validator: _optionalPositive,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _calories,
                label: 'Estimated calories — optional',
                keyboardType: TextInputType.number,
                validator: _optionalPositive,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _region,
                label: 'Region — optional (e.g. "Quezon City")',
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(controller: _notes, label: 'Notes — optional'),
              const SizedBox(height: AscendSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share route & location'),
                subtitle: const Text(
                  'Off by default. There is no route data to share yet — '
                  'this control is ready for when route recording ships.',
                ),
                value: _shareRoute,
                onChanged: (value) => setState(() => _shareRoute = value),
              ),
              const SizedBox(height: AscendSpacing.lg),
              AscendPrimaryButton(
                label: 'Save session',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
