import 'package:flutter/material.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orderId = ModalRoute.of(context)!.settings.arguments as int;
   // _future = OrderService.fetchOrder(orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedido')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(child: Text('Erro: ${s.error}'));
          }

          final data = s.data!;
          final order = data['order'];
          final items = (data['items'] as List?) ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text('Pedido #${order['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Status: ${order['status']}'),
                Text('Total: R\$ ${order['total']}'),
                const Divider(height: 24),

                const Text('Itens', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...items.map((it) => ListTile(
                  title: Text(it['name']),
                  subtitle: Text('Qtd: ${it['qty']}  •  Moagem: ${it['grind']}'),
                  trailing: Text('R\$ ${it['price']}'),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
