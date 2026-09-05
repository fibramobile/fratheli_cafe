import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/order_service.dart';
import '../theme/fratheli_colors.dart';
import '../utils/formatters.dart';
import 'widgets/premium_app_bar.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String? _orderId;
  Future<Map<String, dynamic>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String) {
      _orderId = arguments;
    } else if (arguments is Map && arguments['id'] != null) {
      _orderId = arguments['id'].toString();
    }
    final id = (_orderId ?? '').trim();
    if (id.isNotEmpty) _future = OrderService.fetchOrder(id);
  }

  Future<void> _refresh() async {
    final id = (_orderId ?? '').trim();
    if (id.isEmpty || !mounted) return;

    final next = OrderService.fetchOrder(id);
    setState(() {
      _future = next;
    });

    try {
      await next;
    } catch (_) {
      // O FutureBuilder apresenta a mensagem e mantém disponível o botão de tentar novamente.
    }
  }

  Future<void> _pay(String code) async {
    final uri = Uri.parse(
      'https://frathelicafe.com.br/pagamento_order.html?orderId=${Uri.encodeComponent(code)}',
    );
    final success = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o pagamento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = (_orderId ?? '').trim();
    return Scaffold(
      backgroundColor: FratheliColors.paper,
      appBar: PremiumAppBar(
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), tooltip: 'Atualizar status'),
          const SizedBox(width: 10),
        ],
      ),
      body: id.isEmpty
          ? const Center(child: Text('Pedido inválido: código não informado.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(error: snapshot.error.toString(), onRetry: _refresh);
                    }
                    final data = snapshot.data ?? {};
                    final order = data['order'] is Map
                        ? Map<String, dynamic>.from(data['order'] as Map)
                        : Map<String, dynamic>.from(data);
                    final items = data['items'] is List
                        ? data['items'] as List
                        : order['items'] is List
                            ? order['items'] as List
                            : const [];
                    return _OrderView(order: order, items: items, fallbackId: id, onPay: _pay);
                  },
                ),
              ),
            ),
    );
  }
}

class _OrderView extends StatelessWidget {
  final Map<String, dynamic> order;
  final List items;
  final String fallbackId;
  final ValueChanged<String> onPay;

  const _OrderView({required this.order, required this.items, required this.fallbackId, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final code = _pick(order, ['order_code', 'id'], fallback: fallbackId);
    final paymentRaw = _pick(order, ['paymentStatus', 'payment_status']);
    final shippingRaw = _pick(order, ['shippingStatus', 'shipping_status']);
    final payment = _status(paymentRaw, shipping: false);
    final shipping = _status(shippingRaw, shipping: true);
    final created = _pick(order, ['created_at', 'createdAt'], fallback: '');
    final subtotal = _number(order['subtotal']).toDouble();
    final freight = _number(order['shipping'] ?? order['freight']).toDouble();
    final total = _number(order['total']).toDouble();
    final service = _pick(order, ['shippingService', 'shipping_service'], fallback: '');
    final deadline = _pick(order, ['shippingDeadline', 'shipping_deadline'], fallback: '');
    final canPay = !(paymentRaw.toUpperCase().contains('PAGO') || paymentRaw.toUpperCase().contains('APROV')) &&
        !paymentRaw.toUpperCase().contains('CANCEL');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 64),
      children: [
        const _Eyebrow('ACOMPANHAMENTO'),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido $code', style: GoogleFonts.libreCaslonDisplay(fontSize: 48, height: 1)),
                if (created.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_date(created), style: const TextStyle(color: FratheliColors.muted)),
                ],
              ],
            ),
            Text(brl(total), style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.cherry, fontSize: 37)),
          ],
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final paymentCard = _StatusPanel(
              eyebrow: 'PAGAMENTO',
              status: payment,
              description: payment.label == 'Pago'
                  ? 'Pagamento confirmado. Seu pedido seguirá para a preparação.'
                  : 'Aguardando a confirmação do pagamento via Pix.',
            );
            final shippingCard = _StatusPanel(
              eyebrow: 'ENTREGA',
              status: shipping,
              description: service.isEmpty
                  ? 'O status será atualizado conforme o pedido avançar.'
                  : '$service${deadline.isEmpty ? '' : ' · $deadline'}',
            );
            if (compact) return Column(children: [paymentCard, const SizedBox(height: 12), shippingCard]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: paymentCard), const SizedBox(width: 12), Expanded(child: shippingCard)]);
          },
        ),
        if (canPay) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => onPay(code),
              icon: const Icon(Icons.pix),
              label: const Text('Abrir pagamento Pix'),
            ),
          ),
        ],
        const SizedBox(height: 28),
        const _Eyebrow('ITENS DO PEDIDO'),
        if (items.isEmpty)
          const _Panel(child: Text('Nenhum item encontrado para este pedido.'))
        else
          _Panel(
            child: Column(
              children: items.asMap().entries.map((entry) {
                final item = entry.value is Map
                    ? Map<String, dynamic>.from(entry.value as Map)
                    : <String, dynamic>{};
                final name = _pick(item, ['name'], fallback: 'Café Frathéli');
                final quantity = _pick(item, ['qty', 'quantity'], fallback: '1');
                final grind = _pick(item, ['grind'], fallback: '—');
                final lineTotal = _number(item['lineTotal'] ?? item['line_total'] ?? item['price']).toDouble();
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: entry.key == items.length - 1
                        ? null
                        : const Border(bottom: BorderSide(color: FratheliColors.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.local_cafe_outlined, color: FratheliColors.cherry, size: 21),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('$quantity unidade(s) · $grind', style: const TextStyle(color: FratheliColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(brl(lineTotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 28),
        const _Eyebrow('RESUMO'),
        _Panel(
          child: Column(
            children: [
              _MoneyRow('Subtotal', subtotal),
              const SizedBox(height: 10),
              _MoneyRow('Frete', freight),
              const Divider(height: 28),
              _MoneyRow('Total', total, total: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final String eyebrow;
  final ({String label, IconData icon, Color color}) status;
  final String description;
  const _StatusPanel({required this.eyebrow, required this.status, required this.description});
  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow, style: const TextStyle(color: FratheliColors.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(status.icon, color: status.color, size: 23),
                const SizedBox(width: 9),
                Expanded(child: Text(status.label, style: TextStyle(color: status.color, fontWeight: FontWeight.w700, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(color: FratheliColors.text2, height: 1.45)),
          ],
        ),
      );
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: FratheliColors.border)),
        child: child,
      );
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool total;
  const _MoneyRow(this.label, this.value, {this.total = false});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label, style: TextStyle(fontWeight: total ? FontWeight.w700 : FontWeight.w400)),
          const Spacer(),
          Text(brl(value), style: total ? GoogleFonts.libreCaslonDisplay(fontSize: 26) : const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: FratheliColors.cherry, size: 42),
              const SizedBox(height: 14),
              Text('Não foi possível carregar o pedido', textAlign: TextAlign.center, style: GoogleFonts.libreCaslonDisplay(fontSize: 30)),
              const SizedBox(height: 8),
              Text(error.replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: const TextStyle(color: FratheliColors.muted)),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Text(text, style: const TextStyle(color: FratheliColors.cherry, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
      );
}

({String label, IconData icon, Color color}) _status(String raw, {required bool shipping}) {
  final value = raw.toUpperCase().trim();
  if (value.contains('CANCEL') || value.contains('REJEIT')) {
    return (label: 'Cancelado', icon: Icons.cancel_outlined, color: FratheliColors.danger);
  }
  if (!shipping && (value.contains('PAGO') || value.contains('APROV'))) {
    return (label: 'Pago', icon: Icons.check_circle_outline, color: FratheliColors.green);
  }
  if (shipping && (value.contains('ENTREG') || value.contains('CONCLU'))) {
    return (label: 'Entregue', icon: Icons.home_outlined, color: FratheliColors.green);
  }
  if (shipping && value.contains('AGUARD') && value.contains('ENVI')) {
    return (label: 'Aguardando envio', icon: Icons.schedule, color: FratheliColors.gold);
  }
  if (shipping && (value.startsWith('ENVIADO') || value.contains('POSTADO') || value.contains('EM_TRANSPORTE'))) {
    return (label: 'Enviado', icon: Icons.local_shipping_outlined, color: FratheliColors.cherry);
  }
  if (shipping && (value.contains('PREPAR') || value.contains('SEPAR'))) {
    return (label: 'Em preparação', icon: Icons.inventory_2_outlined, color: FratheliColors.gold);
  }
  return (label: 'Aguardando pagamento', icon: Icons.schedule, color: FratheliColors.gold);
}

String _pick(Map<String, dynamic> map, List<String> keys, {String fallback = '-'}) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
  }
  return fallback;
}

num _number(dynamic value) {
  if (value is num) return value;
  return num.tryParse((value ?? '0').toString().replaceAll(',', '.')) ?? 0;
}

String _date(String raw) {
  try {
    final value = DateTime.parse(raw.replaceFirst(' ', 'T'));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} · ${two(value.hour)}:${two(value.minute)}';
  } catch (_) {
    return raw;
  }
}
