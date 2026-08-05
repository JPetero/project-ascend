import 'package:flutter_test/flutter_test.dart';

/// A `pumpAndSettle()` substitute for widget trees that contain an
/// infinitely-repeating animation (e.g. the companion's idle bob), where
/// `pumpAndSettle()` would never terminate. Pumps a fixed number of frames
/// with real time advancement, which is enough for our async provider
/// chains (bootstrap, fake repository fetches) to resolve.
Future<void> pumpForAsyncSettle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
