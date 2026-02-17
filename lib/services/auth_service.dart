import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ✅ Ajuste para o seu domínio/endpoint
  static const String baseUrl = 'https://frathelicafe.com.br/api';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login.php');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final body = _safeJson(res.body);

    if (res.statusCode != 200) {
      final msg = (body['error'] ?? 'Falha no login').toString();
      throw Exception(msg);
    }

    // Espera: { token: "...", user: { id, name, email } }
    final token = body['token']?.toString();
    final user = body['user'];

    if (token == null || token.isEmpty || user == null) {
      throw Exception('Resposta inválida do servidor.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user));

    return {
      'token': token,
      'user': user,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auth_user');
    if (raw == null) return null;
    return _safeJson(raw);
  }

  static Map<String, dynamic> _safeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? whatsapp,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register.php');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'whatsapp': (whatsapp ?? '').trim(),
      }),
    );

    // ✅ DEBUG (mostra o erro real)
    debugPrint('REGISTER status: ${res.statusCode}');
    debugPrint('REGISTER raw body: ${res.body}');

    final body = _safeJson(res.body);

    if (res.statusCode != 200) {
      final msg = (body['error'] ?? 'Falha no cadastro').toString();
      throw Exception(msg);
    }

    final token = body['token']?.toString();
    final user = body['user'];

    if (token == null || token.isEmpty || user == null) {
      throw Exception('Resposta inválida do servidor.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user));

    return {'token': token, 'user': user};
  }


  static Future<Map<String, dynamic>> fetchMyAccount() async {
    final token = await getToken();
    if (token == null) throw Exception('Não autenticado');

    final uri = Uri.parse('$baseUrl/account/me.php');

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(body['error'] ?? 'Erro ao buscar conta');
    }

    return body;
  }



}
