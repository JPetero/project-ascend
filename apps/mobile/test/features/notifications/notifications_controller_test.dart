import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_controller.dart';

import '../../helpers/fake_notifications_repository.dart';

void main() {
  group('NotificationPreferencesController', () {
    test('loads preferences on construction', () async {
      final repository = FakeNotificationsRepository();
      final controller = NotificationPreferencesController(
        repository: repository,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.asData?.value.workoutReminders, isTrue);
    });

    test(
      'update optimistically applies the patch, then syncs with the server',
      () async {
        final repository = FakeNotificationsRepository();
        final controller = NotificationPreferencesController(
          repository: repository,
        );
        addTearDown(controller.dispose);
        await Future<void>.delayed(Duration.zero);

        await controller.update({'workoutReminders': false});

        expect(controller.state.asData?.value.workoutReminders, isFalse);
        expect(repository.preferences.workoutReminders, isFalse);
        // Siblings are untouched.
        expect(controller.state.asData?.value.waterReminders, isTrue);
      },
    );
  });

  group('NotificationsInboxController', () {
    test(
      'loads events and computes the unread count on construction',
      () async {
        final repository = FakeNotificationsRepository(
          events: [
            sampleNotificationEvent(id: 'e1'),
            sampleNotificationEvent(id: 'e2', readAt: DateTime(2026, 1, 1)),
          ],
        );
        final controller = NotificationsInboxController(repository: repository);
        addTearDown(controller.dispose);

        await Future<void>.delayed(Duration.zero);

        expect(controller.state.events, hasLength(2));
        expect(controller.state.unreadCount, 1);
        expect(controller.state.isLoading, isFalse);
      },
    );

    test('markRead reduces the unread count', () async {
      final repository = FakeNotificationsRepository(
        events: [sampleNotificationEvent(id: 'e1')],
      );
      final controller = NotificationsInboxController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.markRead('e1');

      expect(controller.state.unreadCount, 0);
      expect(controller.state.events.single.isRead, isTrue);
    });

    test('markAllRead clears the unread count', () async {
      final repository = FakeNotificationsRepository(
        events: [
          sampleNotificationEvent(id: 'e1'),
          sampleNotificationEvent(id: 'e2'),
        ],
      );
      final controller = NotificationsInboxController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.markAllRead();

      expect(controller.state.unreadCount, 0);
    });

    test('reports an error state when the fetch fails', () async {
      final repository = _FailingNotificationsRepository();
      final controller = NotificationsInboxController(repository: repository);
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNotNull);
    });
  });
}

class _FailingNotificationsRepository extends FakeNotificationsRepository {
  @override
  Future<List<NotificationEvent>> listEvents({bool unreadOnly = false}) {
    throw Exception('network down');
  }
}
