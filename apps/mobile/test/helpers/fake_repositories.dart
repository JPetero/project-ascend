// Not using super parameters here on purpose: mixing them with the
// separately-stored `_tokenStorage` field (needed for logout/token
// manipulation) reads less clearly than the explicit forwarding below.
// ignore_for_file: use_super_parameters
import 'package:mobile/core/networking/api_client.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';
import 'package:mobile/features/profile/data/preferences_repository.dart';
import 'package:mobile/features/profile/data/profile_repository.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/wearables/data/device_repository.dart';
import 'package:mobile/features/wearables/domain/device_connection.dart';

/// In-memory test doubles for every repository, so widget tests never make
/// a real HTTP call. Each fake extends the real repository (rather than
/// implementing an interface) so provider overrides stay type-compatible
/// with the app's plain `Provider<Repository>` declarations.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({required SecureTokenStorage tokenStorage})
    : _tokenStorage = tokenStorage,
      super(
        apiClient: ApiClient(tokenStorage: tokenStorage),
        tokenStorage: tokenStorage,
      );

  final SecureTokenStorage _tokenStorage;
  bool loggedOutCalled = false;

  @override
  Future<AuthUser> register({
    required String firstName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async {
    await _tokenStorage.saveTokens(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh-id.secret',
    );
    return AuthUser(id: 'user-1', email: email);
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    await _tokenStorage.saveTokens(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh-id.secret',
    );
    return AuthUser(id: 'user-1', email: email);
  }

  @override
  Future<AuthUser> me() async =>
      const AuthUser(id: 'user-1', email: 'ada@example.com');

  @override
  Future<void> logout() async {
    loggedOutCalled = true;
    await _tokenStorage.clear();
  }
}

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository({
    required AppDatabase database,
    ProfileModel? initialProfile,
  }) : _profile = initialProfile ?? _defaultProfile,
       super(apiClient: _unusedApiClient(), database: database);

  static ProfileModel get _defaultProfile => const ProfileModel(
    firstName: 'Ada',
    languageCode: 'en',
    timezone: 'UTC',
    unitSystem: UnitSystem.metric,
    sexForCalculations: SexForCalculations.unspecified,
    onboardingCompleted: false,
    onboardingStep: 0,
  );

  ProfileModel _profile;

  @override
  Future<ProfileModel> fetchProfile(String userId) async => _profile;

  @override
  Future<ProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    _profile = _applyPatch(_profile, patch);
    return _profile;
  }

  @override
  Future<ProfileModel> updateOnboarding(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    _profile = _applyPatch(_profile, patch);
    return _profile;
  }

  ProfileModel _applyPatch(ProfileModel current, Map<String, dynamic> patch) {
    return ProfileModel(
      firstName: patch['firstName'] as String? ?? current.firstName,
      dateOfBirth: current.dateOfBirth,
      countryCode: patch['countryCode'] as String? ?? current.countryCode,
      languageCode: current.languageCode,
      timezone: current.timezone,
      unitSystem: current.unitSystem,
      sexForCalculations: patch['sexForCalculations'] == null
          ? current.sexForCalculations
          : sexForCalculationsFromJson(patch['sexForCalculations'] as String),
      heightCm: (patch['heightCm'] as num?)?.toDouble() ?? current.heightCm,
      weightKg: (patch['weightKg'] as num?)?.toDouble() ?? current.weightKg,
      primaryGoal: patch['primaryGoal'] as String? ?? current.primaryGoal,
      experienceLevel:
          patch['experienceLevel'] as String? ?? current.experienceLevel,
      onboardingCompleted:
          patch['onboardingCompleted'] as bool? ?? current.onboardingCompleted,
      onboardingStep: patch['onboardingStep'] as int? ?? current.onboardingStep,
      equipment: current.equipment,
      workoutSchedule: current.workoutSchedule,
    );
  }
}

class FakePreferencesRepository extends PreferencesRepository {
  FakePreferencesRepository({
    required AppDatabase database,
    PreferencesModel? initial,
  }) : _preferences = initial ?? _defaultPreferences,
       super(apiClient: _unusedApiClient(), database: database);

  static const _defaultPreferences = PreferencesModel(
    companion: Companion.atlas,
    companionMode: CompanionMode.standard,
    themeMode: AppThemeMode.system,
    reducedMotion: false,
    notificationsEnabled: true,
    aiMemoryEnabled: true,
  );

  PreferencesModel _preferences;

  @override
  Future<PreferencesModel> fetchPreferences(String userId) async =>
      _preferences;

  @override
  Future<PreferencesModel> updatePreferences(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    _preferences = _preferences.copyWith(
      companion: patch['companion'] == null
          ? null
          : companionFromJson(patch['companion'] as String),
      themeMode: patch['themeMode'] == null
          ? null
          : themeModeFromJson(patch['themeMode'] as String),
      reducedMotion: patch['reducedMotion'] as bool?,
      notificationsEnabled: patch['notificationsEnabled'] as bool?,
      aiMemoryEnabled: patch['aiMemoryEnabled'] as bool?,
    );
    return _preferences;
  }
}

class FakeDeviceRepository extends DeviceRepository {
  FakeDeviceRepository() : super(apiClient: _unusedApiClient());

  final List<DeviceConnection> _devices = [];
  int _idCounter = 0;

  @override
  Future<List<DeviceConnection>> list() async => List.unmodifiable(_devices);

  @override
  Future<DeviceConnection> connect({
    required String provider,
    required String displayName,
  }) async {
    final device = DeviceConnection(
      id: 'device-${_idCounter++}',
      provider: provider,
      displayName: displayName,
      status: DeviceConnectionStatus.connected,
    );
    _devices.add(device);
    return device;
  }

  @override
  Future<void> disconnect(String id) async {
    _devices.removeWhere((d) => d.id == id);
  }
}

ApiClient _unusedApiClient() {
  return ApiClient(tokenStorage: SecureTokenStorage());
}
