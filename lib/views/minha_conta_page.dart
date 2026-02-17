import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/fratheli_colors.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  Map<String, dynamic>? _user;

  late Future<Map<String, dynamic>> _accountFuture;


  @override
  void initState() {
    super.initState();

    _accountFuture = AuthService.fetchMyAccount();

    _accountFuture.then((data) {
      if (!mounted) return;
      setState(() {
        _user = data['user']; // ✅ garante name/email certos
      });
    });
  }


  Future<void> _load() async {
    final u = await AuthService.getUser();
    debugPrint('USER SALVO: $u'); // 👈 adiciona isso
    if (!mounted) return;
    setState(() => _user = u);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }
  @override
  Widget build(BuildContext context) {
    final name = (_user?['name'] ?? '').toString();
    final email = (_user?['email'] ?? '').toString();

    return Scaffold(
      backgroundColor: FratheliColors.bg,
      appBar: AppBar(
        backgroundColor: FratheliColors.surface.withOpacity(0.92),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/img/logo_escuro.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            const Text.rich(
              TextSpan(
                text: 'FRATHÉLI ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.04,
                  color: FratheliColors.brown,
                ),
                children: [
                  TextSpan(
                    text: 'CAFÉ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: FratheliColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: FratheliColors.gold2,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Sair'),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: FratheliColors.border),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✅ Card de boas-vindas (cara do site)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: FratheliColors.surface,
                    border: Border.all(color: FratheliColors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: FratheliColors.gold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FratheliColors.border),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: FratheliColors.brown,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Olá!' : 'Olá, $name',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: FratheliColors.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email.isEmpty ? '—' : email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: FratheliColors.text2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Sua área de cliente Frathéli: pontos, resgates e vantagens.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: FratheliColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ Wallet de pontos (premium)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: FratheliColors.surface,
                    border: Border.all(color: FratheliColors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _accountFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/img/logo_escuro.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pontos Frathéli',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: FratheliColors.text,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          'Erro ao carregar pontos: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      final points = snapshot.data?['points'];
                      if (points == null) {
                        return const Text('Nenhum dado encontrado.');
                      }

                      final available = (points['available'] ?? 0) as int;
                      final pending = (points['pending'] ?? 0) as int;
                      final lifetime = (points['lifetime_earned'] ?? 0) as int;

                      // ✅ (opcional) regra: 100 pts = R$5
                      final discountValue = (available / 100.0) * 5.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pontos Frathéli 🐝',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: FratheliColors.text,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: FratheliColors.gold.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: FratheliColors.border),
                                ),
                                child: Text(
                                  'Disponíveis: $available',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: FratheliColors.brown,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _miniStat(
                                  title: 'Pendentes',
                                  value: '$pending',
                                  icon: Icons.hourglass_bottom_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _miniStat(
                                  title: 'Total acumulado',
                                  value: '$lifetime',
                                  icon: Icons.auto_graph_rounded,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Equivale a ~ R\$ ${discountValue.toStringAsFixed(2)} em desconto (estimativa).',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: FratheliColors.textMuted,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Botão (futuro: resgatar)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Em breve: resgatar pontos no carrinho 😉')),
                                );
                              },
                              icon: const Icon(Icons.local_offer_rounded),
                              label: const Text('Resgatar pontos (em breve)'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ Card pequeno de “atalhos” (opcional)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FratheliColors.surface,
                    border: Border.all(color: FratheliColors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/'),
                          icon: const Icon(Icons.storefront_rounded),
                          label: const Text('Voltar à loja'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // futuro: histórico
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Em breve: histórico de pontos ✅')),
                            );
                          },
                          icon: const Icon(Icons.receipt_long_rounded),
                          label: const Text('Histórico'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ✅ helper visual: mini card estatística
  Widget _miniStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FratheliColors.surfaceAlt,
        border: Border.all(color: FratheliColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FratheliColors.gold.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FratheliColors.border),
            ),
            child: Icon(icon, color: FratheliColors.brown, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FratheliColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: FratheliColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
