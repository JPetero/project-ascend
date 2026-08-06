import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/personal_record_repository.dart';
import '../../domain/personal_record.dart';

final personalRecordRepositoryProvider = Provider<PersonalRecordRepository>((
  ref,
) {
  return PersonalRecordRepository(apiClient: ref.watch(apiClientProvider));
});

final personalRecordsProvider =
    FutureProvider.autoDispose<List<PersonalRecord>>((ref) {
      return ref.watch(personalRecordRepositoryProvider).list();
    });
