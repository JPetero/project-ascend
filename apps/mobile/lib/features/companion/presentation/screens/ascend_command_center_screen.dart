import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../domain/companion_dialogue.dart';
import '../providers/companion_chat_controller.dart';
import '../widgets/companion_avatar.dart';

const _quickCommands = [
  'Plan today\'s workout',
  'Log a meal',
  'How am I doing this week?',
  'I need some encouragement',
];

class AscendCommandCenterScreen extends ConsumerStatefulWidget {
  const AscendCommandCenterScreen({super.key});

  @override
  ConsumerState<AscendCommandCenterScreen> createState() =>
      _AscendCommandCenterScreenState();
}

class _AscendCommandCenterScreenState
    extends ConsumerState<AscendCommandCenterScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final message = text ?? _inputController.text;
    if (message.trim().isEmpty) return;
    _inputController.clear();
    await ref
        .read(companionChatControllerProvider.notifier)
        .sendMessage(message);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 50));
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companion = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.companion ?? Companion.atlas,
      ),
    );
    final coachingStyle = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.coachingStyle ?? CoachingStyle.balanced,
      ),
    );
    final reducedMotion = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.reducedMotion ?? false,
      ),
    );
    final chatState = ref.watch(companionChatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(companion == Companion.atlas ? 'Atlas' : 'Nova'),
        actions: const [ProfileIconAction()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AscendSpacing.md),
              child: CompanionAvatar(
                companion: companion,
                state: chatState.animationState,
                reducedMotion: reducedMotion,
              ),
            ),
            Expanded(
              child: chatState.messages.isEmpty
                  ? _EmptyChatState(
                      onQuickCommand: _send,
                      welcomeMessage: CompanionDialogue.welcome(
                        companion: companion,
                        style: coachingStyle,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AscendSpacing.md,
                      ),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatState.messages[index];
                        return _ChatBubble(
                          text: message.text,
                          isFromUser: message.isFromUser,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AscendSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AscendTextField(
                      label: 'Ask me anything',
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: AscendSpacing.sm),
                  IconButton.filled(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice input is coming soon.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic_none_rounded),
                    tooltip: 'Voice input (coming soon)',
                  ),
                  const SizedBox(width: AscendSpacing.xs),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.onQuickCommand,
    required this.welcomeMessage,
  });

  final ValueChanged<String> onQuickCommand;
  final String welcomeMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AscendSpacing.lg),
      child: Column(
        children: [
          Text(
            welcomeMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AscendSpacing.md),
          Wrap(
            spacing: AscendSpacing.sm,
            runSpacing: AscendSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              for (final command in _quickCommands)
                ActionChip(
                  label: Text(command),
                  onPressed: () => onQuickCommand(command),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isFromUser});

  final String text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: AscendSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AscendSpacing.md,
          vertical: AscendSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isFromUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AscendRadius.large),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isFromUser
                ? colorScheme.onPrimary
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}
