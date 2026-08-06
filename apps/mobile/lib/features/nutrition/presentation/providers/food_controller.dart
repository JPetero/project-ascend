import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/food_repository.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(apiClient: ref.watch(apiClientProvider));
});
