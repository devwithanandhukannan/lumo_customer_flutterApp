import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _keyToken = 'access_token';
  static const _keyPhone = 'user_phone';
  static const _keyName = 'user_name';
  static const _keyUserId = 'user_id';
  static const _keyAuthenticated = 'is_authenticated';
  static const _keyEmail = 'user_email';
  static const _keyAge = 'user_age';
  static const _keySex = 'user_sex';
  static const _keyProfileComplete = 'profile_complete';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isAuthenticated => _prefs?.getBool(_keyAuthenticated) ?? false;
  static String? get authToken => _prefs?.getString(_keyToken);
  static String get userPhone => _prefs?.getString(_keyPhone) ?? '';
  static String get userName => _prefs?.getString(_keyName) ?? 'Customer';
  static String? get userId => _prefs?.getString(_keyUserId);
  static String get userEmail => _prefs?.getString(_keyEmail) ?? '';
  static int get age => _prefs?.getInt(_keyAge) ?? 0;
  static String get sex => _prefs?.getString(_keySex) ?? 'PREFER_NOT_TO_SAY';
  static bool get isProfileComplete => _prefs?.getBool(_keyProfileComplete) ?? false;

  static Future<void> setSession({
    required String token,
    required String phone,
    String name = 'Customer',
    String? userId,
    String? email,
    int? age,
    String? sex,
  }) async {
    await _prefs?.setBool(_keyAuthenticated, true);
    await _prefs?.setString(_keyToken, token);
    await _prefs?.setString(_keyPhone, phone);
    await _prefs?.setString(_keyName, name);
    if (userId != null) await _prefs?.setString(_keyUserId, userId);
    if (email != null) await _prefs?.setString(_keyEmail, email);
    if (age != null) await _prefs?.setInt(_keyAge, age);
    if (sex != null) await _prefs?.setString(_keySex, sex);
  }

  static Future<void> completeProfile({
    required String name,
    required int age,
    required String sex,
    String? email,
  }) async {
    await _prefs?.setString(_keyName, name);
    await _prefs?.setInt(_keyAge, age);
    await _prefs?.setString(_keySex, sex);
    if (email != null && email.isNotEmpty) await _prefs?.setString(_keyEmail, email);
    await _prefs?.setBool(_keyProfileComplete, true);
  }

  static const _keyAddress = 'user_address';
  static const _keyLat = 'user_lat';
  static const _keyLng = 'user_lng';

  static String get activeAddress => _prefs?.getString(_keyAddress) ?? 'Kochi, Kerala, India';
  static double get activeLat => _prefs?.getDouble(_keyLat) ?? 9.9312;
  static double get activeLng => _prefs?.getDouble(_keyLng) ?? 76.2673;

  static Future<void> setLocation(String address, double lat, double lng) async {
    await _prefs?.setString(_keyAddress, address);
    await _prefs?.setDouble(_keyLat, lat);
    await _prefs?.setDouble(_keyLng, lng);
  }

  static Future<void> clearSession() async {
    await _prefs?.clear();
  }
}
