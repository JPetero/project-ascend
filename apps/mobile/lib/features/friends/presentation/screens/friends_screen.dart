import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../community/domain/community_profile.dart';
import '../../../messages/presentation/providers/conversations_controller.dart';
import '../providers/friends_controller.dart';
import '../providers/user_search_controller.dart';

/// Real mutual friendships — Build Session 8 Part 7. Deliberately
/// separate from Community Follow: search for a member, send a
/// request, and once mutually accepted they show up here as a friend
/// (used later by Direct Messaging's "no message-request limit for
/// friends" rule and by friend-only joint workout invites).
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsControllerProvider);
    final requestCount = state.incoming.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Friends (${state.friends.length})'),
            Tab(
              text: requestCount > 0 ? 'Requests ($requestCount)' : 'Requests',
            ),
            const Tab(text: 'Find'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_FriendsTab(), _RequestsTab(), _FindTab()],
      ),
    );
  }
}

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsControllerProvider);
    final controller = ref.read(friendsControllerProvider.notifier);

    if (state.isLoading && state.friends.isEmpty) {
      return const AscendLoadingIndicator();
    }
    if (state.friends.isEmpty) {
      return const AscendEmptyState(
        icon: Icons.people_outline,
        title: 'No friends yet',
        message:
            'Use the Find tab to search for someone and send a friend request.',
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AscendSpacing.md),
        itemCount: state.friends.length,
        separatorBuilder: (_, _) => const SizedBox(height: AscendSpacing.sm),
        itemBuilder: (context, index) {
          final friend = state.friends[index];
          return AscendCard(
            child: Row(
              children: [
                _Avatar(profile: friend),
                const SizedBox(width: AscendSpacing.sm),
                Expanded(
                  child: Text(
                    friend.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Message',
                  onPressed: () =>
                      _openConversation(context, ref, friend.userId),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined),
                  tooltip: 'Remove friend',
                  onPressed: () => controller.removeFriend(friend.userId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsControllerProvider);
    final controller = ref.read(friendsControllerProvider.notifier);

    if (state.isLoading && state.incoming.isEmpty && state.outgoing.isEmpty) {
      return const AscendLoadingIndicator();
    }
    if (state.incoming.isEmpty && state.outgoing.isEmpty) {
      return const AscendEmptyState(
        icon: Icons.mail_outline,
        title: 'No pending requests',
        message: 'Requests you send or receive will show up here.',
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AscendSpacing.md),
        children: [
          if (state.incoming.isNotEmpty) ...[
            Text('Incoming', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AscendSpacing.sm),
            for (final request in state.incoming)
              Padding(
                padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                child: AscendCard(
                  child: Row(
                    children: [
                      const Expanded(child: Text('Friend request')),
                      TextButton(
                        onPressed: () => controller.declineRequest(request.id),
                        child: const Text('Decline'),
                      ),
                      FilledButton(
                        onPressed: () => controller.acceptRequest(request.id),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (state.outgoing.isNotEmpty) ...[
            const SizedBox(height: AscendSpacing.md),
            Text('Sent', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AscendSpacing.sm),
            for (final request in state.outgoing)
              Padding(
                padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                child: AscendCard(
                  child: Row(
                    children: [
                      const Expanded(child: Text('Pending')),
                      TextButton(
                        onPressed: () => controller.cancelRequest(request.id),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FindTab extends ConsumerStatefulWidget {
  const _FindTab();

  @override
  ConsumerState<_FindTab> createState() => _FindTabState();
}

class _FindTabState extends ConsumerState<_FindTab> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSearchControllerProvider);
    final searchController = ref.read(userSearchControllerProvider.notifier);
    final friendsState = ref.watch(friendsControllerProvider);
    final friendsController = ref.read(friendsControllerProvider.notifier);
    final myUserId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );

    return Padding(
      padding: const EdgeInsets.all(AscendSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AscendTextField(
            controller: _queryController,
            label: 'Search by name',
            onChanged: searchController.search,
          ),
          const SizedBox(height: AscendSpacing.md),
          if (state.isLoading)
            const Expanded(child: AscendLoadingIndicator())
          else if (state.hasSearched && state.results.isEmpty)
            const Expanded(
              child: AscendEmptyState(
                icon: Icons.search_off,
                title: 'No members found',
                message: 'Try a different name.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: state.results.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AscendSpacing.sm),
                itemBuilder: (context, index) {
                  final result = state.results[index];
                  final isFriend = friendsState.friends.any(
                    (f) => f.userId == result.userId,
                  );
                  final isSelf = result.userId == myUserId;
                  final hasOutgoing = friendsState.outgoing.any(
                    (r) => r.recipientId == result.userId,
                  );
                  return AscendCard(
                    child: Row(
                      children: [
                        _Avatar(profile: result),
                        const SizedBox(width: AscendSpacing.sm),
                        Expanded(child: Text(result.displayName)),
                        if (isSelf)
                          const SizedBox.shrink()
                        else if (isFriend)
                          const Chip(label: Text('Friends'))
                        else if (hasOutgoing)
                          const Chip(label: Text('Requested'))
                        else
                          FilledButton(
                            onPressed: () =>
                                friendsController.sendRequest(result.userId),
                            child: const Text('Add'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _openConversation(
  BuildContext context,
  WidgetRef ref,
  String friendUserId,
) async {
  final conversation = await ref
      .read(conversationsControllerProvider.notifier)
      .startConversation(friendUserId);
  if (!context.mounted) return;
  context.push(
    RoutePaths.conversationDetailPath(conversation.id),
    extra: friendUserId,
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final CommunityProfile profile;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: profile.avatarUrl != null
          ? NetworkImage(profile.avatarUrl!)
          : null,
      child: profile.avatarUrl == null
          ? const Icon(Icons.person_outline)
          : null,
    );
  }
}
