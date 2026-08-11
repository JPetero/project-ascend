import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_models.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Per-category reminder/notification preferences — Build Session 8
/// Part 12.
class NotificationPreferencesController
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  NotificationPreferencesController({
    required NotificationsRepository repository,
  }) : _repository = repository,
       super(const AsyncValue.loading()) {
    load();
  }

  final NotificationsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final preferences = await _repository.getPreferences();
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> update(Map<String, bool> patch) async {
    final previous = state;
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          workoutReminders: patch['workoutReminders'],
          restDayReminders: patch['restDayReminders'],
          waterReminders: patch['waterReminders'],
          mealReminders: patch['mealReminders'],
          achievementNotifications: patch['achievementNotifications'],
          socialNotifications: patch['socialNotifications'],
          reEngagementReminders: patch['reEngagementReminders'],
        ),
      );
    }
    try {
      final updated = await _repository.updatePreferences(patch);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = previous is AsyncData<NotificationPreferences>
          ? previous
          : AsyncValue.error(error, stackTrace);
    }
  }
}

final notificationPreferencesControllerProvider =
    StateNotifierProvider.autoDispose<
      NotificationPreferencesController,
      AsyncValue<NotificationPreferences>
    >((ref) {
      return NotificationPreferencesController(
        repository: ref.watch(notificationsRepositoryProvider),
      );
    });

class NotificationsInboxState {
  const NotificationsInboxState({
    this.events = const [],
    this.unreadCount = 0,
    this.isLoading = true,
    this.error,
  });

  final List<NotificationEvent> events;
  final int unreadCount;
  final bool isLoading;
  final Object? error;

  NotificationsInboxState copyWith({
    List<NotificationEvent>? events,
    int? unreadCount,
    bool? isLoading,
    Object? error,
  }) {
    return NotificationsInboxState(
      events: events ?? this.events,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// The caller's notification inbox and unread badge — Build Session 8
/// Part 12. Kept separate from preferences so the unread badge (watched
/// from every primary tab's app bar) doesn't reload on preference
/// changes. Deliberately has no internal Timer.periodic — see
/// ConversationsController's doc comment on why a polling screen owns
/// its own timer instead.
class NotificationsInboxController
    extends StateNotifier<NotificationsInboxState> {
  NotificationsInboxController({required NotificationsRepository repository})
    : _repository = repository,
      super(const NotificationsInboxState()) {
    refresh();
  }

  final NotificationsRepository _repository;

  Future<void> refresh({bool silently = false}) async {
    if (!silently) state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _repository.listEvents();
      final unread = events.where((e) => !e.isRead).length;
      state = state.copyWith(
        events: events,
        unreadCount: unread,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> markRead(String eventId) async {
    try {
      await _repository.markRead(eventId);
      await refresh(silently: true);
    } catch (_) {
      // Leave state as-is on failure — the event simply appears not to
      // have been marked read, which is honest since it wasn't.
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      await refresh(silently: true);
    } catch (_) {
      // As above.
    }
  }
}

final notificationsInboxControllerProvider =
    StateNotifierProvider<
      NotificationsInboxController,
      NotificationsInboxState
    >((ref) {
      return NotificationsInboxController(
        repository: ref.watch(notificationsRepositoryProvider),
      );
    });
