import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const key = 'auth_token';
  static const userKey = 'auth_user';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, token);
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove(userKey);
  }
}
