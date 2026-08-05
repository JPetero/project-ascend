import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../domain/companion_animation_state.dart';

/// A polished placeholder vector avatar for Atlas or Nova. Not a proprietary
/// 3D asset — a gradient-and-icon abstraction that already supports every
/// animation state the future asset pipeline will need.
class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({
    super.key,
    required this.companion,
    this.state = CompanionAnimationState.idle,
    this.size = 96,
    this.reducedMotion = false,
  });

  final Companion companion;
  final CompanionAnimationState state;
  final double size;
  final bool reducedMotion;

  bool get _isAtlas => companion == Companion.atlas;

  List<Color> get _gradientColors => _isAtlas
      ? const [AscendColors.primaryCyan, Color(0xFF6366F1)]
      : const [Color(0xFFF472B6), AscendColors.primaryCyan];

  IconData get _icon {
    switch (state) {
      case CompanionAnimationState.listening:
        return Icons.hearing_rounded;
      case CompanionAnimationState.thinking:
        return Icons.psychology_alt_rounded;
      case CompanionAnimationState.talking:
        return Icons.chat_bubble_rounded;
      case CompanionAnimationState.celebrating:
        return Icons.celebration_rounded;
      case CompanionAnimationState.greeting:
        return Icons.waving_hand_rounded;
      case CompanionAnimationState.chibi:
        return Icons.emoji_emotions_rounded;
      case CompanionAnimationState.docked:
      case CompanionAnimationState.hidden:
      case CompanionAnimationState.idle:
        return _isAtlas ? Icons.shield_rounded : Icons.spa_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state == CompanionAnimationState.hidden) {
      return SizedBox(width: size, height: size);
    }

    final effectiveSize = state == CompanionAnimationState.chibi
        ? size * 0.6
        : size;

    Widget avatar = Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(_icon, color: Colors.white, size: effectiveSize * 0.42),
    );

    final label = '${_isAtlas ? 'Atlas' : 'Nova'}, ${state.name}';
    avatar = Semantics(label: label, image: true, child: avatar);

    if (reducedMotion) return avatar;

    switch (state) {
      case CompanionAnimationState.listening:
      case CompanionAnimationState.thinking:
        return avatar
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(end: 1.06, duration: 900.ms, curve: Curves.easeInOut);
      case CompanionAnimationState.celebrating:
        return avatar
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -8,
              duration: 400.ms,
              curve: Curves.easeInOut,
            );
      case CompanionAnimationState.greeting:
        return avatar
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8));
      case CompanionAnimationState.talking:
        return avatar
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(end: 1.03, duration: 350.ms);
      case CompanionAnimationState.idle:
      case CompanionAnimationState.docked:
      case CompanionAnimationState.chibi:
      case CompanionAnimationState.hidden:
        return avatar
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -4,
              duration: 2000.ms,
              curve: Curves.easeInOut,
            );
    }
  }
}
