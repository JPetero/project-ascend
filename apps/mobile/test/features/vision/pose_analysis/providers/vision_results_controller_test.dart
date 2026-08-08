import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vision/pose_analysis/presentation/providers/vision_results_controller.dart';

import '../../../../helpers/fake_vision_results_repository.dart';

void main() {
  group('VisionResultsController', () {
    test('loads sessions on construction', () async {
      final repository = FakeVisionResultsRepository()
        ..sessions.add(sampleVisionSession(id: 's1'));
      final controller = VisionResultsController(repository: repository);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, VisionResultsStatus.loaded);
      expect(controller.state.sessions, hasLength(1));
    });

    test('surfaces a list failure honestly instead of an empty list', () async {
      final repository = FakeVisionResultsRepository()..failList = true;
      final controller = VisionResultsController(repository: repository);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, VisionResultsStatus.error);
    });

    test('delete only removes the row after the server confirms it', () async {
      final repository = FakeVisionResultsRepository()
        ..sessions.add(sampleVisionSession(id: 's1'))
        ..sessions.add(sampleVisionSession(id: 's2'));
      final controller = VisionResultsController(repository: repository);
      await Future<void>.delayed(Duration.zero);

      await controller.delete('s1');

      expect(controller.state.sessions.map((s) => s.id), ['s2']);
      expect(repository.sessions.map((s) => s.id), ['s2']);
    });

    test(
      'a failed delete leaves the row in place and propagates the error',
      () async {
        final repository = FakeVisionResultsRepository()
          ..sessions.add(sampleVisionSession(id: 's1'))
          ..failDelete = true;
        final controller = VisionResultsController(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await expectLater(controller.delete('s1'), throwsException);
        expect(controller.state.sessions, hasLength(1));
      },
    );
  });
}
