import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/local_notification_scheduling_service.dart';
import '../../../joint_workouts/data/joint_workout_sessions_repository.dart';
import '../../../joint_workouts/presentation/providers/joint_workout_sessions_controller.dart';
import '../../../notifications/presentation/providers/workout_reminder_controller.dart';
import '../../data/trainer_groups_repository.dart';
import '../../domain/trainer_group.dart';
import 'trainer_groups_controller.dart';

class ScheduledSessionDetailState {
  const ScheduledSessionDetailState({
    this.session,
    this.group,
    this.isLoading = true,
    this.isActing = false,
    this.error,
  });

  final TrainerGroupScheduledSession? session;
  final TrainerGroup? group;
  final bool isLoading;
  final bool isActing;
  final String? error;

  ScheduledSessionDetailState copyWith({
    TrainerGroupScheduledSession? session,
    TrainerGroup? group,
    bool? isLoading,
    bool? isActing,
    String? error,
  }) {
    return ScheduledSessionDetailState(
      session: session ?? this.session,
      group: group ?? this.group,
      isLoading: isLoading ?? this.isLoading,
      isActing: isActing ?? this.isActing,
      error: error,
    );
  }
}

/// Drives one trainer-group scheduled session's full detail screen
/// (Build Session 13 continuation Part B) — RSVP going/maybe/decline/
/// change/cancel, host cancel/start, and "Join session" for eligible
/// Going participants once the host has started it. Loads both the
/// session and its group together since the detail screen needs the
/// group's member list (to show the host's display name) and the
/// viewer's own role (to decide whether cancel/start are available) —
/// neither of which the session-only endpoint returns.
class ScheduledSessionDetailController
    extends StateNotifier<ScheduledSessionDetailState> {
  ScheduledSessionDetailController({
    required TrainerGroupsRepository repository,
    required JointWorkoutSessionsRepository jointWorkoutSessionsRepository,
    required LocalNotificationSchedulingService schedulingService,
    required this.sessionId,
  }) : _repository = repository,
       _jointWorkoutSessionsRepository = jointWorkoutSessionsRepository,
       _schedulingService = schedulingService,
       super(const ScheduledSessionDetailState()) {
    load();
  }

  final TrainerGroupsRepository _repository;
  final JointWorkoutSessionsRepository _jointWorkoutSessionsRepository;
  final LocalNotificationSchedulingService _schedulingService;
  final String sessionId;

  /// Distinct id space from workoutReminderNotificationBaseId's weekly
  /// slots (small numbers, `baseId * 10 + weekday`) — see
  /// FlutterLocalNotificationSchedulingService.scheduleOneOff's doc
  /// comment.
  int get _reminderId => 20000000 + (sessionId.hashCode.abs() % 1000000);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final session = await _repository.getScheduledSession(sessionId);
      final group = await _repository.getGroup(session.groupId);
      state = ScheduledSessionDetailState(
        session: session,
        group: group,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> _act(Future<void> Function() action) async {
    state = state.copyWith(isActing: true, error: null);
    try {
      await action();
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(isActing: false, error: error.toString());
      return false;
    }
  }

  Future<bool> rsvp(ScheduledSessionRsvpStatus status) async {
    final ok = await _act(
      () => _repository.rsvpToScheduledSession(sessionId, status),
    );
    if (ok) await _syncReminder();
    return ok;
  }

  Future<bool> cancelRsvp() async {
    final ok = await _act(() => _repository.cancelMyRsvp(sessionId));
    if (ok) await _schedulingService.cancelOneOff(_reminderId);
    return ok;
  }

  Future<bool> cancelSession() async {
    final ok = await _act(() => _repository.cancelScheduledSession(sessionId));
    if (ok) await _schedulingService.cancelOneOff(_reminderId);
    return ok;
  }

  /// Schedules an honest, plainly-worded reminder ("starts in 30
  /// minutes") for a Going/Maybe RSVP, or cancels one for a Decline —
  /// never guilt-based copy (e.g. "you're missing out"), matching this
  /// app's existing reminder tone (see NotificationType's schema
  /// comment). A no-op past-dated reminder is safe to attempt:
  /// [LocalNotificationSchedulingService.scheduleOneOff] never fires one
  /// already in the past.
  Future<void> _syncReminder() async {
    final session = state.session;
    if (session == null) return;
    final status = session.viewerRsvpStatus;
    if (status == ScheduledSessionRsvpStatus.going ||
        status == ScheduledSessionRsvpStatus.maybe) {
      await _schedulingService.scheduleOneOff(
        id: _reminderId,
        title: 'Upcoming session',
        body: '${session.title ?? 'Your group session'} starts in 30 minutes.',
        dateTime: session.scheduledAt.subtract(const Duration(minutes: 30)),
      );
    } else {
      await _schedulingService.cancelOneOff(_reminderId);
    }
  }

  /// Reuses the Joint Workout module's own `trainerGroupId` create path
  /// server-side (see JointWorkoutSessionsService.startFromScheduledSession)
  /// — this never implements a second real-time session of its own.
  /// Returns the live session's id on success so the caller can navigate
  /// straight into JointWorkoutSessionDetailScreen.
  Future<String?> startSession() async {
    state = state.copyWith(isActing: true, error: null);
    try {
      final joined = await _jointWorkoutSessionsRepository
          .startFromScheduledSession(sessionId);
      await load();
      return joined.id;
    } catch (error) {
      state = state.copyWith(isActing: false, error: error.toString());
      return null;
    }
  }

  Future<String?> joinSession() async {
    state = state.copyWith(isActing: true, error: null);
    try {
      final joined = await _jointWorkoutSessionsRepository
          .joinFromScheduledSession(sessionId);
      state = state.copyWith(isActing: false);
      return joined.id;
    } catch (error) {
      state = state.copyWith(isActing: false, error: error.toString());
      return null;
    }
  }
}

final scheduledSessionDetailControllerProvider = StateNotifierProvider
    .autoDispose
    .family<
      ScheduledSessionDetailController,
      ScheduledSessionDetailState,
      String
    >((ref, sessionId) {
      return ScheduledSessionDetailController(
        repository: ref.watch(trainerGroupsRepositoryProvider),
        jointWorkoutSessionsRepository: ref.watch(
          jointWorkoutSessionsRepositoryProvider,
        ),
        schedulingService: ref.watch(
          localNotificationSchedulingServiceProvider,
        ),
        sessionId: sessionId,
      );
    });
