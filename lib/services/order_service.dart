import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrderService {
  static const String baseUrl = 'https://frathelicafe.com.br/api';

  static Map<String, dynamic> safeJson(String raw) {
    try {
      final d = jsonDecode(raw);
      return d is Map<String, dynamic> ? d : {};
    } catch (_) {
      return {};
    }
  }
/*
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    // ✅ CONFIRME A ROTA AQUI:
    // Se seu PHP é /orders/creater.php, use isso.
    final uri = Uri.parse('$baseUrl/orders/create.php'); // <- ajuste aqui

    debugPrint('🧾 [createOrder] POST => $uri');
    debugPrint('🧾 [createOrder] token? ${token.isNotEmpty} (len=${token.length})');
    debugPrint('🧾 [createOrder] payload => ${jsonEncode(payload)}');

    http.Response res;
    try {
      res = await http
          .post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('❌ [createOrder] exception on POST: $e');
      rethrow;
    }

    debugPrint('🧾 [createOrder] status=${res.statusCode}');
    debugPrint('🧾 [createOrder] headers=${res.headers}');
    debugPrint('🧾 [createOrder] rawBody=${res.body}');

    final body = safeJson(res.body);
    debugPrint('🧾 [createOrder] parsedBody=$body');

    if (res.statusCode != 200) {
      throw Exception((body['error'] ?? 'Erro ao criar pedido').toString());
    }

    return body;
  }
*/
  static Future<String> createOrder(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final uri = Uri.parse('$baseUrl/orders/create.php');

    debugPrint('🧾 [OrderService.createOrder] POST => $uri');
    debugPrint('🧾 [OrderService.createOrder] token? ${token.isNotEmpty} (len=${token.length})');
    debugPrint('🧾 [OrderService.createOrder] payload => ${jsonEncode(payload)}');

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 20));

    debugPrint('🧾 [OrderService.createOrder] status=${res.statusCode}');
    debugPrint('🧾 [OrderService.createOrder] rawBody=${res.body}');

    final body = safeJson(res.body);

    if (res.statusCode != 200) {
      throw Exception((body['error'] ?? 'Erro ao criar pedido').toString());
    }

    // Esperado: {"ok":true,"order":{"db_id":11,"id":"ord_..."}}
    if (body['ok'] == true) {
      final code = body['order']?['id']?.toString();
      if (code != null && code.isNotEmpty) return code;
    }

    throw Exception('Resposta inválida do servidor (order.id não veio).');
  }

  static Future<String> createExternalOrder(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final uri = Uri.parse('$baseUrl/orders/create_external.php');

    debugPrint('🧾 [createExternalOrder] POST => $uri');
    debugPrint('🧾 [createExternalOrder] payload => ${jsonEncode(payload)}');

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    debugPrint('🧾 [createExternalOrder] status=${res.statusCode}');
    debugPrint('🧾 [createExternalOrder] rawBody=${res.body}');

    final body = safeJson(res.body);
    if (res.statusCode != 200) {
      throw Exception((body['error'] ?? 'Erro no servidor').toString());
    }

    final code = (body['order']?['id'] ?? '').toString();
    if (code.isEmpty) throw Exception('Resposta inválida do servidor (order.id vazio).');
    return code;
  }

  static Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    final uri = Uri.parse('$baseUrl/orders/get.php?id=$orderId');

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    });

    final body = safeJson(res.body);

    if (res.statusCode != 200) {
      throw Exception((body['error'] ?? 'Falha ao buscar pedido').toString());
    }

    return body;
  }

  static Future<List<Map<String, dynamic>>> fetchMyOrders() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Usuário não autenticado');

    final uri = Uri.parse('$baseUrl/orders/list.php');

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    });

    final body = safeJson(res.body);
    if (res.statusCode != 200) {
      throw Exception((body['error'] ?? 'Falha ao listar pedidos').toString());
    }

    final list = body['orders'];
    if (list is List) {
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }

}
