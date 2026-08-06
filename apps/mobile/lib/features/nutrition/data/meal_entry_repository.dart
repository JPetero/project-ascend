import '../../../core/networking/api_client.dart';
import '../../../core/sync/idempotency_key.dart';
import '../domain/meal_entry.dart';
import '../domain/meal_type.dart';

String formatDateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class MealEntryRepository {
  MealEntryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<MealEntry>> listForDate(DateTime date) async {
    final envelope = await _apiClient.get(
      '/nutrition-log',
      (data) => data as List<dynamic>,
      query: {'date': formatDateOnly(date)},
    );
    return (envelope.data ?? [])
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealEntry> addEntry({
    required String foodId,
    String? foodServingId,
    required MealType mealType,
    required DateTime date,
    required double quantity,
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/nutrition-log',
      (data) => data as Map<String, dynamic>,
      data: {
        'foodId': foodId,
        'foodServingId': ?foodServingId,
        'mealType': mealTypeToJson(mealType),
        'date': formatDateOnly(date),
        'quantity': quantity,
        'idempotencyKey':
            idempotencyKey ?? generateIdempotencyKey('meal-entry'),
      },
    );
    return MealEntry.fromJson(envelope.data!);
  }

  /// PATCH — naturally idempotent (applying the same absolute field values
  /// twice yields the same result), so unlike creates this never needs its
  /// own dedup key for offline-retry safety.
  Future<MealEntry> updateEntry(
    String id, {
    String? foodId,
    String? foodServingId,
    MealType? mealType,
    DateTime? date,
    double? quantity,
    String? notes,
  }) async {
    final envelope = await _apiClient.patch(
      '/nutrition-log/$id',
      (data) => data as Map<String, dynamic>,
      data: {
        'foodId': ?foodId,
        'foodServingId': ?foodServingId,
        if (mealType != null) 'mealType': mealTypeToJson(mealType),
        if (date != null) 'date': formatDateOnly(date),
        'quantity': ?quantity,
        'notes': ?notes,
      },
    );
    return MealEntry.fromJson(envelope.data!);
  }

  Future<void> deleteEntry(String id) async {
    await _apiClient.delete('/nutrition-log/$id', (_) => null);
  }

  Future<List<MealEntry>> copyEntries({
    required DateTime sourceDate,
    required DateTime targetDate,
    MealType? mealType,
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/nutrition-log/copy',
      (data) => data as List<dynamic>,
      data: {
        'sourceDate': formatDateOnly(sourceDate),
        'targetDate': formatDateOnly(targetDate),
        if (mealType != null) 'mealType': mealTypeToJson(mealType),
        'idempotencyKey':
            idempotencyKey ?? generateIdempotencyKey('meal-entry-copy'),
      },
    );
    return (envelope.data ?? [])
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
