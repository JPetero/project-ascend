import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/data_export/presentation/providers/data_export_controller.dart';

import '../../helpers/fake_data_export_repository.dart';

void main() {
  group('DataExportController', () {
    test('starts idle', () {
      final controller = DataExportController(
        repository: FakeDataExportRepository(),
        shareService: FakeDataExportShareService(),
      );
      addTearDown(controller.dispose);

      expect(controller.state.status, DataExportStatus.idle);
    });

    test('fetches the export and hands it to the share service', () async {
      final repository = FakeDataExportRepository(
        exportToReturn: {
          'account': {'email': 'ada@example.com'},
        },
      );
      final shareService = FakeDataExportShareService();
      final controller = DataExportController(
        repository: repository,
        shareService: shareService,
      );
      addTearDown(controller.dispose);

      await controller.exportAndShare();

      expect(controller.state.status, DataExportStatus.shared);
      expect(shareService.shareCount, 1);
      expect(shareService.lastSharedExport, repository.exportToReturn);
    });

    test('reports an error state when the fetch fails', () async {
      final controller = DataExportController(
        repository: FakeDataExportRepository(error: Exception('network down')),
        shareService: FakeDataExportShareService(),
      );
      addTearDown(controller.dispose);

      await controller.exportAndShare();

      expect(controller.state.status, DataExportStatus.error);
      expect(controller.state.errorMessage, contains('network down'));
    });

    test('reset returns to idle', () async {
      final controller = DataExportController(
        repository: FakeDataExportRepository(),
        shareService: FakeDataExportShareService(),
      );
      addTearDown(controller.dispose);
      await controller.exportAndShare();

      controller.reset();

      expect(controller.state.status, DataExportStatus.idle);
    });
  });
}
