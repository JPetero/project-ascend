import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/core/networking/api_client.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/workout/data/exercise_repository.dart';
import 'package:mobile/features/workout/data/personal_record_repository.dart';
import 'package:mobile/features/workout/data/workout_catalog_repository.dart';
import 'package:mobile/features/workout/data/workout_history_repository.dart';
import 'package:mobile/features/workout/data/workout_plan_repository.dart';
import 'package:mobile/features/workout/data/workout_session_repository.dart';
import 'package:mobile/features/workout/domain/exercise.dart';
import 'package:mobile/features/workout/domain/personal_record.dart';
import 'package:mobile/features/workout/domain/progression_suggestion.dart';
import 'package:mobile/features/workout/domain/workout.dart';
import 'package:mobile/features/workout/domain/workout_history_entry.dart';
import 'package:mobile/features/workout/domain/workout_plan.dart';
import 'package:mobile/features/workout/domain/workout_session.dart';

import 'workout_fixtures.dart';

ApiClient _unusedApiClient() => ApiClient(tokenStorage: SecureTokenStorage());

class FakeExerciseRepository extends ExerciseRepository {
  FakeExerciseRepository() : super(apiClient: _unusedApiClient());

  @override
  Future<List<Exercise>> list({
    String? categorySlug,
    String? muscleSlug,
    String? equipmentSlug,
    String? search,
  }) async {
    if (search != null && search.isNotEmpty) {
      return [benchPress]
          .where((e) => e.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return [benchPress];
  }

  @override
  Future<Exercise> getById(String id) async => benchPress;

  @override
  Future<ProgressionSuggestion> getProgression(String exerciseId) async =>
      sampleProgressionSuggestion;
}

class FakeWorkoutCatalogRepository extends WorkoutCatalogRepository {
  FakeWorkoutCatalogRepository() : super(apiClient: _unusedApiClient());

  @override
  Future<List<Workout>> list({String? categorySlug}) async => [sampleWorkout];

  @override
  Future<Workout> getById(String id) async => sampleWorkout;
}

class FakeWorkoutPlanRepository extends WorkoutPlanRepository {
  FakeWorkoutPlanRepository() : super(apiClient: _unusedApiClient());

  final List<WorkoutPlan> created = [];

  @override
  Future<List<WorkoutPlan>> list() async => [sampleWorkoutPlan];

  @override
  Future<WorkoutPlan> getById(String id) async => sampleWorkoutPlan;

  @override
  Future<WorkoutPlan> createFromWorkout({
    required String name,
    required String workoutId,
  }) async {
    created.add(sampleWorkoutPlan);
    return sampleWorkoutPlan;
  }

  @override
  Future<void> delete(String id) async {}
}

class FakePersonalRecordRepository extends PersonalRecordRepository {
  FakePersonalRecordRepository({List<PersonalRecord>? records})
    : _records = records ?? [samplePersonalRecord],
      super(apiClient: _unusedApiClient());

  final List<PersonalRecord> _records;

  @override
  Future<List<PersonalRecord>> list() async => _records;
}

class FakeWorkoutHistoryRepository extends WorkoutHistoryRepository {
  FakeWorkoutHistoryRepository({List<WorkoutHistoryEntry>? entries})
    : _entries = entries ?? [sampleHistoryEntry],
      super(apiClient: _unusedApiClient());

  final List<WorkoutHistoryEntry> _entries;

  @override
  Future<List<WorkoutHistoryEntry>> list({
    int page = 1,
    int limit = 20,
  }) async => _entries;

  @override
  Future<WorkoutHistoryDetail> getById(String id) async => sampleHistoryDetail;
}

/// In-memory stand-in for the backend side of a workout session. Assigns
/// incrementing server ids from [start]/[logSet] just like the real API
/// would, and can be flipped into [failNetwork] mode to simulate being
/// offline — the shape [WorkoutSessionController] checks for via
/// `AppException.network()`.
class FakeWorkoutSessionRepository extends WorkoutSessionRepository {
  FakeWorkoutSessionRepository() : super(apiClient: _unusedApiClient());

  bool failNetwork = false;
  int _idCounter = 0;
  final List<String> startedSessionIds = [];
  final List<Map<String, dynamic>> loggedSets = [];
  List<PersonalRecord> nextPersonalRecords = const [];

  @override
  Future<Map<String, dynamic>> start({String? workoutPlanId}) async {
    if (failNetwork) throw AppException.network();
    final id = 'server-session-${_idCounter++}';
    startedSessionIds.add(id);
    return {'id': id};
  }

  @override
  Future<Map<String, dynamic>?> getActive() async => null;

  @override
  Future<Map<String, dynamic>> pause(String sessionId) async {
    if (failNetwork) throw AppException.network();
    return {'id': sessionId};
  }

  @override
  Future<Map<String, dynamic>> resume(String sessionId) async {
    if (failNetwork) throw AppException.network();
    return {'id': sessionId};
  }

  @override
  Future<(Map<String, dynamic> session, List<PersonalRecord> newRecords)>
  finish(String sessionId) async {
    if (failNetwork) throw AppException.network();
    return ({'id': sessionId}, nextPersonalRecords);
  }

  @override
  Future<Map<String, dynamic>> abandon(String sessionId) async {
    if (failNetwork) throw AppException.network();
    return {'id': sessionId};
  }

  @override
  Future<Map<String, dynamic>> logSet(String sessionId, LoggedSet set) async {
    if (failNetwork) throw AppException.network();
    final id = 'server-set-${_idCounter++}';
    loggedSets.add({
      'id': id,
      'sessionId': sessionId,
      'exerciseId': set.exerciseId,
    });
    return {'id': id};
  }
}
