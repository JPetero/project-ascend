import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_fixture.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(database: ref.watch(appDatabaseProvider));
});

final dashboardFutureProvider = FutureProvider.autoDispose<DashboardFixture?>((
  ref,
) async {
  final user = ref.watch(authControllerProvider.select((s) => s.user));
  if (user == null) return null;
  return ref.watch(dashboardRepositoryProvider).loadDashboard(user.id);
});
