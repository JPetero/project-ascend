import 'package:mobile/features/notifications/data/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';

NotificationEvent sampleNotificationEvent({
  String id = 'event-1',
  NotificationEventType type = NotificationEventType.friendRequest,
  String title = 'New friend request',
  String body = 'Someone sent you a friend request.',
  String? data,
  DateTime? createdAt,
  DateTime? readAt,
}) {
  return NotificationEvent(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    readAt: readAt,
  );
}

/// In-memory stand-in for [NotificationsRepository].
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    NotificationPreferences? preferences,
    List<NotificationEvent>? events,
  }) : preferences =
           preferences ??
           const NotificationPreferences(
             workoutReminders: true,
             restDayReminders: true,
             waterReminders: true,
             mealReminders: true,
             achievementNotifications: true,
             socialNotifications: true,
           ),
       events = events ?? [];

  NotificationPreferences preferences;
  List<NotificationEvent> events;

  @override
  Future<NotificationPreferences> getPreferences() async => preferences;

  @override
  Future<NotificationPreferences> updatePreferences(
    Map<String, bool> patch,
  ) async {
    preferences = preferences.copyWith(
      workoutReminders: patch['workoutReminders'],
      restDayReminders: patch['restDayReminders'],
      waterReminders: patch['waterReminders'],
      mealReminders: patch['mealReminders'],
      achievementNotifications: patch['achievementNotifications'],
      socialNotifications: patch['socialNotifications'],
    );
    return preferences;
  }

  @override
  Future<List<NotificationEvent>> listEvents({bool unreadOnly = false}) async {
    return List.unmodifiable(
      unreadOnly ? events.where((e) => !e.isRead) : events,
    );
  }

  @override
  Future<int> unreadCount() async => events.where((e) => !e.isRead).length;

  @override
  Future<void> markRead(String eventId) async {
    events = [
      for (final event in events)
        if (event.id == eventId)
          NotificationEvent(
            id: event.id,
            type: event.type,
            title: event.title,
            body: event.body,
            data: event.data,
            createdAt: event.createdAt,
            readAt: DateTime(2026, 1, 2),
          )
        else
          event,
    ];
  }

  @override
  Future<void> markAllRead() async {
    events = [
      for (final event in events)
        NotificationEvent(
          id: event.id,
          type: event.type,
          title: event.title,
          body: event.body,
          data: event.data,
          createdAt: event.createdAt,
          readAt: event.readAt ?? DateTime(2026, 1, 2),
        ),
    ];
  }
}
