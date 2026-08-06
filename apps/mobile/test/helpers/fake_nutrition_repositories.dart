import 'package:mobile/features/nutrition/data/food_repository.dart';
import 'package:mobile/features/nutrition/data/macro_target_repository.dart';
import 'package:mobile/features/nutrition/data/meal_entry_repository.dart';
import 'package:mobile/features/nutrition/data/nutrition_summary_repository.dart';
import 'package:mobile/features/nutrition/data/saved_meal_repository.dart';
import 'package:mobile/features/nutrition/data/water_repository.dart';
import 'package:mobile/features/nutrition/domain/food.dart';
import 'package:mobile/features/nutrition/domain/macro_target.dart';
import 'package:mobile/features/nutrition/domain/meal_entry.dart';
import 'package:mobile/features/nutrition/domain/meal_type.dart';
import 'package:mobile/features/nutrition/domain/nutrition_dashboard_summary.dart';
import 'package:mobile/features/nutrition/domain/saved_meal.dart';
import 'package:mobile/features/nutrition/domain/water_entry.dart';

const sampleNutritionDashboardSummary = NutritionDashboardSummary(
  proteinGrams: 42,
  proteinTargetGrams: 140,
  calorieTarget: 2200,
  calories: 850,
  hydrationMl: 750,
  hydrationTargetMl: 2500,
);

/// In-memory stand-in for the dashboard's nutrition summary call — avoids
/// hitting the network in widget tests the way the other Fake*Repository
/// classes do for their domains.
class FakeNutritionSummaryRepository implements NutritionSummaryRepository {
  FakeNutritionSummaryRepository({
    NutritionDashboardSummary? summary,
    this.shouldFail = false,
  }) : _summary = summary ?? sampleNutritionDashboardSummary;

  final NutritionDashboardSummary _summary;
  final bool shouldFail;

  @override
  Future<NutritionDashboardSummary> getTodaySummary() async {
    if (shouldFail) {
      throw Exception('network error');
    }
    return _summary;
  }
}

const sampleFood = Food(
  id: 'food-1',
  name: 'Cooked White Rice',
  isOwnedByCurrentUser: false,
  servingDescription: '1 cup cooked (158 g)',
  caloriesPerServing: 205,
  proteinGramsPerServing: 4.3,
  carbGramsPerServing: 44.5,
  fatGramsPerServing: 0.4,
  isEstimated: true,
);

/// In-memory stand-in for food search + custom food creation.
class FakeFoodRepository implements FoodRepository {
  FakeFoodRepository({List<Food>? seedFoods})
    : foods = List.of(seedFoods ?? [sampleFood]);

  final List<Food> foods;
  int _idCounter = 0;

  @override
  Future<List<Food>> search({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    if (search == null || search.isEmpty) return List.unmodifiable(foods);
    return foods
        .where((f) => f.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
  }

  @override
  Future<Food> createCustom(
    CustomFoodInput input, {
    String? idempotencyKey,
  }) async {
    final food = Food(
      id: 'custom-food-${_idCounter++}',
      name: input.name,
      isOwnedByCurrentUser: true,
      servingDescription: input.servingDescription,
      caloriesPerServing: input.caloriesPerServing,
      proteinGramsPerServing: input.proteinGramsPerServing,
      carbGramsPerServing: input.carbGramsPerServing,
      fatGramsPerServing: input.fatGramsPerServing,
      fiberGramsPerServing: input.fiberGramsPerServing,
      sodiumMgPerServing: input.sodiumMgPerServing,
      isEstimated: true,
    );
    foods.add(food);
    return food;
  }

  @override
  Future<Food> updateCustom(String id, CustomFoodInput input) async {
    final index = foods.indexWhere((f) => f.id == id);
    final food = Food(
      id: id,
      name: input.name,
      isOwnedByCurrentUser: true,
      servingDescription: input.servingDescription,
      caloriesPerServing: input.caloriesPerServing,
      proteinGramsPerServing: input.proteinGramsPerServing,
      carbGramsPerServing: input.carbGramsPerServing,
      fatGramsPerServing: input.fatGramsPerServing,
      fiberGramsPerServing: input.fiberGramsPerServing,
      sodiumMgPerServing: input.sodiumMgPerServing,
      isEstimated: true,
    );
    if (index >= 0) {
      foods[index] = food;
    } else {
      foods.add(food);
    }
    return food;
  }

  @override
  Future<Food> archiveCustom(String id) async {
    final index = foods.indexWhere((f) => f.id == id);
    final existing = foods[index];
    final archived = Food(
      id: existing.id,
      name: existing.name,
      alternateName: existing.alternateName,
      brand: existing.brand,
      isOwnedByCurrentUser: existing.isOwnedByCurrentUser,
      servingDescription: existing.servingDescription,
      servingGrams: existing.servingGrams,
      caloriesPerServing: existing.caloriesPerServing,
      proteinGramsPerServing: existing.proteinGramsPerServing,
      carbGramsPerServing: existing.carbGramsPerServing,
      fatGramsPerServing: existing.fatGramsPerServing,
      fiberGramsPerServing: existing.fiberGramsPerServing,
      sodiumMgPerServing: existing.sodiumMgPerServing,
      isEstimated: existing.isEstimated,
    );
    foods[index] = archived;
    return archived;
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// In-memory stand-in for meal-entry logging — resolves logged entries'
/// macro snapshot from [availableFoods] the same way the real backend
/// snapshots them from the `Food` row at log time.
class FakeMealEntryRepository implements MealEntryRepository {
  FakeMealEntryRepository({List<Food>? availableFoods})
    : _availableFoods = availableFoods ?? [sampleFood];

  final List<Food> _availableFoods;
  final List<MealEntry> _entries = [];
  int _idCounter = 0;

  @override
  Future<List<MealEntry>> listForDate(DateTime date) async {
    return _entries.where((e) => _isSameDay(e.date, date)).toList();
  }

  @override
  Future<MealEntry> addEntry({
    required String foodId,
    String? foodServingId,
    required MealType mealType,
    required DateTime date,
    required double quantity,
    String? idempotencyKey,
  }) async {
    final food = _availableFoods.firstWhere((f) => f.id == foodId);
    final entry = MealEntry(
      id: 'entry-${_idCounter++}',
      food: MealEntryFoodRef(
        id: food.id,
        name: food.name,
        isEstimated: food.isEstimated,
      ),
      mealType: mealType,
      date: date,
      quantity: quantity,
      calories: food.caloriesPerServing * quantity,
      proteinGrams: food.proteinGramsPerServing * quantity,
      carbGrams: food.carbGramsPerServing * quantity,
      fatGrams: food.fatGramsPerServing * quantity,
    );
    _entries.add(entry);
    return entry;
  }

  @override
  Future<MealEntry> updateEntry(
    String id, {
    String? foodId,
    String? foodServingId,
    MealType? mealType,
    DateTime? date,
    double? quantity,
    String? notes,
  }) async {
    final index = _entries.indexWhere((e) => e.id == id);
    final existing = _entries[index];
    final food = foodId == null
        ? null
        : _availableFoods.firstWhere((f) => f.id == foodId);
    final effectiveQuantity = quantity ?? existing.quantity;
    final updated = MealEntry(
      id: existing.id,
      food: food == null
          ? existing.food
          : MealEntryFoodRef(
              id: food.id,
              name: food.name,
              isEstimated: food.isEstimated,
            ),
      foodServing: existing.foodServing,
      mealType: mealType ?? existing.mealType,
      date: date ?? existing.date,
      quantity: effectiveQuantity,
      calories: food == null
          ? existing.calories
          : food.caloriesPerServing * effectiveQuantity,
      proteinGrams: food == null
          ? existing.proteinGrams
          : food.proteinGramsPerServing * effectiveQuantity,
      carbGrams: food == null
          ? existing.carbGrams
          : food.carbGramsPerServing * effectiveQuantity,
      fatGrams: food == null
          ? existing.fatGrams
          : food.fatGramsPerServing * effectiveQuantity,
      fiberGrams: existing.fiberGrams,
      notes: notes ?? existing.notes,
    );
    _entries[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<MealEntry>> copyEntries({
    required DateTime sourceDate,
    required DateTime targetDate,
    MealType? mealType,
    String? idempotencyKey,
  }) async {
    final toCopy = _entries.where(
      (e) =>
          _isSameDay(e.date, sourceDate) &&
          (mealType == null || e.mealType == mealType),
    );
    final copies = [
      for (final e in toCopy)
        MealEntry(
          id: 'entry-${_idCounter++}',
          food: e.food,
          foodServing: e.foodServing,
          mealType: e.mealType,
          date: targetDate,
          quantity: e.quantity,
          calories: e.calories,
          proteinGrams: e.proteinGrams,
          carbGrams: e.carbGrams,
          fatGrams: e.fatGrams,
          fiberGrams: e.fiberGrams,
        ),
    ];
    _entries.addAll(copies);
    return copies;
  }
}

/// In-memory stand-in for water logging.
class FakeWaterRepository implements WaterRepository {
  final List<WaterEntry> _entries = [];
  int _idCounter = 0;

  @override
  Future<DailyWater> getDaily(DateTime date) async {
    final entries = _entries.where((e) => _isSameDay(e.date, date)).toList();
    return DailyWater(
      totalMl: entries.fold(0, (sum, e) => sum + e.amountMl),
      entries: entries,
    );
  }

  @override
  Future<WaterEntry> addEntry({
    required DateTime date,
    required int amountMl,
    String? idempotencyKey,
  }) async {
    final entry = WaterEntry(
      id: 'water-${_idCounter++}',
      date: date,
      amountMl: amountMl,
      loggedAt: DateTime.now(),
    );
    _entries.add(entry);
    return entry;
  }

  @override
  Future<WaterEntry> updateEntry(String id, {required int amountMl}) async {
    final index = _entries.indexWhere((e) => e.id == id);
    final existing = _entries[index];
    final updated = WaterEntry(
      id: existing.id,
      date: existing.date,
      amountMl: amountMl,
      loggedAt: existing.loggedAt,
    );
    _entries[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}

/// In-memory stand-in for saved-meal logging — resolves logged items'
/// food snapshot from [availableFoods], same as [FakeMealEntryRepository].
///
/// [logMeal] writes through to [mealEntryRepository] (when supplied) the
/// same way the real `SavedMealsService` calls `NutritionLogService`, so a
/// logged saved meal actually shows up wherever `todaysMealEntriesProvider`
/// reads from in tests.
class FakeSavedMealRepository implements SavedMealRepository {
  FakeSavedMealRepository({
    List<Food>? availableFoods,
    FakeMealEntryRepository? mealEntryRepository,
  }) : _availableFoods = availableFoods ?? [sampleFood],
       _mealEntryRepository = mealEntryRepository;

  final List<Food> _availableFoods;
  final FakeMealEntryRepository? _mealEntryRepository;
  final List<SavedMeal> _savedMeals = [];
  int _idCounter = 0;

  @override
  Future<List<SavedMeal>> list() async => List.unmodifiable(_savedMeals);

  @override
  Future<SavedMeal> create({
    required String name,
    required List<SavedMealItemInput> items,
    String? idempotencyKey,
  }) async {
    final savedMeal = SavedMeal(
      id: 'saved-meal-${_idCounter++}',
      name: name,
      createdAt: DateTime.now(),
      items: items
          .map(
            (i) => SavedMealItem(
              id: 'saved-meal-item-${_idCounter++}',
              food: _availableFoods
                  .map(
                    (f) => MealEntryFoodRef(
                      id: f.id,
                      name: f.name,
                      isEstimated: f.isEstimated,
                    ),
                  )
                  .firstWhere((f) => f.id == i.foodId),
              quantity: i.quantity,
            ),
          )
          .toList(),
    );
    _savedMeals.add(savedMeal);
    return savedMeal;
  }

  @override
  Future<SavedMeal> update({
    required String id,
    String? name,
    List<SavedMealItemInput>? items,
  }) async {
    final index = _savedMeals.indexWhere((m) => m.id == id);
    final existing = _savedMeals[index];
    final updated = SavedMeal(
      id: existing.id,
      name: name ?? existing.name,
      createdAt: existing.createdAt,
      items: items == null
          ? existing.items
          : items
                .map(
                  (i) => SavedMealItem(
                    id: 'saved-meal-item-${_idCounter++}',
                    food: _availableFoods
                        .map(
                          (f) => MealEntryFoodRef(
                            id: f.id,
                            name: f.name,
                            isEstimated: f.isEstimated,
                          ),
                        )
                        .firstWhere((f) => f.id == i.foodId),
                    quantity: i.quantity,
                  ),
                )
                .toList(),
    );
    _savedMeals[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _savedMeals.removeWhere((m) => m.id == id);
  }

  @override
  Future<List<MealEntry>> logMeal({
    required String id,
    required MealType mealType,
    required DateTime date,
    String? idempotencyKey,
  }) async {
    final meal = _savedMeals.firstWhere((m) => m.id == id);
    final mealEntryRepository = _mealEntryRepository;
    if (mealEntryRepository != null) {
      return [
        for (final item in meal.items)
          await mealEntryRepository.addEntry(
            foodId: item.food.id,
            foodServingId: item.foodServing?.id,
            mealType: mealType,
            date: date,
            quantity: item.quantity,
          ),
      ];
    }
    return meal.items
        .map(
          (item) => MealEntry(
            id: 'entry-from-${item.id}',
            food: item.food,
            foodServing: item.foodServing,
            mealType: mealType,
            date: date,
            quantity: item.quantity,
            calories: 0,
            proteinGrams: 0,
            carbGrams: 0,
            fatGrams: 0,
          ),
        )
        .toList();
  }
}

final sampleMacroTarget = MacroTarget(
  calorieTarget: 2200,
  proteinGramsTarget: 140,
  carbGramsTarget: 220,
  fatGramsTarget: 70,
  fiberGramsTarget: 30,
  isEstimatedDefault: true,
  disclaimer:
      'This is a general estimate, not medical advice. If you are '
      'pregnant, managing an eating disorder, kidney disease, diabetes, '
      'or another condition affecting your nutrition needs, please set '
      'targets with guidance from a qualified professional.',
  updatedAt: DateTime.utc(2026, 1, 1),
);

/// In-memory stand-in for macro targets — `upsert` flips
/// `isEstimatedDefault` to false, matching the real backend's behavior.
class FakeMacroTargetRepository implements MacroTargetRepository {
  FakeMacroTargetRepository({MacroTarget? initial})
    : _current = initial ?? sampleMacroTarget;

  MacroTarget _current;
  final List<MacroTargetInput> upsertCalls = [];

  @override
  Future<MacroTarget> get() async => _current;

  @override
  Future<MacroTarget> upsert(MacroTargetInput input) async {
    upsertCalls.add(input);
    _current = MacroTarget(
      calorieTarget: input.calorieTarget,
      proteinGramsTarget: input.proteinGramsTarget,
      carbGramsTarget: input.carbGramsTarget,
      fatGramsTarget: input.fatGramsTarget,
      fiberGramsTarget: input.fiberGramsTarget,
      isEstimatedDefault: false,
      disclaimer: _current.disclaimer,
      updatedAt: DateTime.now(),
    );
    return _current;
  }
}
