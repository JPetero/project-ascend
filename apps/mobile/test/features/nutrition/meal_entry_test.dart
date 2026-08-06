import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/domain/food.dart';
import 'package:mobile/features/nutrition/domain/meal_entry.dart';
import 'package:mobile/features/nutrition/domain/meal_type.dart';

void main() {
  group('MealEntry.fromJson', () {
    test('parses a full entry, including its food snapshot', () {
      final entry = MealEntry.fromJson({
        'id': 'entry-1',
        'food': {
          'id': 'food-1',
          'name': 'Cooked White Rice',
          'brand': null,
          'isEstimated': true,
        },
        'foodServing': null,
        'mealType': 'BREAKFAST',
        'date': '2026-08-06',
        'quantity': 1.5,
        'calories': 307.5,
        'proteinGrams': 6.45,
        'carbGrams': 66.75,
        'fatGrams': 0.6,
        'fiberGrams': null,
        'notes': null,
      });

      expect(entry.id, 'entry-1');
      expect(entry.food.name, 'Cooked White Rice');
      expect(entry.mealType, MealType.breakfast);
      expect(entry.quantity, 1.5);
      expect(entry.calories, 307.5);
    });
  });

  group('Food.fromJson', () {
    test('parses servings and estimated-value fields', () {
      final food = Food.fromJson({
        'id': 'food-1',
        'name': 'Carrot, Raw',
        'isOwnedByCurrentUser': false,
        'servingDescription': '1 medium (61 g)',
        'caloriesPerServing': 25,
        'proteinGramsPerServing': 0.6,
        'carbGramsPerServing': 5.8,
        'fatGramsPerServing': 0.1,
        'isEstimated': true,
        'servings': [
          {
            'id': 'serving-1',
            'label': '1 medium',
            'grams': 61,
            'isDefault': true,
          },
        ],
      });

      expect(food.name, 'Carrot, Raw');
      expect(food.servings, hasLength(1));
      expect(food.servings.first.isDefault, isTrue);
    });
  });

  group('mealTypeFromJson / mealTypeToJson', () {
    test('round-trips every meal type', () {
      for (final type in MealType.values) {
        expect(mealTypeFromJson(mealTypeToJson(type)), type);
      }
    });
  });
}
