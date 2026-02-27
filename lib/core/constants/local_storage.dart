import 'dart:convert';
import 'package:brokkerspot/models/login_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  /// Initialize in main()
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveAccessToken(String token) async {
    await _prefs?.setString("access_token", token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _prefs?.setString("refresh_token", token);
  }

  static String? getAccessToken() {
    return _prefs?.getString("access_token");
  }

  static String? getRefreshToken() {
    return _prefs?.getString("refresh_token");
  }

  static Future<void> removeTokens() async {
    await _prefs?.remove("access_token");
    await _prefs?.remove("refresh_token");
  }

  static Future<void> saveUser(LoginResponseModel model) async {
    String userJson = jsonEncode(model.toJson());
    await _prefs?.setString("user_data", userJson);
  }

  static LoginResponseModel? getUser() {
    String? userString = _prefs?.getString("user_data");
    if (userString == null) return null;

    return LoginResponseModel.fromJson(
      jsonDecode(userString),
    );
  }

  static Future<void> removeUser() async {
    await _prefs?.remove("user_data");
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  static bool isLoggedIn() {
    return getAccessToken() != null;
  }
}
