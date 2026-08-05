import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/domain/companion_animation_state.dart';
import 'package:mobile/features/companion/presentation/widgets/companion_avatar.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

void main() {
  group('CompanionAvatar reduced motion', () {
    testWidgets('animates by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompanionAvatar(
              companion: Companion.atlas,
              state: CompanionAnimationState.idle,
            ),
          ),
        ),
      );
      // flutter_animate schedules its initial play via Future.delayed, even
      // with a zero delay — advance the fake clock so that timer actually
      // fires instead of leaking past the end of the test.
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byType(Animate), findsOneWidget);

      // The idle animation repeats forever, so unmount it explicitly rather
      // than pumpAndSettle-ing (which would never terminate) — this lets
      // its AnimationController dispose and cancel its pending timer
      // before the test binding checks for leaks.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('skips animation when reducedMotion is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompanionAvatar(
              companion: Companion.atlas,
              state: CompanionAnimationState.idle,
              reducedMotion: true,
            ),
          ),
        ),
      );

      expect(find.byType(Animate), findsNothing);
    });
  });
}
