import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../views/home_page.dart';
import '../views/login_page.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<bool>? _future;

  @override
  void initState() {
    super.initState();
    _future = _hasToken();
  }

  Future<bool> _hasToken() async {
    final token = await AuthService.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final logged = snap.data == true;
        return logged ? const HomePage() : const HomePage();//LoginPage();
      },
    );
  }
}
