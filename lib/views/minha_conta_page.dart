import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../theme/fratheli_colors.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;
  late Future<Map<String, dynamic>> _accountFuture;
  bool _profileDialogShown = false;

  bool _isProfileIncomplete() {
    final name = (_user?['name'] ?? '').toString().trim();
    final phone = (_profile?['phone'] ?? '').toString().trim();
    final cpf = (_profile?['cpf'] ?? '').toString().trim();
    final address = _formatAddress(_profile?['address']).trim();

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final cpfDigits = cpf.replaceAll(RegExp(r'\D'), '');

    return name.length < 3 ||
        phoneDigits.length < 10 ||
        cpfDigits.length != 11 ||
        address.isEmpty ||
        address == '—';
  }

  List<String> _missingProfileFields() {
    final missing = <String>[];

    final name = (_user?['name'] ?? '').toString().trim();
    final phone = (_profile?['phone'] ?? '').toString().trim();
    final cpf = (_profile?['cpf'] ?? '').toString().trim();
    final address = _formatAddress(_profile?['address']).trim();

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final cpfDigits = cpf.replaceAll(RegExp(r'\D'), '');

    if (name.length < 3) missing.add('Nome');
    if (phoneDigits.length < 10) missing.add('Telefone');
    if (cpfDigits.length != 11) missing.add('CPF');
    if (address.isEmpty || address == '—') missing.add('Endereço');

    return missing;
  }
  Future<void> _showCompleteProfileDialog() async {
    if (!mounted || _profileDialogShown) return;

    _profileDialogShown = true;
    final missing = _missingProfileFields();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: FratheliColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Complete seu perfil',
            style: TextStyle(
              color: FratheliColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para aproveitar melhor sua experiência na Frathéli, complete seus dados cadastrais.',
                style: TextStyle(
                  color: FratheliColors.text2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (missing.isNotEmpty) ...[
                const Text(
                  'Campos pendentes:',
                  style: TextStyle(
                    color: FratheliColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...missing.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: FratheliColors.gold2,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item,
                          style: const TextStyle(
                            color: FratheliColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Depois',
                style: TextStyle(color: FratheliColors.text2),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _openEditProfileDialog();
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar agora'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _accountFuture = AuthService.fetchMyAccount();

    _accountFuture.then((data) async {
      if (!mounted) return;

      final profile = await AuthService.fetchClientProfile();

      if (!mounted) return;
      setState(() {
        _user = data['user'];
        _profile = profile;
        _loadingProfile = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isProfileIncomplete()) {
          _showCompleteProfileDialog();
        }
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
      });
    });
  }

  String _formatAddress(dynamic address) {
    if (address == null) return '—';

    if (address is String) {
      return address.trim().isEmpty ? '—' : address.trim();
    }

    if (address is Map) {
      final street = (address['street'] ?? '').toString().trim();
      final number = (address['number'] ?? '').toString().trim();
      final complement = (address['complement'] ?? '').toString().trim();
      final neighborhood = (address['neighborhood'] ?? '').toString().trim();
      final city = (address['city'] ?? '').toString().trim();
      final state = (address['state'] ?? '').toString().trim();
      final cep = ((address['cep'] ?? address['zip']) ?? '').toString().trim();

      final parts = <String>[
        if (street.isNotEmpty) street,
        if (number.isNotEmpty) number,
        if (complement.isNotEmpty) complement,
        if (neighborhood.isNotEmpty) neighborhood,
        if (city.isNotEmpty) city,
        if (state.isNotEmpty) state,
        if (cep.isNotEmpty) 'CEP: $cep',
      ];

      return parts.isEmpty ? '—' : parts.join(', ');
    }

    return '—';
  }

  /*
  Future<void> _openEditProfileDialog() async {
    final nameCtrl = TextEditingController(
      text: (_user?['name'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (_profile?['phone'] ?? '').toString(),
    );
    final cpfCtrl = TextEditingController(
      text: (_profile?['cpf'] ?? '').toString(),
    );
    final addressCtrl = TextEditingController(
      text: _formatAddress(_profile?['address']) == '—'
          ? ''
          : _formatAddress(_profile?['address']),
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: FratheliColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Editar dados',
            style: TextStyle(
              color: FratheliColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) {
                        if ((v ?? '').trim().length < 3) return 'Informe seu nome';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: (_user?['email'] ?? '').toString(),
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10) return 'Telefone inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cpfCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      decoration: const InputDecoration(labelText: 'CPF'),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.length != 11) return 'CPF inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Endereço completo Com CEP',
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().length < 8) return 'Endereço inválido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                try {
                  await AuthService.updateBasicUser(
                    name: nameCtrl.text.trim(),
                  );

                  await AuthService.upsertClientProfile(
                    cpf: cpfCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: {
                      'street': addressCtrl.text.trim(),
                    },
                  );

                  if (!mounted) return;

                  setState(() {
                    _user = {
                      ...?_user,
                      'name': nameCtrl.text.trim(),
                    };

                    _profile = {
                      ...?_profile,
                      'cpf': cpfCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'address': {
                        'street': addressCtrl.text.trim(),
                      },
                    };
                  });

                  Navigator.pop(ctx, true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dados atualizados com sucesso')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar dados: $e')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final refreshed = await AuthService.fetchMyAccount();
      final refreshedProfile = await AuthService.fetchClientProfile();

      if (!mounted) return;
      setState(() {
        _user = refreshed['user'];
        _profile = refreshedProfile;
        _profileDialogShown = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isProfileIncomplete()) {
          _showCompleteProfileDialog();
        }
      });
    }
  }
  */
  Future<void> _openEditProfileDialog() async {
    final nameCtrl = TextEditingController(
      text: (_user?['name'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (_profile?['phone'] ?? '').toString(),
    );
    final cpfCtrl = TextEditingController(
      text: (_profile?['cpf'] ?? '').toString(),
    );

    final currentAddress = _profile?['address'];
    String initialStreet = '';
    String initialCep = '';

    if (currentAddress is Map) {
      initialStreet = (currentAddress['street'] ?? '').toString().trim();
      initialCep = ((currentAddress['cep'] ?? currentAddress['zip']) ?? '')
          .toString()
          .trim();
    } else {
      final formatted = _formatAddress(_profile?['address']);
      initialStreet = formatted == '—' ? '' : formatted;
    }

    final addressCtrl = TextEditingController(text: initialStreet);
    final cepCtrl = TextEditingController(text: initialCep);

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: FratheliColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Editar dados',
            style: TextStyle(
              color: FratheliColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) {
                        if ((v ?? '').trim().length < 3) {
                          return 'Informe seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: (_user?['email'] ?? '').toString(),
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10) return 'Telefone inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cpfCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      decoration: const InputDecoration(labelText: 'CPF'),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.length != 11) return 'CPF inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cepCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'CEP'),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.length != 8) return 'CEP inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      style: const TextStyle(color: FratheliColors.text),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Endereço completo',
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().length < 8) {
                          return 'Endereço inválido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                try {
                  await AuthService.updateBasicUser(
                    name: nameCtrl.text.trim(),
                  );

                  await AuthService.upsertClientProfile(
                    cpf: cpfCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: {
                      'street': addressCtrl.text.trim(),
                      'cep': cepCtrl.text.trim(),
                    },
                  );

                  if (!mounted) return;

                  setState(() {
                    _user = {
                      ...?_user,
                      'name': nameCtrl.text.trim(),
                    };

                    _profile = {
                      ...?_profile,
                      'cpf': cpfCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'address': {
                        'street': addressCtrl.text.trim(),
                        'cep': cepCtrl.text.trim(),
                      },
                    };
                  });

                  Navigator.pop(ctx, true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados atualizados com sucesso'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar dados: $e')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final refreshed = await AuthService.fetchMyAccount();
      final refreshedProfile = await AuthService.fetchClientProfile();

      if (!mounted) return;
      setState(() {
        _user = refreshed['user'];
        _profile = refreshedProfile;
        _profileDialogShown = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isProfileIncomplete()) {
          _showCompleteProfileDialog();
        }
      });
    }
  }

  Future<void> _openChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: FratheliColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Alterar senha',
            style: TextStyle(
              color: FratheliColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha atual'),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Informe a senha atual';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova senha'),
                    validator: (v) {
                      if ((v ?? '').length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
                    validator: (v) {
                      if (v != newCtrl.text) return 'As senhas não coincidem';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                try {
                  await AuthService.changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );

                  if (!mounted) return;
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senha alterada com sucesso')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao alterar senha: $e')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
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
                    text: 'CAFÉS',
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
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

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/meus_pedidos');
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Meus pedidos'),
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

                const SizedBox(height: 14),

                /// ✅ Meus dados
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: FratheliColors.surface,
                    border: Border.all(color: FratheliColors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: FratheliColors.brown),
                          const SizedBox(width: 8),
                          Text(
                            'Meus dados',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: FratheliColors.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _loadingProfile ? null : _openEditProfileDialog,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _infoLine('Nome', (_user?['name'] ?? '—').toString()),
                      _infoLine('Email', (_user?['email'] ?? '—').toString()),
                      _infoLine('Telefone', (_profile?['phone'] ?? '—').toString()),
                      _infoLine('CPF', (_profile?['cpf'] ?? '—').toString()),
                      _infoLine(
                        'Endereço',
                        _formatAddress(_profile?['address']),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openChangePasswordDialog,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Alterar senha'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
/*
                /// ✅ Wallet de pontos (premium)
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
*/
              ],
            ),
                ],
              ),
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


Widget _infoLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FratheliColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            color: FratheliColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}