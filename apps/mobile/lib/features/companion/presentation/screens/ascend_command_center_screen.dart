import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entitlements/capability.dart';
import '../../../../core/entitlements/capability_provider.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../domain/companion_dialogue.dart';
import '../../domain/companion_memory_note.dart';
import '../providers/companion_chat_controller.dart';
import '../providers/companion_voice_controller.dart';
import '../widgets/companion_avatar.dart';
import 'research_mode_screen.dart';

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

  Future<void> _showVoiceUpgradePrompt() async {
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice conversation is Premium'),
        content: const Text(
          'Talking to your companion out loud, and having replies read '
          'back to you, unlocks with Premium. Typed chat stays free.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('See Premium'),
          ),
        ],
      ),
    );
    if (upgrade == true && mounted) {
      context.push(RoutePaths.subscription);
    }
  }

  Future<void> _toggleListening(bool hasVoiceAccess) async {
    if (!hasVoiceAccess) {
      await _showVoiceUpgradePrompt();
      return;
    }
    final voiceController = ref.read(companionVoiceControllerProvider.notifier);
    final status = ref.read(companionVoiceControllerProvider).listeningStatus;
    if (status == VoiceListeningStatus.listening) {
      await voiceController.stopListening();
    } else {
      await voiceController.startListening();
    }
  }

  Future<void> _toggleSpeakReplies(bool hasVoiceAccess) async {
    if (!hasVoiceAccess) {
      await _showVoiceUpgradePrompt();
      return;
    }
    final voiceController = ref.read(companionVoiceControllerProvider.notifier);
    final enabled = ref
        .read(companionVoiceControllerProvider)
        .speakRepliesEnabled;
    voiceController.setSpeakRepliesEnabled(!enabled);
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
    final hasVoiceAccess = ref.watch(
      capabilityProvider(AppCapability.premiumCompanionVoices),
    );
    final voiceState = ref.watch(companionVoiceControllerProvider);
    final isListening =
        voiceState.listeningStatus == VoiceListeningStatus.listening;
    final isRequestingVoicePermission =
        voiceState.listeningStatus == VoiceListeningStatus.requestingPermission;

    return Scaffold(
      appBar: AppBar(
        title: Text(companion == Companion.atlas ? 'Atlas' : 'Nova'),
        actions: [
          IconButton(
            onPressed: () => _toggleSpeakReplies(hasVoiceAccess),
            icon: Icon(
              voiceState.speakRepliesEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
            tooltip: hasVoiceAccess
                ? (voiceState.speakRepliesEnabled
                      ? 'Stop speaking replies aloud'
                      : 'Speak replies aloud (Premium)')
                : 'Speak replies aloud (Premium)',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ResearchModeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Research mode',
          ),
          const NotificationBellAction(),
          const ProfileIconAction(),
        ],
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
            if (chatState.pendingMemory != null)
              _PendingMemoryBanner(
                companionName: companion == Companion.atlas ? 'Atlas' : 'Nova',
                candidate: chatState.pendingMemory!,
                onRemember: () => ref
                    .read(companionChatControllerProvider.notifier)
                    .confirmPendingMemory(),
                onNotNow: () => ref
                    .read(companionChatControllerProvider.notifier)
                    .dismissPendingMemory(),
              ),
            if (isListening || voiceState.isSpeaking)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AscendSpacing.md,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, size: 18),
                    const SizedBox(width: AscendSpacing.xs),
                    Expanded(
                      child: Text(
                        isListening
                            ? (voiceState.partialTranscript.isEmpty
                                  ? 'Listening…'
                                  : voiceState.partialTranscript)
                            : 'Speaking…',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (voiceState.isSpeaking)
                      TextButton(
                        onPressed: () => ref
                            .read(companionVoiceControllerProvider.notifier)
                            .stopSpeaking(),
                        child: const Text('Stop'),
                      ),
                  ],
                ),
              ),
            if (voiceState.listeningStatus == VoiceListeningStatus.unavailable)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AscendSpacing.md),
                child: Text(
                  "Ascend couldn't start voice recognition — check your "
                  "device's microphone/speech permission for Ascend and try "
                  'again.',
                  style: TextStyle(fontSize: 12),
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
                    onPressed: isRequestingVoicePermission
                        ? null
                        : () => _toggleListening(hasVoiceAccess),
                    icon: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    ),
                    tooltip: hasVoiceAccess
                        ? (isListening ? 'Stop listening' : 'Voice input')
                        : 'Voice input (Premium)',
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

/// Build Session 12 Part 4 — a non-blocking, explicit-consent prompt for
/// a SENSITIVE-category fact (accessibility/dietary info) the assistant
/// noticed but did not silently auto-save, even though memory is on.
/// Never a dialog/modal — sits inline above the composer so ignoring it
/// (sending another message) is a perfectly valid way to decline.
class _PendingMemoryBanner extends StatelessWidget {
  const _PendingMemoryBanner({
    required this.companionName,
    required this.candidate,
    required this.onRemember,
    required this.onNotNow,
  });

  final String companionName;
  final PendingCompanionMemory candidate;
  final VoidCallback onRemember;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AscendSpacing.md,
        vertical: AscendSpacing.xs,
      ),
      padding: const EdgeInsets.all(AscendSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AscendRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$companionName noticed something that could help personalize '
            'Ascend. Remember: "${candidate.value}"?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: AscendSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onNotNow, child: const Text('Not now')),
              const SizedBox(width: AscendSpacing.xs),
              FilledButton(
                onPressed: onRemember,
                child: const Text('Remember'),
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
