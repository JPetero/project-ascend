import 'package:flutter/material.dart';

import '../../../profile/domain/preferences_model.dart';
import '../../domain/companion_animation_state.dart';
import 'companion_avatar.dart';
import 'companion_quick_actions_sheet.dart';

/// The floating companion entry point shown on the dashboard. Tapping it
/// opens [CompanionQuickActionsSheet].
class CompanionBubble extends StatelessWidget {
  const CompanionBubble({
    super.key,
    required this.companion,
    this.state = CompanionAnimationState.idle,
    this.reducedMotion = false,
  });

  final Companion companion;
  final CompanionAnimationState state;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Open ${companion == Companion.atlas ? 'Atlas' : 'Nova'} quick actions',
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => CompanionQuickActionsSheet.show(context),
        child: CompanionAvatar(
          companion: companion,
          state: state,
          size: 64,
          reducedMotion: reducedMotion,
        ),
      ),
    );
  }
}
