import 'package:flutter/material.dart';
import '../services/order_service.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Future<Map<String, dynamic>>? _future;
  String? _orderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    // ✅ Aceita: arguments: "ord_..." OU arguments: {'id': 'ord_...'}
    if (args is String) {
      _orderId = args;
    } else if (args is Map && args['id'] != null) {
      _orderId = args['id'].toString();
    }

    final id = (_orderId ?? '').trim();
    if (id.isNotEmpty) {
      _future = OrderService.fetchOrder(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = (_orderId ?? '').trim();

    if (id.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Pedido inválido: ID não informado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Pedido $id')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Erro ao carregar pedido:\n${s.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = s.data ?? {};

          // ✅ Seu backend pode devolver:
          // 1) { "order": {...}, "items": [...] }
          // 2) { ...pedido... } (pedido direto)
          final order = (data['order'] is Map)
              ? (data['order'] as Map).cast<String, dynamic>()
              : data.cast<String, dynamic>();

          final itemsRaw = (data['items'] is List)
              ? (data['items'] as List)
              : (order['items'] is List ? (order['items'] as List) : const []);

          // Helpers
          String pickStr(Map o, List<String> keys, {String fallback = '-'}) {
            for (final k in keys) {
              final v = o[k];
              if (v == null) continue;
              final s = v.toString().trim();
              if (s.isNotEmpty) return s;
            }
            return fallback;
          }

          num pickNum(Map o, List<String> keys, {num fallback = 0}) {
            for (final k in keys) {
              final v = o[k];
              if (v == null) continue;
              if (v is num) return v;
              final parsed = num.tryParse(v.toString().replaceAll(',', '.'));
              if (parsed != null) return parsed;
            }
            return fallback;
          }

          final paymentStatus = pickStr(order, ['paymentStatus', 'payment_status']);
          final shippingStatus = pickStr(order, ['shippingStatus', 'shipping_status']);
          final shippingService = pickStr(order, ['shippingService', 'shipping_service'], fallback: '');
          final shippingDeadline = pickStr(order, ['shippingDeadline', 'shipping_deadline'], fallback: '');

          final subtotal = pickNum(order, ['subtotal']);
          final shipping = pickNum(order, ['shipping', 'freight']);
          final total = pickNum(order, ['total']);

          final headerCode = pickStr(order, ['order_code', 'id'], fallback: id);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  'Pedido #$headerCode',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                Text('Pagamento: $paymentStatus'),
                Text('Envio: $shippingStatus'),

                if (shippingService.isNotEmpty || shippingDeadline.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Frete: $shippingService${shippingDeadline.isNotEmpty ? " ($shippingDeadline)" : ""}',
                  ),
                ],

                const SizedBox(height: 10),
                Text('Subtotal: R\$ ${subtotal.toStringAsFixed(2)}'),
                Text('Frete: R\$ ${shipping.toStringAsFixed(2)}'),
                Text('Total: R\$ ${total.toStringAsFixed(2)}'),

                const Divider(height: 24),

                const Text('Itens', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),

                if (itemsRaw.isEmpty)
                  const Text('Nenhum item encontrado.')
                else
                  ...itemsRaw.map((it) {
                    final m = (it as Map).cast<String, dynamic>();

                    final name = (m['name'] ?? '').toString();
                    final qty = (m['qty'] ?? m['quantity'] ?? 0).toString();
                    final grind = (m['grind'] ?? '-').toString();

                    final lineTotal = pickNum(m, ['lineTotal', 'line_total', 'price', 'unitPrice', 'unit_price']);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name.isEmpty ? '-' : name),
                      subtitle: Text('Qtd: $qty  •  Moagem: $grind'),
                      trailing: Text('R\$ ${lineTotal.toStringAsFixed(2)}'),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
