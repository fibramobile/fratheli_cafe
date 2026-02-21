import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../theme/fratheli_colors.dart';

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

  // helpers fora do build (mais limpo)
  String brl(num v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String formatDt(String raw) {
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} • ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return raw;
    }
  }

  num parseNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse((v ?? '0').toString().replaceAll(',', '.')) ?? 0;
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

  @override
  Widget build(BuildContext context) {
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
            Image.asset(
              'assets/img/logo_escuro.png',
              width: 30,
              height: 30,
            ),
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

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, s) {
          // loading
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // erro
          if (s.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar seus pedidos.\n${s.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FratheliColors.textMuted),
                ),
              ),
            );
          }

          final orders = s.data ?? [];

          // vazio
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não tem pedidos.',
                style: TextStyle(color: FratheliColors.textMuted),
              ),
            );
          }

          // ✅ AQUI é onde entra o título + lista
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Meus pedidos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: FratheliColors.text,
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final o = orders[i];

                    final code = (o['order_code'] ?? '').toString();
                    final payRaw = (o['payment_status'] ?? '').toString();
                    final createdRaw = (o['created_at'] ?? '').toString();
                    final totalNum = parseNum(o['total']);
                    final st = statusStyle(payRaw);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: FratheliColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/pedido',
                              arguments: code,
                            );
                          },
                          child: Container(
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
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Pedido $code',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: FratheliColors.text,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: FratheliColors.brown,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        brl(totalNum),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    pill(st.label, st.icon, st.bg, st.fg),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        formatDt(createdRaw),
                                        style: const TextStyle(
                                          color: FratheliColors.textMuted,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: FratheliColors.text.withOpacity(0.35),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                const Row(
                                  children: [
                                    _Dot(),
                                    SizedBox(width: 8),
                                    Text(
                                      'Frathéli Café',
                                      style: TextStyle(
                                        color: FratheliColors.text2,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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