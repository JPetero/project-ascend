import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trainer_groups_repository.dart';
import '../../domain/trainer_group.dart';
import 'trainer_groups_controller.dart';

class TrainerGroupDetailState {
  const TrainerGroupDetailState({
    this.group,
    this.messages = const [],
    this.sharedPlans = const [],
    this.announcements = const [],
    this.isLoading = true,
    this.isSendingMessage = false,
    this.isPostingAnnouncement = false,
    this.error,
  });

  final TrainerGroup? group;
  final List<TrainerGroupMessage> messages;
  final List<TrainerGroupSharedPlan> sharedPlans;
  final List<TrainerGroupAnnouncement> announcements;
  final bool isLoading;
  final bool isSendingMessage;
  final bool isPostingAnnouncement;
  final String? error;

  TrainerGroupDetailState copyWith({
    TrainerGroup? group,
    List<TrainerGroupMessage>? messages,
    List<TrainerGroupSharedPlan>? sharedPlans,
    List<TrainerGroupAnnouncement>? announcements,
    bool? isLoading,
    bool? isSendingMessage,
    bool? isPostingAnnouncement,
    String? error,
    bool clearError = false,
  }) {
    return TrainerGroupDetailState(
      group: group ?? this.group,
      messages: messages ?? this.messages,
      sharedPlans: sharedPlans ?? this.sharedPlans,
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isPostingAnnouncement:
          isPostingAnnouncement ?? this.isPostingAnnouncement,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// A single group's members, chat, and shared plans.
class TrainerGroupDetailController
    extends StateNotifier<TrainerGroupDetailState> {
  TrainerGroupDetailController({
    required TrainerGroupsRepository repository,
    required this.groupId,
  }) : _repository = repository,
       super(const TrainerGroupDetailState()) {
    load();
  }

  final TrainerGroupsRepository _repository;
  final String groupId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.getGroup(groupId),
        _repository.listMessages(groupId),
        _repository.listSharedPlans(groupId),
        _repository.listAnnouncements(groupId),
      ]);
      state = TrainerGroupDetailState(
        group: results[0] as TrainerGroup,
        // The API returns newest-first; the chat UI reads top-to-bottom
        // as oldest-first.
        messages: (results[1] as List<TrainerGroupMessage>).reversed.toList(),
        sharedPlans: results[2] as List<TrainerGroupSharedPlan>,
        announcements: results[3] as List<TrainerGroupAnnouncement>,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> sendMessage({String? body, String? imageUrl}) async {
    if ((body == null || body.trim().isEmpty) &&
        (imageUrl == null || imageUrl.trim().isEmpty)) {
      return false;
    }
    state = state.copyWith(isSendingMessage: true, clearError: true);
    try {
      final message = await _repository.sendMessage(
        groupId,
        body: body?.trim(),
        imageUrl: imageUrl?.trim(),
      );
      state = state.copyWith(
        messages: [...state.messages, message],
        isSendingMessage: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isSendingMessage: false, error: error.toString());
      return false;
    }
  }

  Future<bool> invite(String inviteeUserId) async {
    try {
      await _repository.invite(groupId, inviteeUserId);
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    try {
      await _repository.removeMember(groupId, userId);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> sharePlan(String workoutPlanId) async {
    try {
      final shared = await _repository.sharePlan(groupId, workoutPlanId);
      state = state.copyWith(sharedPlans: [shared, ...state.sharedPlans]);
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> unsharePlan(String sharedPlanId) async {
    final previous = state.sharedPlans;
    state = state.copyWith(
      sharedPlans: previous.where((p) => p.id != sharedPlanId).toList(),
    );
    try {
      await _repository.unsharePlan(groupId, sharedPlanId);
      return true;
    } catch (error) {
      state = state.copyWith(sharedPlans: previous, error: error.toString());
      return false;
    }
  }

  /// Owner-only, and only on an expanded (Premium) group — see
  /// TrainerGroupsService.setMemberRole.
  Future<bool> setMemberRole(String userId, TrainerGroupMemberRole role) async {
    try {
      await _repository.setMemberRole(groupId, userId, role);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> postAnnouncement(String body) async {
    if (body.trim().isEmpty) return false;
    state = state.copyWith(isPostingAnnouncement: true, clearError: true);
    try {
      final announcement = await _repository.postAnnouncement(
        groupId,
        body.trim(),
      );
      state = state.copyWith(
        announcements: [announcement, ...state.announcements],
        isPostingAnnouncement: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isPostingAnnouncement: false,
        error: error.toString(),
      );
      return false;
    }
  }
}

final trainerGroupDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<TrainerGroupDetailController, TrainerGroupDetailState, String>(
      (ref, groupId) {
        return TrainerGroupDetailController(
          repository: ref.watch(trainerGroupsRepositoryProvider),
          groupId: groupId,
        );
      },
    );
