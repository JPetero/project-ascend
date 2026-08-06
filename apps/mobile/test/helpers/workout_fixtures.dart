import 'package:mobile/features/workout/domain/exercise.dart';
import 'package:mobile/features/workout/domain/personal_record.dart';
import 'package:mobile/features/workout/domain/progression_suggestion.dart';
import 'package:mobile/features/workout/domain/workout.dart';
import 'package:mobile/features/workout/domain/workout_history_entry.dart';
import 'package:mobile/features/workout/domain/workout_plan.dart';
import 'package:mobile/features/workout/domain/workout_session.dart';

/// Small, hand-built fixtures for the Workout Engine's domain types, shared
/// by the fake repositories and widget tests below so every test isn't
/// re-deriving the same nested object graphs.
const strengthCategory = ExerciseCategory(
  id: 'category-1',
  name: 'Strength',
  slug: 'strength',
);

const chest = MuscleGroup(id: 'muscle-1', name: 'Chest', slug: 'chest');
const triceps = MuscleGroup(id: 'muscle-2', name: 'Triceps', slug: 'triceps');
const barbell = EquipmentType(
  id: 'equipment-1',
  name: 'Barbell',
  slug: 'barbell',
);

final benchPressSummary = ExerciseSummary(
  id: 'exercise-bench-press',
  name: 'Bench Press',
  slug: 'bench-press',
  difficulty: ExerciseDifficulty.intermediate,
  category: strengthCategory,
);

final benchPress = Exercise(
  id: 'exercise-bench-press',
  name: 'Bench Press',
  slug: 'bench-press',
  description: 'A compound push exercise for the chest.',
  difficulty: ExerciseDifficulty.intermediate,
  instructions: 'Lower the bar to your chest, then press up.',
  safetyTips: 'Use a spotter for heavy sets.',
  commonMistakes: 'Flaring the elbows too wide.',
  category: strengthCategory,
  primaryMuscles: const [chest],
  secondaryMuscles: const [triceps],
  equipment: const [barbell],
  measurementType: MeasurementType.repsWeight,
  alternatives: [
    ExerciseSummary(
      id: 'exercise-pushup',
      name: 'Push-Up',
      slug: 'push-up',
      difficulty: ExerciseDifficulty.beginner,
      category: strengthCategory,
    ),
  ],
);

final samplePrescribedExercise = PrescribedExercise(
  id: 'prescribed-1',
  order: 1,
  targetSets: 3,
  targetReps: 8,
  targetWeightKg: 60,
  restSeconds: 90,
  exercise: benchPressSummary,
);

final sampleWorkout = Workout(
  id: 'workout-1',
  name: 'Full Body Strength',
  slug: 'full-body-strength',
  description: 'A balanced full-body strength session.',
  difficulty: ExerciseDifficulty.intermediate,
  estimatedDurationMinutes: 45,
  category: strengthCategory,
  exercises: [samplePrescribedExercise],
);

final sampleWorkoutPlan = WorkoutPlan(
  id: 'plan-1',
  name: 'Full Body Strength',
  workout: const WorkoutPlanSummary(
    id: 'workout-1',
    name: 'Full Body Strength',
  ),
  exercises: [samplePrescribedExercise],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final samplePersonalRecord = PersonalRecord(
  id: 'pr-1',
  exercise: const PersonalRecordExercise(
    id: 'exercise-bench-press',
    name: 'Bench Press',
    slug: 'bench-press',
  ),
  type: PersonalRecordType.maxWeight,
  value: 62.5,
  unit: 'kg',
  achievedAt: DateTime(2026, 8, 1),
  previousValue: 60,
);

final sampleHistoryEntry = WorkoutHistoryEntry(
  id: 'session-1',
  workoutPlan: const WorkoutPlanSummary(
    id: 'workout-1',
    name: 'Full Body Strength',
  ),
  startedAt: DateTime(2026, 7, 30, 9),
  completedAt: DateTime(2026, 7, 30, 9, 45),
  activeDurationSeconds: 2700,
  exerciseCount: 5,
  setCount: 15,
  totalVolumeKg: 3200,
);

final sampleHistoryDetail = WorkoutHistoryDetail(
  id: 'session-1',
  workoutPlan: const WorkoutPlanSummary(
    id: 'workout-1',
    name: 'Full Body Strength',
  ),
  startedAt: DateTime(2026, 7, 30, 9),
  completedAt: DateTime(2026, 7, 30, 9, 45),
  activeDurationSeconds: 2700,
  exerciseCount: 1,
  setCount: 1,
  totalVolumeKg: 480,
  sets: [
    LoggedSet(
      localId: 'set-1',
      serverId: 'set-1',
      exerciseId: 'exercise-bench-press',
      exerciseName: 'Bench Press',
      setNumber: 1,
      reps: 8,
      weightKg: 60,
      completedAt: DateTime(2026, 7, 30, 9, 10),
    ),
  ],
);

final sampleProgressionSuggestion = ProgressionSuggestion(
  hasPreviousPerformance: true,
  lastPerformance: LastPerformance(
    reps: 8,
    weightKg: 60,
    performedAt: DateTime(2026, 7, 25),
  ),
  suggestion: const SuggestedSet(
    reps: 8,
    weightKg: 62.5,
    rationale: 'Increase load slightly from your last session.',
  ),
);
