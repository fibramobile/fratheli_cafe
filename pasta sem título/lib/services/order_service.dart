import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class OrderService {
  static const String baseUrl = 'https://frathelicafe.com.br/api';
  static const String _coffeeSaleSyncUrl =
      'https://southamerica-east1-coffee-sale-fibramobile.cloudfunctions.net/createStorefrontSale';
  static const String _pendingSyncsKey = 'pending_coffee_sale_order_syncs';
  static const String _pendingCustomersKey =
      'pending_coffee_sale_order_customers';

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

    await _retryPendingFirebaseSyncs(token);

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
      if (code != null && code.isNotEmpty) {
        await _syncOrQueue(code, token, payload);
        return code;
      }
    }

    throw Exception('Resposta inválida do servidor (order.id não veio).');
  }

  static Future<String> createExternalOrder(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Usuário não autenticado');

    await _retryPendingFirebaseSyncs(token);

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

    await _syncOrQueue(code, token, payload);
    return code;
  }

  static Future<void> _syncOrQueue(
    String orderCode,
    String token,
    Map<String, dynamic> payload,
  ) async {
    final customer = _customerForSync(payload);

    try {
      await _syncOrderToCoffeeSale(
        orderCode,
        token,
        customer: customer,
      );
      await _removePendingSync(orderCode);
    } catch (error) {
      await _addPendingSync(orderCode, customer);
      debugPrint(
        '⚠️ Pedido $orderCode salvo na Hostinger, mas a sincronização com o '
        'Coffee Sale ficou pendente: $error',
      );
    }
  }

  static Future<void> _syncOrderToCoffeeSale(
    String orderCode,
    String token, {
    Map<String, dynamic>? customer,
  }) async {
    final response = await http
        .post(
          Uri.parse(_coffeeSaleSyncUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'orderId': orderCode,
            if (customer != null) 'customer': customer,
          }),
        )
        .timeout(const Duration(seconds: 25));

    final body = safeJson(response.body);

    debugPrint(
      '🔥 [CoffeeSaleSync] order=$orderCode status=${response.statusCode} '
      'body=$body',
    );

    if (response.statusCode != 200 || body['ok'] != true) {
      throw Exception(
        (body['error'] ?? 'Não foi possível sincronizar com o Firebase')
            .toString(),
      );
    }
  }

  static Future<void> retryPendingFirebaseSyncs() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return;
    await _retryPendingFirebaseSyncs(token);
  }

  static Future<void> _retryPendingFirebaseSyncs(String token) async {
    final pending = await _readPendingSyncs();
    final customers = await _readPendingCustomers();

    for (final orderCode in pending) {
      try {
        await _syncOrderToCoffeeSale(
          orderCode,
          token,
          customer: customers[orderCode],
        );
        await _removePendingSync(orderCode);
      } catch (error) {
        debugPrint(
          '⚠️ Sincronização pendente do pedido $orderCode ainda falhou: $error',
        );
      }
    }
  }

  static Future<List<String>> _readPendingSyncs() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_pendingSyncsKey);
    if (raw == null || raw.isEmpty) return <String>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>[];

      return decoded
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return <String>[];
    }
  }

  static Future<void> _addPendingSync(
    String orderCode,
    Map<String, dynamic> customer,
  ) async {
    final pending = (await _readPendingSyncs()).toSet()..add(orderCode);
    await _writePendingSyncs(pending);

    final customers = await _readPendingCustomers();
    customers[orderCode] = customer;
    await _writePendingCustomers(customers);
  }

  static Future<void> _removePendingSync(String orderCode) async {
    final pending = (await _readPendingSyncs()).toSet()..remove(orderCode);
    await _writePendingSyncs(pending);

    final customers = await _readPendingCustomers();
    customers.remove(orderCode);
    await _writePendingCustomers(customers);
  }

  static Future<void> _writePendingSyncs(Iterable<String> orderCodes) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _pendingSyncsKey,
      jsonEncode(orderCodes.toList()..sort()),
    );
  }

  static Map<String, dynamic> _customerForSync(
    Map<String, dynamic> payload,
  ) {
    final rawCustomer = payload['customer'];
    if (rawCustomer is! Map) return <String, dynamic>{};

    return {
      'name': rawCustomer['name']?.toString().trim() ?? '',
      'phone': rawCustomer['phone']?.toString().trim() ?? '',
      'cpf': rawCustomer['cpf']?.toString().trim() ?? '',
      'address': rawCustomer['address']?.toString().trim() ?? '',
      'cep': (rawCustomer['cep'] ?? payload['cep'])?.toString().trim() ?? '',
      'shipping': payload['shipping'] ?? 0,
      'shippingService': payload['shippingService']?.toString().trim() ?? '',
      'shippingDeadline':
          payload['shippingDeadline']?.toString().trim() ?? '',
    };
  }

  static Future<Map<String, Map<String, dynamic>>>
      _readPendingCustomers() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_pendingCustomersKey);
    if (raw == null || raw.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Map<String, dynamic>>{};

      return decoded.map((key, value) {
        final customer = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        return MapEntry(key.toString(), customer);
      });
    } catch (_) {
      return <String, Map<String, dynamic>>{};
    }
  }

  static Future<void> _writePendingCustomers(
    Map<String, Map<String, dynamic>> customers,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _pendingCustomersKey,
      jsonEncode(customers),
    );
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

    await _retryPendingFirebaseSyncs(token);

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
