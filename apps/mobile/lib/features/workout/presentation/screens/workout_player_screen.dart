import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/progression_suggestion.dart';
import '../../domain/workout.dart';
import '../../domain/workout_plan.dart';
import '../../domain/workout_session.dart';
import '../providers/exercise_controller.dart';
import '../providers/workout_plan_controller.dart';
import '../providers/workout_session_controller.dart';
import '../widgets/rest_timer.dart';

class WorkoutPlayerScreen extends ConsumerStatefulWidget {
  const WorkoutPlayerScreen({super.key});

  @override
  ConsumerState<WorkoutPlayerScreen> createState() =>
      _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends ConsumerState<WorkoutPlayerScreen> {
  int _exerciseIndex = 0;
  int? _restSecondsRemaining;
  bool _isBusy = false;
  Timer? _clock;
  int _tick = 0;

  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _logSet(PrescribedExercise entry) async {
    final controller = ref.read(workoutSessionControllerProvider.notifier);
    setState(() => _isBusy = true);
    try {
      await controller.logSet(
        exerciseId: entry.exercise.id,
        exerciseName: entry.exercise.name,
        reps: entry.targetDurationSeconds == null
            ? int.tryParse(_repsController.text)
            : null,
        weightKg: entry.targetDurationSeconds == null
            ? double.tryParse(_weightController.text)
            : null,
        durationSeconds: entry.targetDurationSeconds == null
            ? null
            : int.tryParse(_durationController.text),
      );
      if (!mounted) return;
      setState(
        () => _restSecondsRemaining = entry.restSeconds > 0
            ? entry.restSeconds
            : null,
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _togglePause(WorkoutSessionState session) async {
    final controller = ref.read(workoutSessionControllerProvider.notifier);
    if (session.status == WorkoutSessionStatus.inProgress) {
      await controller.pause();
    } else {
      await controller.resume();
    }
  }

  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish workout?'),
        content: const Text("You'll see a summary of what you logged."),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    final result = await ref
        .read(workoutSessionControllerProvider.notifier)
        .finish();
    if (!mounted) return;
    context.pushReplacement(RoutePaths.workoutSummary, extra: result);
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this workout?'),
        content: const Text('Nothing logged so far will be saved.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Keep going'),
          ),
          AscendDangerButton(
            label: 'End workout',
            expand: false,
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(workoutSessionControllerProvider.notifier).abandon();
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(workoutSessionControllerProvider);

    if (session == null || !session.isActive) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No active workout.')),
      );
    }

    if (session.workoutPlanId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const AscendEmptyState(
          icon: Icons.error_outline,
          title: 'This workout has no plan',
          message: 'Start a workout from the catalog to use the player.',
        ),
      );
    }

    final planAsync = ref.watch(
      workoutPlanDetailProvider(session.workoutPlanId!),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_formatClock(session.liveActiveDurationSeconds())),
          actions: [
            IconButton(
              icon: Icon(
                session.status == WorkoutSessionStatus.inProgress
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              tooltip: session.status == WorkoutSessionStatus.inProgress
                  ? 'Pause'
                  : 'Resume',
              onPressed: () => _togglePause(session),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'End workout',
              onPressed: _abandon,
            ),
          ],
        ),
        body: SafeArea(
          child: planAsync.when(
            data: (plan) => _buildPlayer(context, session, plan),
            loading: () => const AscendLoadingIndicator(),
            error: (error, stackTrace) => AscendEmptyState(
              icon: Icons.cloud_off_outlined,
              title: "Couldn't load this workout's exercises",
              message: 'Check your connection and try again.',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(
    BuildContext context,
    WorkoutSessionState session,
    WorkoutPlan plan,
  ) {
    if (plan.exercises.isEmpty) {
      return const AscendEmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'No exercises in this plan',
        message: 'Go back and choose a different workout.',
      );
    }

    final index = _exerciseIndex.clamp(0, plan.exercises.length - 1);
    final entry = plan.exercises[index];
    final loggedForExercise = session.sets
        .where((s) => s.exerciseId == entry.exercise.id)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AscendSpacing.md),
          child: ClipRRect(
            borderRadius: AscendRadius.pillRadius,
            child: LinearProgressIndicator(
              value: (index + 1) / plan.exercises.length,
              minHeight: 6,
              semanticsLabel:
                  'Exercise ${index + 1} of ${plan.exercises.length}',
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              Text(
                'Exercise ${index + 1} of ${plan.exercises.length}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AscendSpacing.xs),
              Text(
                entry.exercise.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AscendSpacing.xs),
              Text(
                '${loggedForExercise.length} / ${entry.targetSets} sets logged',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AscendSpacing.md),
              Consumer(
                builder: (context, ref, _) {
                  final suggestionAsync = ref.watch(
                    exerciseProgressionProvider(entry.exercise.id),
                  );
                  return suggestionAsync.maybeWhen(
                    data: (suggestion) =>
                        suggestion.hasPreviousPerformance &&
                            suggestion.suggestion != null
                        ? _ProgressionCard(suggestion: suggestion)
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: AscendSpacing.md),
              if (_restSecondsRemaining != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AscendSpacing.md),
                  child: RestTimer(
                    key: ValueKey('rest-${loggedForExercise.length}'),
                    totalSeconds: _restSecondsRemaining!,
                    onComplete: () =>
                        setState(() => _restSecondsRemaining = null),
                  ),
                ),
              _SetInputForm(
                entry: entry,
                repsController: _repsController,
                weightController: _weightController,
                durationController: _durationController,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendPrimaryButton(
                label: 'Log Set',
                icon: Icons.check_circle_outline,
                isLoading: _isBusy,
                onPressed: session.status == WorkoutSessionStatus.inProgress
                    ? () => _logSet(entry)
                    : null,
              ),
              if (loggedForExercise.isNotEmpty) ...[
                const SizedBox(height: AscendSpacing.md),
                for (final set in loggedForExercise) _LoggedSetRow(set: set),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: AscendSecondaryButton(
                  label: 'Previous',
                  onPressed: index == 0
                      ? null
                      : () => setState(() => _exerciseIndex = index - 1),
                ),
              ),
              const SizedBox(width: AscendSpacing.sm),
              Expanded(
                child: AscendSecondaryButton(
                  label: index == plan.exercises.length - 1 ? 'Finish' : 'Skip',
                  onPressed: index == plan.exercises.length - 1
                      ? _finish
                      : () => setState(() => _exerciseIndex = index + 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatClock(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SetInputForm extends StatelessWidget {
  const _SetInputForm({
    required this.entry,
    required this.repsController,
    required this.weightController,
    required this.durationController,
  });

  final PrescribedExercise entry;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController durationController;

  @override
  Widget build(BuildContext context) {
    if (entry.targetDurationSeconds != null) {
      return AscendTextField(
        label: 'Duration (seconds)',
        controller: durationController,
        keyboardType: TextInputType.number,
      );
    }

    return Row(
      children: [
        Expanded(
          child: AscendTextField(
            label: 'Reps',
            controller: repsController,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: AscendSpacing.sm),
        Expanded(
          child: AscendTextField(
            label: 'Weight (kg)',
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}

class _LoggedSetRow extends StatelessWidget {
  const _LoggedSetRow({required this.set});

  final LoggedSet set;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (set.weightKg != null) parts.add('${set.weightKg} kg');
    if (set.reps != null) parts.add('${set.reps} reps');
    if (set.durationSeconds != null) parts.add('${set.durationSeconds}s');

    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
      child: Row(
        children: [
          Icon(
            set.isSynced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AscendSpacing.xs),
          Text('Set ${set.setNumber}: ${parts.join(' × ')}'),
        ],
      ),
    );
  }
}

class _ProgressionCard extends StatelessWidget {
  const _ProgressionCard({required this.suggestion});

  final ProgressionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AscendCard(
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Text(
              suggestion.suggestion!.rationale,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
