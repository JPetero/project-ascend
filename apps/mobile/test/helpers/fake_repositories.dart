// Not using super parameters here on purpose: mixing them with the
// separately-stored `_tokenStorage` field (needed for logout/token
// manipulation) reads less clearly than the explicit forwarding below.
// ignore_for_file: use_super_parameters
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/core/networking/api_client.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/auth/data/auth_identity_repository.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_identity.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';
import 'package:mobile/features/auth/domain/device_session.dart';
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
  String? lastForgotPasswordEmail;
  String? lastResetPasswordToken;
  bool changePasswordCalled = false;
  bool resendVerificationCalled = false;
  bool signOutEverywhereCalled = false;
  String? lastDeleteAccountPassword;
  bool throwOnNextCall = false;
  List<DeviceSession> sessions = [
    DeviceSession(
      id: 'family-current',
      deviceName: 'Test Device',
      platform: 'ios',
      createdAt: DateTime(2026, 1, 1),
      lastUsedAt: DateTime(2026, 1, 2),
      current: true,
    ),
  ];
  bool revokeOtherSessionsCalled = false;
  String? lastRevokedSessionId;

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

  bool signInWithGoogleCalled = false;
  bool signInWithAppleCalled = false;
  String? lastSocialIdToken;
  String? lastSocialFirstName;

  @override
  Future<AuthUser> signInWithGoogle(String idToken) async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Google sign-in failed. Please try again.',
        code: 'UNKNOWN',
      );
    }
    signInWithGoogleCalled = true;
    lastSocialIdToken = idToken;
    await _tokenStorage.saveTokens(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh-id.secret',
    );
    return const AuthUser(id: 'user-1', email: 'social@example.com');
  }

  @override
  Future<AuthUser> signInWithApple(String idToken, {String? firstName}) async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Apple sign-in failed. Please try again.',
        code: 'UNKNOWN',
      );
    }
    signInWithAppleCalled = true;
    lastSocialIdToken = idToken;
    lastSocialFirstName = firstName;
    await _tokenStorage.saveTokens(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh-id.secret',
    );
    return const AuthUser(id: 'user-1', email: 'social@example.com');
  }

  @override
  Future<AuthUser> me() async =>
      const AuthUser(id: 'user-1', email: 'ada@example.com');

  @override
  Future<void> logout() async {
    loggedOutCalled = true;
    await _tokenStorage.clear();
  }

  @override
  Future<void> forgotPassword(String email) async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Something went wrong.',
        code: 'UNKNOWN',
      );
    }
    lastForgotPasswordEmail = email;
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'This reset link is invalid or has expired.',
        code: 'UNKNOWN',
      );
    }
    lastResetPasswordToken = token;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Current password is incorrect.',
        code: 'UNKNOWN',
      );
    }
    changePasswordCalled = true;
  }

  @override
  Future<void> verifyEmail(String token) async {}

  @override
  Future<void> resendVerification() async {
    resendVerificationCalled = true;
  }

  @override
  Future<void> logoutAllSessions() async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Something went wrong.',
        code: 'UNKNOWN',
      );
    }
    signOutEverywhereCalled = true;
    await _tokenStorage.clear();
  }

  @override
  Future<void> deleteAccount(String password) async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Current password is incorrect.',
        code: 'UNKNOWN',
      );
    }
    lastDeleteAccountPassword = password;
    await _tokenStorage.clear();
  }

  @override
  Future<List<DeviceSession>> getSessions() async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Could not load your devices.',
        code: 'UNKNOWN',
      );
    }
    return sessions;
  }

  @override
  Future<void> revokeSession(String familyId) async {
    if (throwOnNextCall) {
      throw const AppException(message: 'Session not found.', code: 'UNKNOWN');
    }
    lastRevokedSessionId = familyId;
    sessions = sessions.where((s) => s.id != familyId).toList();
  }

  @override
  Future<int> revokeOtherSessions() async {
    if (throwOnNextCall) {
      throw const AppException(
        message: 'Something went wrong.',
        code: 'UNKNOWN',
      );
    }
    revokeOtherSessionsCalled = true;
    final revokedCount = sessions.where((s) => !s.current).length;
    sessions = sessions.where((s) => s.current).toList();
    return revokedCount;
  }
}

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository({
    required AppDatabase database,
    ProfileModel? initialProfile,
    this.failFetch = false,
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

  /// When true, every [fetchProfile] call throws — used to exercise the
  /// Splash screen's "couldn't load your profile" retry/sign-out state.
  /// Flip it back to false (e.g. from a test's "Try again" tap) to let a
  /// subsequent fetch succeed.
  bool failFetch;

  @override
  Future<ProfileModel> fetchProfile(String userId) async {
    if (failFetch) {
      throw AppException(
        message: 'Unable to reach Ascend.',
        code: 'NETWORK_ERROR',
      );
    }
    return _profile;
  }

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
      conversationHistoryEnabled: patch['conversationHistoryEnabled'] as bool?,
      textScale: (patch['textScale'] as num?)?.toDouble(),
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

class FakeAuthIdentityRepository extends AuthIdentityRepository {
  FakeAuthIdentityRepository() : super(apiClient: _unusedApiClient());

  @override
  Future<List<AuthIdentity>> listMine() async => [
    AuthIdentity(
      provider: 'EMAIL',
      providerEmail: 'test@example.com',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
}

ApiClient _unusedApiClient() {
  return ApiClient(tokenStorage: SecureTokenStorage());
}
