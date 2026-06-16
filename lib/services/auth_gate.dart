import 'package:flutter/material.dart';

import '../views/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Loja aberta para visitante navegar. O login é exigido apenas no fechamento do pedido.
    return const HomePage();
  }
}
