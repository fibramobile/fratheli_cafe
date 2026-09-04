import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/fratheli_colors.dart';
import 'widgets/premium_app_bar.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  Map<String, dynamic>? _account;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _profilePromptShown = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccount(showProfilePrompt: true);
  }

  Future<void> _loadAccount({bool showProfilePrompt = false}) async {
    if (mounted && !showProfilePrompt) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final account = await AuthService.fetchMyAccount();
      final profile = await AuthService.fetchClientProfile();
      if (!mounted) return;
      setState(() {
        _account = account;
        _user = account['user'] is Map
            ? Map<String, dynamic>.from(account['user'] as Map)
            : null;
        _profile = profile;
        _loading = false;
        _error = null;
      });
      if (showProfilePrompt && _isProfileIncomplete()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCompleteProfileDialog();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _isProfileIncomplete() {
    final name = (_user?['name'] ?? '').toString().trim();
    final phone = (_profile?['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    final cpf = (_profile?['cpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    final address = _formatAddress(_profile?['address']);
    return name.length < 3 || phone.length < 10 || cpf.length != 11 || address == '—';
  }

  List<String> _missingFields() {
    final fields = <String>[];
    if ((_user?['name'] ?? '').toString().trim().length < 3) fields.add('Nome completo');
    if ((_profile?['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '').length < 10) {
      fields.add('Telefone');
    }
    if ((_profile?['cpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '').length != 11) {
      fields.add('CPF');
    }
    if (_formatAddress(_profile?['address']) == '—') fields.add('Endereço e CEP');
    return fields;
  }

  String _formatAddress(dynamic address) {
    if (address is String) return address.trim().isEmpty ? '—' : address.trim();
    if (address is! Map) return '—';
    final parts = <String>[
      (address['street'] ?? '').toString().trim(),
      (address['number'] ?? '').toString().trim(),
      (address['complement'] ?? '').toString().trim(),
      (address['neighborhood'] ?? '').toString().trim(),
      (address['city'] ?? '').toString().trim(),
      (address['state'] ?? '').toString().trim(),
    ].where((value) => value.isNotEmpty).toList();
    final cep = ((address['cep'] ?? address['zip']) ?? '').toString().trim();
    if (cep.isNotEmpty) parts.add('CEP: $cep');
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  Future<void> _showCompleteProfileDialog() async {
    if (_profilePromptShown || !mounted) return;
    _profilePromptShown = true;
    final missing = _missingFields();
    final editNow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('SEU CADASTRO'),
            Text('Complete seu perfil', style: GoogleFonts.libreCaslonDisplay(fontSize: 39)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Precisamos destes dados para calcular a entrega e identificar seus pedidos:',
                style: TextStyle(color: FratheliColors.text2, height: 1.5),
              ),
              const SizedBox(height: 16),
              ...missing.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, color: FratheliColors.cherry),
                      Text(field, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Completar agora'),
          ),
        ],
      ),
    );
    if (editNow == true && mounted) await _openEditProfileDialog();
  }

  Future<void> _openEditProfileDialog() async {
    final name = TextEditingController(text: (_user?['name'] ?? '').toString());
    final phone = TextEditingController(text: (_profile?['phone'] ?? '').toString());
    final cpf = TextEditingController(text: (_profile?['cpf'] ?? '').toString());
    final addressData = _profile?['address'];
    final street = TextEditingController(
      text: addressData is Map
          ? (addressData['street'] ?? '').toString()
          : _formatAddress(addressData) == '—'
              ? ''
              : _formatAddress(addressData),
    );
    final cep = TextEditingController(
      text: addressData is Map
          ? ((addressData['cep'] ?? addressData['zip']) ?? '').toString()
          : '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('DADOS PESSOAIS'),
            Text('Editar cadastro', style: GoogleFonts.libreCaslonDisplay(fontSize: 40)),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    validator: (value) => (value ?? '').trim().length < 3 ? 'Informe seu nome completo' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: (_user?['email'] ?? '').toString(),
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    validator: (value) =>
                        (value ?? '').replaceAll(RegExp(r'\D'), '').length < 10
                            ? 'Telefone inválido'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cpf,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CPF'),
                    validator: (value) =>
                        (value ?? '').replaceAll(RegExp(r'\D'), '').length != 11
                            ? 'CPF inválido'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cep,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CEP'),
                    validator: (value) => (value ?? '').replaceAll(RegExp(r'\D'), '').length != 8 ? 'CEP inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: street,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Endereço completo'),
                    validator: (value) => (value ?? '').trim().length < 8 ? 'Informe o endereço completo' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              try {
                await AuthService.updateBasicUser(name: name.text.trim());
                await AuthService.upsertClientProfile(
                  cpf: cpf.text.trim(),
                  phone: phone.text.trim(),
                  address: {'street': street.text.trim(), 'cep': cep.text.trim()},
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Não foi possível salvar: $error')),
                );
              }
            },
            child: const Text('Salvar alterações'),
          ),
        ],
      ),
    );

    name.dispose();
    phone.dispose();
    cpf.dispose();
    street.dispose();
    cep.dispose();

    if (saved == true && mounted) {
      _profilePromptShown = false;
      await _loadAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso.')),
        );
      }
    }
  }

  Future<void> _openChangePasswordDialog() async {
    final current = TextEditingController();
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(18),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('SEGURANÇA'),
            Text('Alterar senha', style: GoogleFonts.libreCaslonDisplay(fontSize: 40)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha atual'),
                  validator: (value) => (value ?? '').isEmpty ? 'Informe a senha atual' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  validator: (value) => (value ?? '').length < 6 ? 'Use pelo menos 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
                  validator: (value) => value != password.text ? 'As senhas não coincidem' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              try {
                await AuthService.changePassword(
                  currentPassword: current.text,
                  newPassword: password.text,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senha alterada com sucesso.')),
                  );
                }
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Não foi possível alterar a senha: $error')),
                );
              }
            },
            child: const Text('Alterar senha'),
          ),
        ],
      ),
    );

    current.dispose();
    password.dispose();
    confirmation.dispose();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FratheliColors.paper,
      appBar: PremiumAppBar(
        actions: [
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(foregroundColor: FratheliColors.cream),
            child: const Text('Sair'),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _AccountError(message: _error!, onRetry: () => _loadAccount())
              : RefreshIndicator(
                  onRefresh: () => _loadAccount(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 72),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Eyebrow('ÁREA DO CLIENTE'),
                              Text(
                                'Sua conta Frathéli.',
                                style: GoogleFonts.libreCaslonDisplay(
                                  color: FratheliColors.ink,
                                  fontSize: 56,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _firstName.isEmpty
                                    ? 'Acompanhe seus dados, benefícios e pedidos.'
                                    : 'Olá, $_firstName. Acompanhe seus dados, benefícios e pedidos.',
                                style: const TextStyle(color: FratheliColors.text2, height: 1.55),
                              ),
                              const SizedBox(height: 36),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final desktop = constraints.maxWidth >= 820;
                                  final profile = _ProfilePanel(
                                    user: _user,
                                    profile: _profile,
                                    address: _formatAddress(_profile?['address']),
                                    completeness: _profileCompleteness,
                                    onEdit: _openEditProfileDialog,
                                    onPassword: _openChangePasswordDialog,
                                  );
                                  final actions = Column(
                                    children: [
                                      _OrdersCard(
                                        onTap: () => Navigator.pushNamed(context, '/meus_pedidos'),
                                      ),
                                      const SizedBox(height: 14),
                                      _PointsPanel(account: _account),
                                      const SizedBox(height: 14),
                                      _StoreCard(
                                        onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                                      ),
                                    ],
                                  );
                                  if (!desktop) {
                                    return Column(children: [profile, const SizedBox(height: 14), actions]);
                                  }
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 6, child: profile),
                                      const SizedBox(width: 18),
                                      Expanded(flex: 4, child: actions),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String get _firstName {
    final value = (_user?['name'] ?? '').toString().trim();
    return value.isEmpty ? '' : value.split(RegExp(r'\s+')).first;
  }

  int get _profileCompleteness {
    var complete = 0;
    if ((_user?['name'] ?? '').toString().trim().length >= 3) complete++;
    if ((_profile?['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '').length >= 10) complete++;
    if ((_profile?['cpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '').length == 11) complete++;
    if (_formatAddress(_profile?['address']) != '—') complete++;
    return complete * 25;
  }
}

class _ProfilePanel extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? profile;
  final String address;
  final int completeness;
  final VoidCallback onEdit;
  final VoidCallback onPassword;

  const _ProfilePanel({
    required this.user,
    required this.profile,
    required this.address,
    required this.completeness,
    required this.onEdit,
    required this.onPassword,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: FratheliColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: FratheliColors.cream,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: FratheliColors.espresso, shape: BoxShape.circle),
                    child: Text(
                      _initials((user?['name'] ?? '').toString()),
                      style: const TextStyle(color: FratheliColors.gold2, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user?['name'] ?? 'Cliente Frathéli').toString(),
                          style: GoogleFonts.libreCaslonDisplay(fontSize: 28),
                        ),
                        Text((user?['email'] ?? '—').toString(), style: const TextStyle(color: FratheliColors.muted)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onEdit, tooltip: 'Editar cadastro', icon: const Icon(Icons.edit_outlined)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: _Eyebrow('SEUS DADOS')),
                      Text('$completeness% completo', style: const TextStyle(color: FratheliColors.cherry, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: completeness / 100,
                      minHeight: 3,
                      backgroundColor: FratheliColors.cream,
                      color: FratheliColors.cherry,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DataRow(label: 'Nome', value: (user?['name'] ?? '—').toString()),
                  _DataRow(label: 'E-mail', value: (user?['email'] ?? '—').toString()),
                  _DataRow(label: 'Telefone', value: (profile?['phone'] ?? '—').toString()),
                  _DataRow(label: 'CPF', value: (profile?['cpf'] ?? '—').toString()),
                  _DataRow(label: 'Endereço', value: address, last: true),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar meus dados')),
                      OutlinedButton.icon(
                        onPressed: onPassword,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: const Text('Alterar senha'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FratheliColors.ink,
                          side: const BorderSide(color: FratheliColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _DataRow({required this.label, required this.value, this.last = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: FratheliColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Text(label, style: const TextStyle(color: FratheliColors.muted, fontSize: 12))),
            Expanded(
              child: Text(
                value.trim().isEmpty ? '—' : value,
                style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class _OrdersCard extends StatelessWidget {
  final VoidCallback onTap;
  const _OrdersCard({required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: FratheliColors.espresso,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long_outlined, color: FratheliColors.gold2, size: 29),
                const SizedBox(height: 24),
                Text('Meus pedidos', style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.cream, fontSize: 32)),
                const SizedBox(height: 8),
                const Text('Acompanhe pagamento, preparação e entrega.', style: TextStyle(color: Color(0xFFCFC1B2), height: 1.45)),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Text('VER PEDIDOS E STATUS', style: TextStyle(color: FratheliColors.gold2, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
                    Spacer(),
                    Icon(Icons.arrow_forward, color: FratheliColors.gold2, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _PointsPanel extends StatelessWidget {
  final Map<String, dynamic>? account;
  const _PointsPanel({required this.account});
  @override
  Widget build(BuildContext context) {
    final raw = account?['points'];
    final points = raw is Map ? raw : const <String, dynamic>{};
    final available = _asInt(points['available']);
    final pending = _asInt(points['pending']);
    final lifetime = _asInt(points['lifetime_earned']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: FratheliColors.cream, border: Border.all(color: FratheliColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('PONTOS FRATHÉLI'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$available', style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.ink, fontSize: 46, height: .9)),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('disponíveis', style: TextStyle(color: FratheliColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _PointStat(label: 'Pendentes', value: '$pending')),
              const SizedBox(width: 12),
              Expanded(child: _PointStat(label: 'Acumulados', value: '$lifetime')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointStat extends StatelessWidget {
  final String label;
  final String value;
  const _PointStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white.withOpacity(.65),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: FratheliColors.muted, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
      );
}

class _StoreCard extends StatelessWidget {
  final VoidCallback onTap;
  const _StoreCard({required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: FratheliColors.border)),
            child: const Row(
              children: [
                Icon(Icons.local_cafe_outlined, color: FratheliColors.cherry),
                SizedBox(width: 12),
                Expanded(child: Text('Voltar para a loja', style: TextStyle(fontWeight: FontWeight.w700))),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      );
}

class _AccountError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _AccountError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, color: FratheliColors.cherry, size: 42),
              const SizedBox(height: 14),
              Text('Não foi possível carregar sua conta', textAlign: TextAlign.center, style: GoogleFonts.libreCaslonDisplay(fontSize: 31)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: FratheliColors.muted)),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return 'F';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '0').toString()) ?? 0;
}
