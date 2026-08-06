import '../../../core/networking/api_client.dart';
import '../domain/macro_target.dart';

class MacroTargetInput {
  const MacroTargetInput({
    required this.calorieTarget,
    required this.proteinGramsTarget,
    required this.carbGramsTarget,
    required this.fatGramsTarget,
    this.fiberGramsTarget,
  });

  final int calorieTarget;
  final int proteinGramsTarget;
  final int carbGramsTarget;
  final int fatGramsTarget;
  final int? fiberGramsTarget;

  Map<String, dynamic> toJson() => {
    'calorieTarget': calorieTarget,
    'proteinGramsTarget': proteinGramsTarget,
    'carbGramsTarget': carbGramsTarget,
    'fatGramsTarget': fatGramsTarget,
    'fiberGramsTarget': ?fiberGramsTarget,
  };
}

class MacroTargetRepository {
  MacroTargetRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<MacroTarget> get() async {
    final envelope = await _apiClient.get(
      '/macro-targets',
      (data) => data as Map<String, dynamic>,
    );
    return MacroTarget.fromJson(envelope.data!);
  }

  Future<MacroTarget> upsert(MacroTargetInput input) async {
    final envelope = await _apiClient.put(
      '/macro-targets',
      (data) => data as Map<String, dynamic>,
      data: input.toJson(),
    );
    return MacroTarget.fromJson(envelope.data!);
  }
}
