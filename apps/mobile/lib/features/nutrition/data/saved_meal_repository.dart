import '../../../core/networking/api_client.dart';
import '../../../core/sync/idempotency_key.dart';
import '../../achievements/domain/achievement.dart';
import '../domain/meal_entry.dart';
import '../domain/meal_type.dart';
import '../domain/saved_meal.dart';
import 'meal_entry_repository.dart' show formatDateOnly;

class SavedMealItemInput {
  const SavedMealItemInput({
    required this.foodId,
    this.foodServingId,
    required this.quantity,
  });

  final String foodId;
  final String? foodServingId;
  final double quantity;

  Map<String, dynamic> toJson() => {
    'foodId': foodId,
    'foodServingId': ?foodServingId,
    'quantity': quantity,
  };
}

class SavedMealRepository {
  SavedMealRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<SavedMeal>> list() async {
    final envelope = await _apiClient.get(
      '/saved-meals',
      (data) => data as List<dynamic>,
    );
    return (envelope.data ?? [])
        .map((m) => SavedMeal.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<SavedMeal> create({
    required String name,
    required List<SavedMealItemInput> items,
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/saved-meals',
      (data) => data as Map<String, dynamic>,
      data: {
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
        'idempotencyKey':
            idempotencyKey ?? generateIdempotencyKey('saved-meal'),
      },
    );
    return SavedMeal.fromJson(envelope.data!);
  }

  /// PATCH — replaces the name and/or the full item list, naturally
  /// idempotent for offline retry the same way `FoodRepository.updateCustom`
  /// is.
  Future<SavedMeal> update({
    required String id,
    String? name,
    List<SavedMealItemInput>? items,
  }) async {
    final envelope = await _apiClient.patch(
      '/saved-meals/$id',
      (data) => data as Map<String, dynamic>,
      data: {
        'name': ?name,
        if (items != null) 'items': items.map((i) => i.toJson()).toList(),
      },
    );
    return SavedMeal.fromJson(envelope.data!);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/saved-meals/$id', (_) => null);
  }

  Future<({List<MealEntry> entries, List<Achievement> newAchievements})>
  logMeal({
    required String id,
    required MealType mealType,
    required DateTime date,
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/saved-meals/$id/log',
      (data) => data as List<dynamic>,
      data: {
        'mealType': mealTypeToJson(mealType),
        'date': formatDateOnly(date),
        'idempotencyKey':
            idempotencyKey ?? generateIdempotencyKey('saved-meal-log'),
      },
    );
    final entries = (envelope.data ?? [])
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final newAchievements =
        (envelope.meta['newAchievements'] as List<dynamic>? ?? [])
            .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
            .toList();
    return (entries: entries, newAchievements: newAchievements);
  }
}
