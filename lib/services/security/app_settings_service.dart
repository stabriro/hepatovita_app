import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const _kNotificationsEnabled = 'notifications_enabled_v1';
  static const _kSmartReminderStampPrefix = 'smart_reminder_stamp_v1_';

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, enabled);
  }

  Future<String?> getSmartReminderStamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kSmartReminderStampPrefix$key');
  }

  Future<void> setSmartReminderStamp(String key, String stamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kSmartReminderStampPrefix$key', stamp);
  }
}
