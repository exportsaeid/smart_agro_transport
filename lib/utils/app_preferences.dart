import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _keySender = 'backup_sender_email';
  static const String _keyAppPassword = 'backup_app_password';
  static const String _keyReceiver = 'backup_receiver_email';
  static const String _keyEnabled = 'backup_enabled';
  static const String _keyForcePasswordChange = 'force_password_change';
  static const String _keyLastUsername = 'last_username';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // ---------- ایمیل بکاپ ----------
  static Future<void> setBackupConfig(
      String sender,
      String appPassword,
      String receiver,
      ) async {
    final p = await _prefs;
    await p.setString(_keySender, sender.trim());
    await p.setString(_keyAppPassword, appPassword.trim());
    await p.setString(_keyReceiver, receiver.trim());
  }

  static Future<String> getBackupSender() async {
    final p = await _prefs;
    return p.getString(_keySender) ?? '';
  }

  static Future<String> getBackupAppPassword() async {
    final p = await _prefs;
    return p.getString(_keyAppPassword) ?? '';
  }

  static Future<String> getBackupReceiver() async {
    final p = await _prefs;
    return p.getString(_keyReceiver) ?? '';
  }

  static Future<bool> isBackupConfigValid() async {
    final sender = await getBackupSender();
    final password = await getBackupAppPassword();
    final receiver = await getBackupReceiver();
    return sender.isNotEmpty &&
        sender.contains('@') &&
        password.isNotEmpty &&
        receiver.isNotEmpty &&
        receiver.contains('@');
  }

  static Future<void> setBackupEnabled(bool enabled) async {
    final p = await _prefs;
    await p.setBool(_keyEnabled, enabled);
  }

  static Future<bool> isBackupEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyEnabled) ?? false;
  }

  static Future<void> clearBackupCredentials() async {
    final p = await _prefs;
    await p.remove(_keySender);
    await p.remove(_keyAppPassword);
    await p.remove(_keyReceiver);
  }

  // ---------- تغییر رمز ----------
  static Future<void> setForcePasswordChange(bool force) async {
    final p = await _prefs;
    await p.setBool(_keyForcePasswordChange, force);
  }

  static Future<bool> isForcePasswordChange() async {
    final p = await _prefs;
    return p.getBool(_keyForcePasswordChange) ?? false;
  }

  static Future<void> setLastUsername(String username) async {
    final p = await _prefs;
    await p.setString(_keyLastUsername, username);
  }

  static Future<String> getLastUsername() async {
    final p = await _prefs;
    return p.getString(_keyLastUsername) ?? '';
  }
}