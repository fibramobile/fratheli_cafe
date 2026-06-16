import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Map<String, dynamic> safeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.login),
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    return _handleAuthResponse(res, defaultError: 'Falha no login');
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? whatsapp,
  }) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.register),
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
            'whatsapp': (whatsapp ?? '').trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    return _handleAuthResponse(res, defaultError: 'Falha no cadastro');
  }

  static Future<Map<String, dynamic>> _handleAuthResponse(
    http.Response res, {
    required String defaultError,
  }) async {
    if (kDebugMode) {
      debugPrint('[AuthService] status=${res.statusCode} body=${res.body}');
    }

    final body = safeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? defaultError).toString());
    }

    final token = body['token']?.toString();
    final rawUser = body['user'];

    if (token == null || token.isEmpty || rawUser is! Map) {
      throw Exception('Resposta inválida do servidor.');
    }

    final user = Map<String, dynamic>.from(rawUser);
    user['role'] = (user['role'] ?? 'user').toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));

    return {'token': token, 'user': user};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    final parsed = safeJson(raw);
    return parsed.isEmpty ? null : parsed;
  }

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  static Future<Map<String, dynamic>> fetchMyAccount() async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final res = await http
        .get(Uri.parse(AppConfig.accountMe), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 20));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Falha ao buscar conta').toString());
    }

    final user = body['user'];
    if (user is Map) {
      final prefs = await SharedPreferences.getInstance();
      final normalized = Map<String, dynamic>.from(user);
      normalized['role'] = (normalized['role'] ?? 'user').toString();
      await prefs.setString(_userKey, jsonEncode(normalized));
    }

    return body;
  }

  static Future<Map<String, dynamic>?> fetchClientProfile() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    final res = await http
        .get(Uri.parse(AppConfig.profileGet), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 20));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) return null;

    final profile = body['profile'];
    return profile is Map ? Map<String, dynamic>.from(profile) : null;
  }

  static Future<void> upsertClientProfile({
    required String cpf,
    required String phone,
    required Map<String, dynamic> address,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final res = await http
        .post(
          Uri.parse(AppConfig.profileUpsert),
          headers: _authHeaders(token),
          body: jsonEncode({
            'cpf': cpf,
            'phone': phone,
            'address': address,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Falha ao salvar perfil').toString());
    }
  }

  static Future<String> getRole() async {
    try {
      final me = await fetchMyAccount();
      final role = (me['user']?['role'] ?? '').toString().trim();
      if (role.isNotEmpty) return role;
    } catch (_) {}

    final user = await getUser();
    return (user?['role'] ?? 'user').toString();
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role.toLowerCase() == 'admin';
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final res = await http
        .post(
          Uri.parse(AppConfig.changePassword),
          headers: _authHeaders(token),
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Falha ao alterar senha').toString());
    }
  }

  static Future<void> updateBasicUser({required String name}) async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final res = await http
        .post(
          Uri.parse(AppConfig.updateUser),
          headers: _authHeaders(token),
          body: jsonEncode({'name': name.trim()}),
        )
        .timeout(const Duration(seconds: 20));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Falha ao atualizar usuário').toString());
    }

    final prefs = await SharedPreferences.getInstance();
    final currentUser = await getUser() ?? {};
    currentUser['name'] = name.trim();
    await prefs.setString(_userKey, jsonEncode(currentUser));
  }
}
