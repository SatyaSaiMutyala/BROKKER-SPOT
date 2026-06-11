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

  // Save which side user last logged out from ('user' or 'broker')
  static Future<void> saveLastSide(String side) async {
    await _prefs?.setString("last_side", side);
  }

  static String getLastSide() {
    return _prefs?.getString("last_side") ?? 'user';
  }

  static Future<void> clearAll() async {
    // Preserve last_side across logout
    final lastSide = getLastSide();
    await _prefs?.clear();
    await saveLastSide(lastSide);
  }

  static bool isLoggedIn() {
    return getAccessToken() != null;
  }

  /// Decodes the stored JWT access token and returns the user ID from the
  /// payload. This is more reliable than getUser()?.data?.id after an account
  /// switch because it reads the live token, not potentially-stale saved data.
  ///
  /// The server encodes the user id as "id" in the token payload.
  static String? getUserIdFromToken() {
    final token = getAccessToken() ?? '';
    if (token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
        default: break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      return data['id']?.toString() ??
          data['_id']?.toString() ??
          data['sub']?.toString();
    } catch (_) {
      return null;
    }
  }
}
