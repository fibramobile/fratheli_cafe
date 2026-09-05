import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/order_service.dart';
import '../theme/fratheli_colors.dart';
import '../utils/formatters.dart';
import 'widgets/premium_app_bar.dart';

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = OrderService.fetchMyOrders();
  }

  Future<void> _refresh() async {
    final next = OrderService.fetchMyOrders();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // O FutureBuilder exibe o erro e oferece nova tentativa.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FratheliColors.paper,
      appBar: PremiumAppBar(
        actions: [
          IconButton(
            tooltip: 'Atualizar pedidos',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.receipt_long_outlined,
              title: 'Não foi possível carregar seus pedidos',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              button: 'Tentar novamente',
              onTap: _refresh,
            );
          }

          final orders = snapshot.data ?? const <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _OrdersHero(orderCount: orders.length),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 42, 20, 72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (orders.isEmpty)
                            _MessageState(
                              icon: Icons.local_cafe_outlined,
                              title: 'Seu primeiro café está por vir',
                              message:
                                  'Quando você finalizar uma compra, o pedido e cada etapa da entrega aparecerão aqui.',
                              button: 'Escolher cafés',
                              onTap: () => Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (route) => false,
                              ),
                            )
                          else ...[
                            const _SectionHeading(),
                            const SizedBox(height: 18),
                            ...orders.indexed.map(
                              (entry) => _OrderCard(
                                order: entry.$2,
                                index: entry.$1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: FratheliColors.cherry),
      );
}

class _OrdersHero extends StatelessWidget {
  final int orderCount;
  const _OrdersHero({required this.orderCount});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: FratheliColors.cream,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 54, 20, 52),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 720;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Eyebrow('ÁREA DO CLIENTE · PEDIDOS'),
                      Text(
                        'Seu café,\npedido a pedido.',
                        style: GoogleFonts.libreCaslonDisplay(
                          color: FratheliColors.ink,
                          fontSize: desktop ? 58 : 44,
                          height: .98,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                       ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 570),
                        child: const Text(
                          'Acompanhe o pagamento, a preparação e o caminho de cada lote até a sua casa.',
                          style: TextStyle(
                            color: FratheliColors.text2,
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  );
                  final counter = Container(
                    width: desktop ? 220 : double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: FratheliColors.espresso,
                      border: Border(
                        top: BorderSide(color: FratheliColors.gold2, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$orderCount',
                          style: GoogleFonts.libreCaslonDisplay(
                            color: FratheliColors.cream,
                            fontSize: 48,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          orderCount == 1 ? 'PEDIDO ENCONTRADO' : 'PEDIDOS ENCONTRADOS',
                          style: const TextStyle(
                            color: FratheliColors.gold2,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                  if (!desktop) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 28), counter],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 48),
                      counter,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            'Histórico de pedidos',
            style: GoogleFonts.libreCaslonDisplay(
              color: FratheliColors.ink,
              fontSize: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Divider(color: FratheliColors.border)),
        ],
      );
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final int index;
  const _OrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    final code = _pick(order, ['order_code', 'id'], fallback: '—');
    final created = _pick(order, ['created_at', 'createdAt'], fallback: '');
    final total = _number(order['total']).toDouble();
    final payment = _status(
      _pick(order, ['paymentStatus', 'payment_status'], fallback: ''),
      shipping: false,
    );
    final shipping = _status(
      _pick(order, ['shippingStatus', 'shipping_status'], fallback: ''),
      shipping: true,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/pedido', arguments: code),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: index == 0
                      ? FratheliColors.cherry
                      : FratheliColors.gold,
                  width: 4,
                ),
                top: const BorderSide(color: FratheliColors.border),
                right: const BorderSide(color: FratheliColors.border),
                bottom: const BorderSide(color: FratheliColors.border),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 760;
                  final identity = _OrderIdentity(
                    code: code,
                    created: created,
                    latest: index == 0,
                  );
                  final journey = _OrderJourney(
                    payment: payment,
                    shipping: shipping,
                  );
                  final totalAndLink = _OrderTotal(
                    total: total,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/pedido',
                      arguments: code,
                    ),
                  );
                  if (!desktop) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        const SizedBox(height: 22),
                        journey,
                        const SizedBox(height: 22),
                        totalAndLink,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 250, child: identity),
                      const SizedBox(width: 22),
                      Expanded(child: journey),
                      const SizedBox(width: 30),
                      SizedBox(width: 180, child: totalAndLink),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderIdentity extends StatelessWidget {
  final String code;
  final String created;
  final bool latest;
  const _OrderIdentity({required this.code, required this.created, required this.latest});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Eyebrow('PEDIDO'),
              if (latest) ...[
                const SizedBox(width: 9),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'MAIS RECENTE',
                    style: TextStyle(
                      color: FratheliColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SelectableText(
            code,
            style: GoogleFonts.libreCaslonDisplay(
              color: FratheliColors.ink,
              fontSize: 27,
              height: 1.1,
            ),
          ),
          if (created.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              _date(created),
              style: const TextStyle(color: FratheliColors.muted, fontSize: 12),
            ),
          ],
        ],
      );
}

class _OrderJourney extends StatelessWidget {
  final _OrderStatus payment;
  final _OrderStatus shipping;
  const _OrderJourney({required this.payment, required this.shipping});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _StatusLine(label: 'Pagamento', status: payment),
          const SizedBox(height: 14),
          _StatusLine(label: 'Entrega', status: shipping),
        ],
      );
}

class _StatusLine extends StatelessWidget {
  final String label;
  final _OrderStatus status;
  const _StatusLine({required this.label, required this.status});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            color: status.color.withOpacity(.10),
            child: Icon(status.icon, size: 17, color: status.color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: FratheliColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.label,
                  style: TextStyle(color: status.color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      );
}

class _OrderTotal extends StatelessWidget {
  final double total;
  final VoidCallback onTap;
  const _OrderTotal({required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL',
            style: TextStyle(
              color: FratheliColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            brl(total),
            style: GoogleFonts.libreCaslonDisplay(
              color: FratheliColors.ink,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: FratheliColors.cherry,
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text(
              'VER DETALHES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1),
            ),
          ),
        ],
      );
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String button;
  final VoidCallback onTap;
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.button,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: FratheliColors.cream,
              border: Border.all(color: FratheliColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: FratheliColors.cherry),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.libreCaslonDisplay(fontSize: 31),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FratheliColors.text2, height: 1.5),
                ),
                const SizedBox(height: 22),
                ElevatedButton(onPressed: onTap, child: Text(button)),
              ],
            ),
          ),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            color: FratheliColors.cherry,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      );
}

class _OrderStatus {
  final String label;
  final IconData icon;
  final Color color;
  const _OrderStatus(this.label, this.icon, this.color);
}

_OrderStatus _status(String raw, {required bool shipping}) {
  final value = raw.toUpperCase().trim();
  if (value.contains('CANCEL') || value.contains('REJEIT')) {
    return const _OrderStatus('Cancelado', Icons.cancel_outlined, FratheliColors.danger);
  }
  if (!shipping && (value.contains('PAGO') || value.contains('APROV'))) {
    return const _OrderStatus('Pagamento aprovado', Icons.check_circle_outline, FratheliColors.green);
  }
  if (!shipping && (value.contains('FALH') || value.contains('EXPIR'))) {
    return const _OrderStatus('Pagamento não concluído', Icons.error_outline, FratheliColors.danger);
  }
  if (shipping && (value.contains('ENTREG') || value.contains('CONCLU'))) {
    return const _OrderStatus('Entregue', Icons.home_outlined, FratheliColors.green);
  }
  if (shipping && value.contains('AGUARD') && value.contains('ENVI')) {
    return const _OrderStatus('Aguardando envio', Icons.schedule, FratheliColors.gold);
  }
  if (shipping &&
      (value.startsWith('ENVIADO') ||
          value.contains('POSTADO') ||
          value.contains('EM_TRANSPORTE'))) {
    return const _OrderStatus('Em transporte', Icons.local_shipping_outlined, FratheliColors.cherry);
  }
  if (shipping && (value.contains('PREPAR') || value.contains('SEPAR'))) {
    return const _OrderStatus('Em preparação', Icons.inventory_2_outlined, FratheliColors.gold);
  }
  return _OrderStatus(
    shipping ? 'Aguardando confirmação' : 'Aguardando pagamento',
    Icons.schedule,
    FratheliColors.gold,
  );
}

String _pick(Map<String, dynamic> map, List<String> keys, {String fallback = '-'}) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
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
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} · ${two(value.hour)}:${two(value.minute)}';
  } catch (_) {
    return raw;
  }
}
