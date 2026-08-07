import 'package:mobile/features/data_export/data/data_export_repository.dart';
import 'package:mobile/features/data_export/data/data_export_share_service.dart';

class FakeDataExportRepository implements DataExportRepository {
  FakeDataExportRepository({Map<String, dynamic>? exportToReturn, this.error})
    : exportToReturn =
          exportToReturn ??
          {
            'account': {'email': 'ada@example.com'},
          };

  Map<String, dynamic> exportToReturn;
  Object? error;

  @override
  Future<Map<String, dynamic>> fetchExport() async {
    if (error != null) throw error!;
    return exportToReturn;
  }
}

class FakeDataExportShareService implements DataExportShareService {
  Map<String, dynamic>? lastSharedExport;
  int shareCount = 0;

  @override
  Future<void> shareExport(Map<String, dynamic> export) async {
    lastSharedExport = export;
    shareCount++;
  }
}
