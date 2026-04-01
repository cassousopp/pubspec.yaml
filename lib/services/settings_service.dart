import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kThemeMode = 'theme_mode'; // system|light|dark
  static const _kPushNotificationsEnabled = 'push_notifications_enabled';
  static const _kAlertSoundEnabled = 'alert_sound_enabled';
  static const _kMotionSensitivity = 'motion_sensitivity'; // 0..2
  static const _kAutoArmEnabled = 'auto_arm_enabled';
  static const _kBatterySaverEnabled = 'battery_saver_enabled';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<String> getThemeMode() async {
    final p = await _prefs();
    return p.getString(_kThemeMode) ?? 'dark';
  }

  static Future<void> setThemeMode(String value) async {
    final p = await _prefs();
    await p.setString(_kThemeMode, value);
  }

  static Future<bool> getPushNotificationsEnabled() async {
    final p = await _prefs();
    return p.getBool(_kPushNotificationsEnabled) ?? true;
  }

  static Future<void> setPushNotificationsEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kPushNotificationsEnabled, v);
  }

  static Future<bool> getAlertSoundEnabled() async {
    final p = await _prefs();
    return p.getBool(_kAlertSoundEnabled) ?? true;
  }

  static Future<void> setAlertSoundEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kAlertSoundEnabled, v);
  }

  static Future<int> getMotionSensitivity() async {
    final p = await _prefs();
    return p.getInt(_kMotionSensitivity) ?? 1;
  }

  static Future<void> setMotionSensitivity(int v) async {
    final p = await _prefs();
    await p.setInt(_kMotionSensitivity, v.clamp(0, 2));
  }

  static Future<bool> getAutoArmEnabled() async {
    final p = await _prefs();
    return p.getBool(_kAutoArmEnabled) ?? true;
  }

  static Future<void> setAutoArmEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kAutoArmEnabled, v);
  }

  static Future<bool> getBatterySaverEnabled() async {
    final p = await _prefs();
    return p.getBool(_kBatterySaverEnabled) ?? false;
  }

  static Future<void> setBatterySaverEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kBatterySaverEnabled, v);
  }
}

