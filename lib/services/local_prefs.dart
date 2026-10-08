import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Lightweight local storage for onboarding, theme, currency, and
/// local-mode persistence (NOT the primary DB when Firebase is configured).
class LocalPrefs {
  final SharedPreferences _prefs;
  LocalPrefs(this._prefs);

  static Future<LocalPrefs> load() async =>
      LocalPrefs(await SharedPreferences.getInstance());

  bool get onboardingDone =>
      _prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) =>
      _prefs.setBool(AppConstants.keyOnboardingDone, v);

  /// 'system' | 'light' | 'dark'
  String get themeMode => _prefs.getString(AppConstants.keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String v) =>
      _prefs.setString(AppConstants.keyThemeMode, v);

  String get currency => _prefs.getString(AppConstants.keyCurrency) ??
      AppConstants.defaultCurrency;
  Future<void> setCurrency(String v) =>
      _prefs.setString(AppConstants.keyCurrency, v);

  bool get notificationsEnabled =>
      _prefs.getBool(AppConstants.keyNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool(AppConstants.keyNotifications, v);

  // ---- local demo-mode auth persistence ----
  String? get demoUserId => _prefs.getString(AppConstants.keyDemoUserId);
  Future<void> setDemoUser(
      {required String uid, required String name, required String email}) async {
    await _prefs.setString(AppConstants.keyDemoUserId, uid);
    await _prefs.setString(AppConstants.keyDemoUserName, name);
    await _prefs.setString(AppConstants.keyDemoUserEmail, email);
  }

  Future<void> clearDemoUser() async {
    await _prefs.remove(AppConstants.keyDemoUserId);
    await _prefs.remove(AppConstants.keyDemoUserName);
    await _prefs.remove(AppConstants.keyDemoUserEmail);
  }

  String get demoUserName =>
      _prefs.getString(AppConstants.keyDemoUserName) ?? 'Demo User';
  String get demoUserEmail =>
      _prefs.getString(AppConstants.keyDemoUserEmail) ?? 'demo@spendwise.app';

  // ---- generic JSON blob storage for local-mode transactions/budgets ----
  String? readString(String key) => _prefs.getString(key);
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}
