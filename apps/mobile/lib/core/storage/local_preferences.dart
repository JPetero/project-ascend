import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local settings only (theme choice, reduced-motion flag,
/// last-seen onboarding step). Never store tokens or health data here.
class LocalPreferences {
  LocalPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'ascend.theme_mode';
  static const _reducedMotionKey = 'ascend.reduced_motion';
  static const _onboardingCompletedKey = 'ascend.onboarding_completed';

  String? get themeMode => _prefs.getString(_themeModeKey);
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_themeModeKey, value);

  bool get reducedMotion => _prefs.getBool(_reducedMotionKey) ?? false;
  Future<void> setReducedMotion(bool value) =>
      _prefs.setBool(_reducedMotionKey, value);

  bool get onboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) ?? false;
  Future<void> setOnboardingCompleted(bool value) =>
      _prefs.setBool(_onboardingCompletedKey, value);

  Future<void> clear() async {
    await _prefs.remove(_onboardingCompletedKey);
  }
}
