import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _whatsCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _whatsCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      if (!_formKey.currentState!.validate()) {
        setState(() => _loading = false);
        return;
      }

      await AuthService.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        whatsapp: _whatsCtrl.text,
        password: _passCtrl.text,
      );

      if (!mounted) return;

      // Após cadastrar, já loga (token salvo) e manda pra Minha Conta
      Navigator.of(context).pushNamedAndRemoveUntil('/minha_conta', (r) => false);
    }catch (e, s) {
  debugPrint('REGISTER ERROR: $e');
  debugPrint('$s');

  setState(() {
  _error = e.toString().replaceFirst('Exception: ', '');
  });
}finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Informe seu nome';
                          if (s.length < 2) return 'Nome muito curto';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Informe seu email';
                          if (!s.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _whatsCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp (opcional)',
                          hintText: 'DDD + número',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        validator: (v) {
                          final s = (v ?? '');
                          if (s.isEmpty) return 'Informe uma senha';
                          if (s.length < 6) return 'Use pelo menos 6 caracteres';
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _loading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Criar conta'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pushReplacementNamed('/login'),
                        child: const Text('Já tenho conta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
