import '../../../core/networking/api_client.dart';
import '../domain/food.dart';

class CustomFoodInput {
  const CustomFoodInput({
    required this.name,
    required this.servingDescription,
    required this.caloriesPerServing,
    required this.proteinGramsPerServing,
    required this.carbGramsPerServing,
    required this.fatGramsPerServing,
    this.fiberGramsPerServing,
    this.sodiumMgPerServing,
  });

  final String name;
  final String servingDescription;
  final double caloriesPerServing;
  final double proteinGramsPerServing;
  final double carbGramsPerServing;
  final double fatGramsPerServing;
  final double? fiberGramsPerServing;
  final double? sodiumMgPerServing;

  Map<String, dynamic> toJson() => {
    'name': name,
    'servingDescription': servingDescription,
    'caloriesPerServing': caloriesPerServing,
    'proteinGramsPerServing': proteinGramsPerServing,
    'carbGramsPerServing': carbGramsPerServing,
    'fatGramsPerServing': fatGramsPerServing,
    if (fiberGramsPerServing != null)
      'fiberGramsPerServing': fiberGramsPerServing,
    if (sodiumMgPerServing != null) 'sodiumMgPerServing': sodiumMgPerServing,
    'isEstimated': true,
  };
}

class FoodRepository {
  FoodRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Food>> search({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final envelope = await _apiClient.get(
      '/foods',
      (data) => data as Map<String, dynamic>,
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items.map((f) => Food.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<Food> createCustom(CustomFoodInput input) async {
    final envelope = await _apiClient.post(
      '/foods',
      (data) => data as Map<String, dynamic>,
      data: input.toJson(),
    );
    return Food.fromJson(envelope.data!);
  }
}
