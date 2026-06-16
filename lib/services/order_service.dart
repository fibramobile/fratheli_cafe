import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class OrderService {
  static Map<String, dynamic> safeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  static String _extractOrderCode(Map<String, dynamic> body) {
    final candidates = <dynamic>[
      body['orderCode'],
      body['orderId'],
      body['id'],
      body['order'] is Map ? body['order']['id'] : null,
      body['order'] is Map ? body['order']['order_code'] : null,
      body['order'] is Map ? body['order']['code'] : null,
      body['data'] is Map ? body['data']['orderId'] : null,
      body['data'] is Map ? body['data']['id'] : null,
    ];

    for (final value in candidates) {
      final code = value?.toString().trim() ?? '';
      if (code.isNotEmpty) return code;
    }

    throw Exception('Resposta inválida do servidor: código do pedido não veio.');
  }

  static Future<String> createOrder(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final sanitizedPayload = Map<String, dynamic>.from(payload);
    sanitizedPayload['paymentProvider'] ??= 'PIX_MANUAL';
    sanitizedPayload['paymentStatus'] ??= 'AGUARDANDO_PAGAMENTO';
    sanitizedPayload['shippingStatus'] ??= 'AGUARDANDO_PAGAMENTO';

    if (kDebugMode) {
      debugPrint('[OrderService.createOrder] POST ${AppConfig.orderCreate}');
      debugPrint('[OrderService.createOrder] payload=${jsonEncode(sanitizedPayload)}');
    }

    final res = await http
        .post(
          Uri.parse(AppConfig.orderCreate),
          headers: _authHeaders(token),
          body: jsonEncode(sanitizedPayload),
        )
        .timeout(const Duration(seconds: 25));

    final body = safeJson(res.body);

    if (kDebugMode) {
      debugPrint('[OrderService.createOrder] status=${res.statusCode} body=${res.body}');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Erro ao criar pedido').toString());
    }

    return _extractOrderCode(body);
  }

  static Future<String> createExternalOrder(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final res = await http
        .post(
          Uri.parse(AppConfig.orderCreateExternal),
          headers: _authHeaders(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Erro ao criar pedido externo').toString());
    }

    return _extractOrderCode(body);
  }

  static Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final uri = Uri.parse(AppConfig.orderGet).replace(queryParameters: {'id': orderId});
    final res = await http
        .get(uri, headers: _authHeaders(token))
        .timeout(const Duration(seconds: 20));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Falha ao buscar pedido').toString());
    }

    return body;
  }

  static Future<List<Map<String, dynamic>>> fetchMyOrders() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    final res = await http
        .get(Uri.parse(AppConfig.orderList), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 20));

    final body = safeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['error'] ?? 'Falha ao listar pedidos').toString());
    }

    final orders = body['orders'];
    if (orders is! List) return [];

    return orders
        .whereType<Map>()
        .map((order) => Map<String, dynamic>.from(order))
        .toList();
  }
}
