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
      appBar: AppBar(
        title: const Text('Minha Conta'),
        actions: [
          TextButton(onPressed: _logout, child: const Text('Sair')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Olá!' : 'Olá, $name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: FratheliColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FratheliColors.text2,
                  ),
                ),

                const Divider(),
                const SizedBox(height: 12),

                // Placeholder do futuro "Pontos Colmeia"
                // Pontos Colmeia
                Text(
                  'Pontos Fratheli',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: FratheliColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                FutureBuilder<Map<String, dynamic>>(
                  future: _accountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disponíveis: ${points['available']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Pendentes: ${points['pending']}'),
                        const SizedBox(height: 4),
                        Text('Total acumulado: ${points['lifetime_earned']}'),
                      ],
                    );
                  },
                )


              ],
            ),
          ),
        ),
      ),
    );
  }
}
