import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../theme/fratheli_colors.dart';

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

  // ---------------- helpers ----------------

  String brl(num v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  num parseNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse((v ?? '0').toString().replaceAll(',', '.')) ?? 0;
  }

  String formatDt(String raw) {
    // "2026-02-21 18:00:29" -> "21/02/2026 • 18:00"
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} • ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return raw;
    }
  }

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

  ({String label, Color bg, Color fg, IconData icon}) statusStyle(String s) {
    final up = s.toUpperCase().trim();

    if (up.contains('PAGO') || up.contains('APROV')) {
      return (
      label: 'Pago',
      bg: FratheliColors.green.withOpacity(0.12),
      fg: FratheliColors.green,
      icon: Icons.check_circle,
      );
    }
    if (up.contains('CANCEL') || up.contains('REJEIT')) {
      return (
      label: 'Cancelado',
      bg: FratheliColors.danger.withOpacity(0.10),
      fg: FratheliColors.danger,
      icon: Icons.cancel,
      );
    }
    if (up.contains('ENVI') || up.contains('POST')) {
      return (
      label: 'Enviado',
      bg: FratheliColors.gold.withOpacity(0.14),
      fg: FratheliColors.gold2,
      icon: Icons.local_shipping,
      );
    }
    return (
    label: 'Aguardando pagamento',
    bg: FratheliColors.gold.withOpacity(0.12),
    fg: FratheliColors.gold2,
    icon: Icons.schedule,
    );
  }

  Widget pill(String label, IconData icon, Color bgC, Color fgC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgC,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fgC.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgC),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fgC,
            ),
          ),
        ],
      ),
    );
  }

  Widget card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Material(
      color: FratheliColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FratheliColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: child,
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final id = (_orderId ?? '').trim();
    final w = MediaQuery.of(context).size.width;

    final bool isWide = kIsWeb && w >= 900;
    final double maxWidth = 1040;
    final double sidePad = isWide ? 24 : 16;

    if (id.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Pedido inválido: ID não informado.')),
      );
    }

    return Scaffold(
      backgroundColor: FratheliColors.bg,
      appBar: AppBar(
        backgroundColor: FratheliColors.bg,
        elevation: 0,
        foregroundColor: FratheliColors.text,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            color: FratheliColors.gold.withOpacity(0.5),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/img/logo_escuro.png', width: 30, height: 30),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                children: [
                  TextSpan(
                    text: 'FRATHÉLI ',
                    style: TextStyle(color: FratheliColors.brown),
                  ),
                  TextSpan(
                    text: 'CAFÉ',
                    style: TextStyle(color: FratheliColors.gold2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? maxWidth : double.infinity,
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (s.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Não foi possível carregar seu pedido.\n${s.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FratheliColors.textMuted),
                    ),
                  ),
                );
              }

              final data = s.data ?? {};

              // 1) { "order": {...}, "items": [...] }
              // 2) { ...pedido... }
              final order = (data['order'] is Map)
                  ? (data['order'] as Map).cast<String, dynamic>()
                  : data.cast<String, dynamic>();

              final itemsRaw = (data['items'] is List)
                  ? (data['items'] as List)
                  : (order['items'] is List ? (order['items'] as List) : const []);

              final headerCode = pickStr(order, ['order_code', 'id'], fallback: id);

              final paymentStatus = pickStr(order, ['paymentStatus', 'payment_status']);
              final shippingStatus = pickStr(order, ['shippingStatus', 'shipping_status']);

              final shippingService =
              pickStr(order, ['shippingService', 'shipping_service'], fallback: '');
              final shippingDeadline =
              pickStr(order, ['shippingDeadline', 'shipping_deadline'], fallback: '');

              final createdAt = pickStr(order, ['created_at', 'createdAt'], fallback: '');

              final subtotal = pickNum(order, ['subtotal']);
              final shipping = pickNum(order, ['shipping', 'freight']);
              final total = pickNum(order, ['total']);

              final paySt = statusStyle(paymentStatus);

              return ListView(
                padding: EdgeInsets.fromLTRB(sidePad, 16, sidePad, 28),
                children: [
                  // título da página
                  Text(
                    'Pedido #$headerCode',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: FratheliColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (createdAt.isNotEmpty)
                    Text(
                      formatDt(createdAt),
                      style: const TextStyle(
                        color: FratheliColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 14),

                  // resumo (status + total)
                  card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            pill(paySt.label, paySt.icon, paySt.bg, paySt.fg),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: FratheliColors.brown,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                brl(total),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Status do envio',
                          style: TextStyle(
                            color: FratheliColors.text2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shippingStatus,
                          style: const TextStyle(
                            color: FratheliColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        if (shippingService.isNotEmpty || shippingDeadline.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Frete',
                            style: TextStyle(
                              color: FratheliColors.text2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$shippingService${shippingDeadline.isNotEmpty ? " ($shippingDeadline)" : ""}',
                            style: const TextStyle(
                              color: FratheliColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // valores
                  card(
                    child: Column(
                      children: [
                        _rowMoney('Subtotal', brl(subtotal)),
                        const SizedBox(height: 8),
                        _rowMoney('Frete', brl(shipping)),
                        const Divider(height: 22),
                        _rowMoney(
                          'Total',
                          brl(total),
                          strong: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // itens
                  const Text(
                    'Itens',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: FratheliColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (itemsRaw.isEmpty)
                    const Text(
                      'Nenhum item encontrado.',
                      style: TextStyle(color: FratheliColors.textMuted),
                    )
                  else
                    ...itemsRaw.map((it) {
                      final m = (it as Map).cast<String, dynamic>();

                      final name = (m['name'] ?? '').toString().trim();
                      final qty = (m['qty'] ?? m['quantity'] ?? 0).toString();
                      final grind = (m['grind'] ?? '-').toString();

                      final lineTotal = pickNum(
                        m,
                        ['lineTotal', 'line_total', 'price', 'unitPrice', 'unit_price'],
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // bolinha assinatura
                              const _Dot(),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? '-' : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: FratheliColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Qtd: $qty  •  Moagem: $grind',
                                      style: const TextStyle(
                                        color: FratheliColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                brl(lineTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: FratheliColors.brown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: FratheliColors.gold,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _rowMoney extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _rowMoney(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: FratheliColors.textMuted,
      fontWeight: FontWeight.w800,
    );

    final valueStyle = TextStyle(
      color: strong ? FratheliColors.brown : FratheliColors.text,
      fontWeight: FontWeight.w900,
      fontSize: strong ? 16 : 14,
    );

    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}