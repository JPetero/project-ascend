import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/providers/scheduled_session_detail_controller.dart';

import '../../helpers/fake_joint_workout_sessions_repository.dart';
import '../../helpers/fake_local_notification_scheduling_service.dart';
import '../../helpers/fake_trainer_groups_repository.dart';

/// Build Session 13 continuation Part B — ScheduledSessionDetailController
/// drives RSVP/cancel/start/join for one scheduled session, plus honest,
/// plainly-worded local reminders for a Going/Maybe RSVP (see
/// FlutterLocalNotificationSchedulingService.scheduleOneOff's doc comment
/// on why this uses a distinct id space from the weekly reminders).
void main() {
  late FakeTrainerGroupsRepository repository;
  late FakeJointWorkoutSessionsRepository jointWorkoutSessionsRepository;
  late FakeLocalNotificationSchedulingService schedulingService;

  setUp(() {
    repository = FakeTrainerGroupsRepository();
    repository.groups.add(sampleGroup(id: 'group-1', ownerId: 'owner-1'));
    repository.scheduledSessions.add(
      TrainerGroupScheduledSession(
        id: 'session-1',
        groupId: 'group-1',
        createdById: 'owner-1',
        title: 'Saturday session',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      ),
    );
    jointWorkoutSessionsRepository = FakeJointWorkoutSessionsRepository();
    schedulingService = FakeLocalNotificationSchedulingService();
  });

  ScheduledSessionDetailController buildController() =>
      ScheduledSessionDetailController(
        repository: repository,
        jointWorkoutSessionsRepository: jointWorkoutSessionsRepository,
        schedulingService: schedulingService,
        sessionId: 'session-1',
      );

  test('loads the session and its group on construction', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.session?.id, 'session-1');
    expect(controller.state.group?.id, 'group-1');
    expect(controller.state.isLoading, isFalse);
  });

  test(
    'RSVPing Going schedules a plainly-worded reminder, not a guilt-based one',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final ok = await controller.rsvp(ScheduledSessionRsvpStatus.going);

      expect(ok, isTrue);
      expect(schedulingService.scheduledOneOffIds, isNotEmpty);
      final body = schedulingService.lastOneOffSchedule.values.single.body;
      expect(body, contains('starts in 30 minutes'));
      expect(body, isNot(contains('miss')));
    },
  );

  test('RSVPing Maybe also schedules a reminder', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.rsvp(ScheduledSessionRsvpStatus.maybe);

    expect(schedulingService.scheduledOneOffIds, isNotEmpty);
  });

  test('RSVPing Declined does not schedule a reminder', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.rsvp(ScheduledSessionRsvpStatus.declined);

    expect(schedulingService.scheduledOneOffIds, isEmpty);
  });

  test('cancelRsvp clears any scheduled reminder', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    await controller.rsvp(ScheduledSessionRsvpStatus.going);
    expect(schedulingService.scheduledOneOffIds, isNotEmpty);

    await controller.cancelRsvp();

    expect(schedulingService.scheduledOneOffIds, isEmpty);
  });

  test('cancelSession clears any scheduled reminder too', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    await controller.rsvp(ScheduledSessionRsvpStatus.going);

    await controller.cancelSession();

    expect(schedulingService.scheduledOneOffIds, isEmpty);
    expect(controller.state.session?.status, ScheduledSessionStatus.canceled);
  });

  test(
    'startSession reuses the Joint Workout trainerGroupId path and returns the live session id',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final liveSessionId = await controller.startSession();

      expect(liveSessionId, isNotNull);
      expect(
        jointWorkoutSessionsRepository.lastStartedScheduledSessionId,
        'session-1',
      );
    },
  );

  test(
    'joinSession calls through to the Joint Workout join endpoint',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final liveSessionId = await controller.joinSession();

      expect(liveSessionId, isNotNull);
      expect(
        jointWorkoutSessionsRepository.lastJoinedScheduledSessionId,
        'session-1',
      );
    },
  );
}
