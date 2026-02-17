import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HeaderAccountButton extends StatefulWidget {
  final bool compact; // pra usar no mobile
  const HeaderAccountButton({super.key, this.compact = false});

  @override
  State<HeaderAccountButton> createState() => _HeaderAccountButtonState();
}

class _HeaderAccountButtonState extends State<HeaderAccountButton> {
  bool _loading = true;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await AuthService.getToken();
    if (!mounted) return;
    setState(() {
      _logged = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  void _go() {
    Navigator.of(context).pushNamed(_logged ? '/minha_conta' : '/login')
        .then((_) => _check()); // quando voltar, atualiza estado
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 40,
        width: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Compacto (mobile): só ícone
    if (widget.compact) {
      return IconButton(
        tooltip: _logged ? 'Minha conta' : 'Entrar',
        onPressed: _go,
        icon: Icon(_logged ? Icons.person : Icons.login),
      );
    }

    // Desktop: botão bonito
    return OutlinedButton.icon(
      onPressed: _go,
      icon: Icon(_logged ? Icons.person : Icons.login, size: 18),
      label: Text(_logged ? 'Minha conta' : 'Entrar'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
