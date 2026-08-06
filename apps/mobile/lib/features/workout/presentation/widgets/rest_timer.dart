import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// A countdown shown after logging a set, before the next one. Calls
/// [onComplete] when it reaches zero and offers a "Skip rest" action to end
/// it early — both paths just remove this widget from the tree.
class RestTimer extends StatefulWidget {
  const RestTimer({
    super.key,
    required this.totalSeconds,
    required this.onComplete,
  });

  final int totalSeconds;
  final VoidCallback onComplete;

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remaining = widget.totalSeconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (_remaining <= 1) {
      timer.cancel();
      widget.onComplete();
      return;
    }
    setState(() => _remaining -= 1);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.totalSeconds == 0
        ? 0.0
        : 1 - (_remaining / widget.totalSeconds);

    return AscendCard(
      semanticLabel: 'Resting, $_remaining seconds remaining',
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: progress, strokeWidth: 3),
                Icon(
                  Icons.self_improvement,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rest', style: theme.textTheme.titleMedium),
                Text(
                  '$_remaining s remaining',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          AscendGhostButton(
            label: 'Skip',
            onPressed: () {
              _ticker?.cancel();
              widget.onComplete();
            },
          ),
        ],
      ),
    );
  }
}
