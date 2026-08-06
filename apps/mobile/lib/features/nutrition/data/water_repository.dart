import '../../../core/networking/api_client.dart';
import '../../../core/sync/idempotency_key.dart';
import '../domain/water_entry.dart';
import 'meal_entry_repository.dart' show formatDateOnly;

class DailyWater {
  const DailyWater({required this.totalMl, required this.entries});

  final int totalMl;
  final List<WaterEntry> entries;
}

class WaterRepository {
  WaterRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<DailyWater> getDaily(DateTime date) async {
    final envelope = await _apiClient.get(
      '/water',
      (data) => data as Map<String, dynamic>,
      query: {'date': formatDateOnly(date)},
    );
    final body = envelope.data!;
    final entries = (body['entries'] as List<dynamic>)
        .map((e) => WaterEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return DailyWater(totalMl: body['totalMl'] as int, entries: entries);
  }

  Future<WaterEntry> addEntry({
    required DateTime date,
    required int amountMl,
  }) async {
    final envelope = await _apiClient.post(
      '/water',
      (data) => data as Map<String, dynamic>,
      data: {
        'date': formatDateOnly(date),
        'amountMl': amountMl,
        'idempotencyKey': generateIdempotencyKey('water-entry'),
      },
    );
    return WaterEntry.fromJson(envelope.data!);
  }

  Future<void> deleteEntry(String id) async {
    await _apiClient.delete('/water/$id', (_) => null);
  }
}
