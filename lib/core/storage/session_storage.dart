import 'package:shared_preferences/shared_preferences.dart';

/// Persistent session storage using shared_preferences
class SessionStorage {
  static const _keyToken = 'lumo_access_token';
  static const _keyPhone = 'lumo_user_phone';
  static const _keyName = 'lumo_user_name';
  static const _keyUserId = 'lumo_user_id';
  static const _keyAuthenticated = 'lumo_is_authenticated';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isAuthenticated => _prefs?.getBool(_keyAuthenticated) ?? false;
  static String? get authToken => _prefs?.getString(_keyToken);
  static String get userPhone => _prefs?.getString(_keyPhone) ?? '';
  static String get userName => _prefs?.getString(_keyName) ?? 'Customer';
  static String? get userId => _prefs?.getString(_keyUserId);

  static Future<void> setSession({
    required String token,
    required String phone,
    String name = 'Customer User',
    String? userId,
  }) async {
    await _prefs?.setBool(_keyAuthenticated, true);
    await _prefs?.setString(_keyToken, token);
    await _prefs?.setString(_keyPhone, phone);
    await _prefs?.setString(_keyName, name);
    if (userId != null) await _prefs?.setString(_keyUserId, userId);
  }

  static Future<void> clearSession() async {
    await _prefs?.clear();
  }
}
