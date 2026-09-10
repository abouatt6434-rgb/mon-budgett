import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kTheme = 'theme_mode'; // system | light | dark
  static const _kCurrency = 'currency';
  static const _kNotifications = 'notifications_enabled';
  static const _kHideBalances = 'hide_balances';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kUserName = 'user_name';
  static const _kMonthlyBudget = 'monthly_budget';

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<String> getThemeMode() async =>
      (await _prefs).getString(_kTheme) ?? 'system';
  Future<void> setThemeMode(String mode) async =>
      (await _prefs).setString(_kTheme, mode);

  Future<String> getCurrency() async =>
      (await _prefs).getString(_kCurrency) ?? 'FCFA';
  Future<void> setCurrency(String currency) async =>
      (await _prefs).setString(_kCurrency, currency);

  Future<bool> getNotificationsEnabled() async =>
      (await _prefs).getBool(_kNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool value) async =>
      (await _prefs).setBool(_kNotifications, value);

  Future<bool> getHideBalances() async =>
      (await _prefs).getBool(_kHideBalances) ?? false;
  Future<void> setHideBalances(bool value) async =>
      (await _prefs).setBool(_kHideBalances, value);

  Future<bool> getOnboardingDone() async =>
      (await _prefs).getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) async =>
      (await _prefs).setBool(_kOnboardingDone, value);

  Future<String?> getUserName() async => (await _prefs).getString(_kUserName);
  Future<void> setUserName(String name) async =>
      (await _prefs).setString(_kUserName, name);

  Future<double?> getMonthlyBudget() async =>
      (await _prefs).getDouble(_kMonthlyBudget);
  Future<void> setMonthlyBudget(double amount) async =>
      (await _prefs).setDouble(_kMonthlyBudget, amount);

  Future<void> clearAll() async {
    final p = await _prefs;
    await p.clear();
  }
}
