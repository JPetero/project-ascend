import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/data_export_repository.dart';
import '../../data/data_export_share_service.dart';

final dataExportRepositoryProvider = Provider<DataExportRepository>((ref) {
  return DataExportRepository(apiClient: ref.watch(apiClientProvider));
});

final dataExportShareServiceProvider = Provider<DataExportShareService>((ref) {
  return const DefaultDataExportShareService();
});

enum DataExportStatus { idle, exporting, shared, error }

class DataExportState {
  const DataExportState({
    this.status = DataExportStatus.idle,
    this.errorMessage,
  });

  final DataExportStatus status;
  final String? errorMessage;

  DataExportState copyWith({DataExportStatus? status, String? errorMessage}) {
    return DataExportState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Drives the "export my data" flow — Build Session 8 Part 14. Fetches
/// the caller's own export from the backend, then hands it straight to
/// the OS share sheet; nothing is cached or written anywhere the app
/// itself can read back later.
class DataExportController extends StateNotifier<DataExportState> {
  DataExportController({
    required DataExportRepository repository,
    required DataExportShareService shareService,
  }) : _repository = repository,
       _shareService = shareService,
       super(const DataExportState());

  final DataExportRepository _repository;
  final DataExportShareService _shareService;

  Future<void> exportAndShare() async {
    state = state.copyWith(
      status: DataExportStatus.exporting,
      errorMessage: null,
    );
    try {
      final export = await _repository.fetchExport();
      await _shareService.shareExport(export);
      state = state.copyWith(status: DataExportStatus.shared);
    } catch (error) {
      state = state.copyWith(
        status: DataExportStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  void reset() {
    state = const DataExportState();
  }
}

final dataExportControllerProvider =
    StateNotifierProvider.autoDispose<DataExportController, DataExportState>((
      ref,
    ) {
      return DataExportController(
        repository: ref.watch(dataExportRepositoryProvider),
        shareService: ref.watch(dataExportShareServiceProvider),
      );
    });
