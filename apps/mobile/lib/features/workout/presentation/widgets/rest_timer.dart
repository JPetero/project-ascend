import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// A countdown shown after logging a set, before the next one. Calls
/// [onComplete] when it reaches zero and offers a "Skip rest" action to end
/// it early — both paths just remove this widget from the tree.
///
/// The remaining time is always derived from wall-clock timestamps
/// (`clock.now().difference(_endAt)`), not from decrementing a counter once
/// per tick. A pure tick-counter breaks when the app is backgrounded —
/// Flutter's `Timer.periodic` does not fire while the app is suspended, so
/// a counter-based timer would silently pause and resume showing stale
/// time on return. Deriving from an absolute end time means the displayed
/// value is always correct the instant the widget rebuilds, regardless of
/// how many ticks were actually delivered while backgrounded. Uses
/// `package:clock`'s `clock.now()` rather than raw `DateTime.now()` so
/// widget tests can drive it through Flutter's fake-time test zone instead
/// of needing real wall-clock seconds to pass.
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
  // Deliberately not a `late final` field initializer: those evaluate
  // lazily on first *read*, which would be inside the first `_tick()` call
  // a full second after construction — silently shifting the whole
  // countdown a tick late. Setting it explicitly in `initState()` pins it
  // to the moment the timer actually starts.
  late DateTime _endAt;
  late int _remaining;
  Timer? _ticker;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _endAt = clock.now().add(Duration(seconds: widget.totalSeconds));
    _remaining = widget.totalSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remainingMs = _endAt.difference(clock.now()).inMilliseconds;
    // Rounds up rather than truncating: with truncation, a diff of e.g.
    // 999ms (a hair under a full second, from ordinary scheduling jitter)
    // would read as 0 and end the rest a tick early even though almost a
    // full second remained.
    final remaining = (remainingMs / 1000).ceil();
    if (remaining <= 0) {
      _finish();
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    _ticker?.cancel();
    widget.onComplete();
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
          AscendGhostButton(label: 'Skip', onPressed: _finish),
        ],
      ),
    );
  }
}
