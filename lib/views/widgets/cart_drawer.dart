import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../../controllers/cart_controller.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/fratheli_colors.dart';
import '../../utils/formatters.dart';

class CartDrawer extends StatefulWidget {
  final TextEditingController cepController;
  final VoidCallback onClose;
  final ValueChanged<String> onCepSaved;
  final VoidCallback onCheckout;
  final VoidCallback onClear;
  final Future<void> Function(String cep) onCalculateFreight;

  const CartDrawer({
    super.key,
    required this.cepController,
    required this.onClose,
    required this.onCepSaved,
    required this.onCheckout,
    required this.onClear,
    required this.onCalculateFreight,
  });

  @override
  State<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends State<CartDrawer> {
  bool _calculating = false;
  bool _finishing = false;

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _prefillCep();
  }

  Future<void> _prefillCep() async {
    if (widget.cepController.text.trim().isNotEmpty) return;
    try {
      final profile = await AuthService.fetchClientProfile();
      final address = profile?['address'];
      if (address is Map) {
        final saved = ((address['zip'] ?? address['cep']) ?? '').toString().trim();
        if (saved.isNotEmpty && mounted && widget.cepController.text.isEmpty) {
          widget.cepController.text = saved;
        }
      }
    } catch (_) {
      // O visitante pode não estar autenticado; o CEP continua editável.
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Material(
      color: FratheliColors.paper,
      elevation: 24,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Eyebrow('SUA SELEÇÃO'),
                        Text(
                          'Sacola',
                          style: GoogleFonts.libreCaslonDisplay(
                            color: FratheliColors.ink,
                            fontSize: 42,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar sacola',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                children: [
                  if (cart.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 46),
                      child: Center(
                        child: Text(
                          'Sua sacola está vazia.',
                          style: TextStyle(color: FratheliColors.muted),
                        ),
                      ),
                    )
                  else
                    ...cart.items.map((item) => _CartLine(
                          item: item,
                          onLess: () => cart.changeQty(
                            item.product.sku,
                            item.grind,
                            -1,
                          ),
                          onMore: () => cart.changeQty(
                            item.product.sku,
                            item.grind,
                            1,
                          ),
                        )),
                  const SizedBox(height: 18),
                  _DeliverySelector(
                    cart: cart,
                    onExternal: () => _showExternalPurchaseDialog(context),
                  ),
                  if (cart.freightMode == FreightMode.calculated) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'CEP DE ENTREGA',
                      style: TextStyle(
                        color: FratheliColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.cepController,
                            inputFormatters: [_cepMask],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '00000-000'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _calculating ? null : _calculateFreight,
                            child: _calculating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Calcular'),
                          ),
                        ),
                      ],
                    ),
                    if (cart.freightValue != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: FratheliColors.cream,
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${cart.freightService ?? 'Frete'}${(cart.freightDeadline ?? '').isEmpty ? '' : ' · ${cart.freightDeadline}'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              brl(cart.freightValue!),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 22),
                  _Totals(cart: cart),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _finishing ? null : _finish,
                      child: _finishing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continuar para o pedido'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: cart.items.isEmpty ? null : widget.onClear,
                    child: const Text('Limpar sacola'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _calculateFreight() async {
    final rawCep = widget.cepController.text.replaceAll(RegExp(r'\D'), '');
    if (rawCep.length != 8) {
      _message('Digite um CEP válido com 8 números.');
      return;
    }
    final cart = context.read<CartController>();
    if (cart.items.isEmpty) {
      _message('Adicione um café antes de calcular o frete.');
      return;
    }
    setState(() => _calculating = true);
    widget.onCepSaved(widget.cepController.text.trim());
    try {
      await widget.onCalculateFreight(rawCep);
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _finish() async {
    final cart = context.read<CartController>();
    if (cart.items.isEmpty) {
      _message('Sua sacola está vazia.');
      return;
    }

    if (cart.freightMode == FreightMode.calculated) {
      final rawCep = widget.cepController.text.replaceAll(RegExp(r'\D'), '');
      if (rawCep.length != 8) {
        _message('Informe o CEP de entrega.');
        return;
      }
      if (cart.freightValue == null) {
        _message('Calcule e selecione uma opção de frete.');
        return;
      }
      widget.onCepSaved(widget.cepController.text.trim());
    }

    final token = await AuthService.getToken();
    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Entre para continuar', style: GoogleFonts.libreCaslonDisplay(fontSize: 34)),
          content: const Text(
            'O login protege os dados do seu pedido e permite acompanhar o pagamento e a entrega.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Agora não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Fazer login'),
            ),
          ],
        ),
      );
      if (shouldLogin == true && mounted) {
        widget.onClose();
        await Navigator.pushNamed(context, '/login');
      }
      return;
    }

    setState(() => _finishing = true);
    try {
      if (cart.freightMode == FreightMode.external) {
        final admin = await AuthService.isAdmin();
        if (!admin) throw Exception('Apenas administradores podem criar uma compra externa.');
        if (!cart.isExternalOk) {
          await _showExternalPurchaseDialog(context);
          if (!cart.isExternalOk) return;
        }
        cart.setCustomerData(
          name: cart.externalTitle ?? 'Compra externa',
          phone: cart.customerPhone ?? '-',
          cpf: cart.customerCpf ?? '-',
          address: cart.externalDescription ?? 'Compra externa',
        );
        final orderCode = await OrderService.createExternalOrder(
          _buildPayload(cart, external: true),
        );
        cart.lastOrderId = orderCode;
        widget.onCheckout();
        return;
      }

      final customer = await _showCustomerDialog();
      if (customer == null) return;

      var address = customer['address'] ?? '';
      final cep = widget.cepController.text.trim();
      if (cep.isNotEmpty && !address.toLowerCase().contains('cep:')) {
        address = '$address\nCEP: $cep';
      }
      cart.setCustomerData(
        name: customer['name'] ?? '',
        phone: customer['phone'] ?? '',
        cpf: customer['cpf'] ?? '',
        address: address,
      );

      try {
        await AuthService.upsertClientProfile(
          cpf: customer['cpf'] ?? '',
          phone: customer['phone'] ?? '',
          address: {'street': customer['address'] ?? '', 'cep': cep},
        );
      } catch (_) {
        // O pedido continua mesmo se a atualização do perfil falhar.
      }

      final orderCode = await OrderService.createOrder(_buildPayload(cart));
      cart.lastOrderId = orderCode;
      widget.onCheckout();
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Map<String, dynamic> _buildPayload(
    CartController cart, {
    bool external = false,
  }) {
    final items = cart.items
        .map((item) => {
              'sku': item.product.sku,
              'qty': item.quantity,
              'name': item.product.name,
              'grind': item.grind,
              'unitPrice': item.product.price,
              'lineTotal': item.product.price * item.quantity,
            })
        .toList();
    final shipping = cart.freightMode == FreightMode.calculated
        ? (cart.freightValue ?? 0.0)
        : 0.0;

    return {
      'items': items,
      'subtotal': cart.subtotal,
      'shipping': shipping,
      'shippingService': cart.freightService ?? '',
      'shippingDeadline': cart.freightDeadline ?? '',
      'freightMode': cart.freightMode.name,
      'cep': cart.cep ?? '',
      'total': cart.subtotal + shipping,
      'paymentProvider': 'PIX_MANUAL',
      'paymentStatus': 'AGUARDANDO_PAGAMENTO',
      'shippingStatus': 'AGUARDANDO_PAGAMENTO',
      'customer': {
        'name': cart.customerName ?? '',
        'phone': cart.customerPhone ?? '',
        'cpf': cart.customerCpf ?? '',
        'address': cart.customerAddress ?? '',
      },
      if (external)
        'external': {
          'title': cart.externalTitle ?? '',
          'description': cart.externalDescription ?? '',
        },
    };
  }

  Future<Map<String, String>?> _showCustomerDialog() async {
    var initialName = '';
    var initialPhone = '';
    var initialCpf = '';
    var initialAddress = '';

    try {
      final user = await AuthService.getUser();
      initialName = (user?['name'] ?? '').toString().trim();
      final profile = await AuthService.fetchClientProfile();
      initialPhone = (profile?['phone'] ?? '').toString().trim();
      initialCpf = (profile?['cpf'] ?? '').toString().trim();
      final address = profile?['address'];
      if (address is Map) {
        final parts = [
          address['street'],
          address['number'],
          address['complement'],
          address['neighborhood'],
          address['city'],
          address['state'],
        ]
            .map((value) => (value ?? '').toString().trim())
            .where((value) => value.isNotEmpty);
        initialAddress = parts.join(', ');
      } else {
        initialAddress = (address ?? '').toString().trim();
      }
    } catch (_) {
      // O formulário permanece disponível sem preenchimento automático.
    }

    if (!mounted) return null;
    final name = TextEditingController(text: initialName);
    final phone = TextEditingController(text: initialPhone);
    final cpf = TextEditingController(text: initialCpf);
    final address = TextEditingController(text: initialAddress);
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('FINALIZAR COMPRA'),
            Text('Dados do pedido', style: GoogleFonts.libreCaslonDisplay(fontSize: 42)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DialogField(
                    controller: name,
                    label: 'Nome completo',
                    validator: (value) => (value ?? '').trim().length < 3
                        ? 'Informe o nome completo'
                        : null,
                  ),
                  _DialogField(
                    controller: phone,
                    label: 'WhatsApp',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneMask],
                    validator: (value) => (value ?? '').replaceAll(RegExp(r'\D'), '').length < 10
                        ? 'Telefone inválido'
                        : null,
                  ),
                  _DialogField(
                    controller: cpf,
                    label: 'CPF',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cpfMask],
                    validator: (value) => (value ?? '').replaceAll(RegExp(r'\D'), '').length != 11
                        ? 'CPF inválido'
                        : null,
                  ),
                  _DialogField(
                    controller: address,
                    label: 'Endereço completo',
                    width: 680,
                    maxLines: 3,
                    validator: (value) => (value ?? '').trim().length < 10
                        ? 'Informe o endereço completo'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, {
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'cpf': cpf.text.trim(),
                'address': address.text.trim(),
              });
            },
            child: const Text('Criar pedido e seguir para o Pix'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExternalPurchaseDialog(BuildContext context) async {
    final cart = context.read<CartController>();
    final title = TextEditingController(text: cart.externalTitle ?? '');
    final description = TextEditingController(text: cart.externalDescription ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Compra externa', style: GoogleFonts.libreCaslonDisplay(fontSize: 36)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Título *')),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result == true && title.text.trim().isNotEmpty) {
      cart.setExternalPurchase(
        title: title.text,
        description: description.text,
      );
    } else if (title.text.trim().isEmpty) {
      cart.setCalculatedMode();
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  final VoidCallback onLess;
  final VoidCallback onMore;

  const _CartLine({required this.item, required this.onLess, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FratheliColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '${item.grind} · ${brl(item.product.price)} cada',
                  style: const TextStyle(color: FratheliColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _QtyButton(icon: Icons.remove, onTap: onLess),
          SizedBox(width: 34, child: Text('${item.quantity}', textAlign: TextAlign.center)),
          _QtyButton(icon: Icons.add, onTap: onMore),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(border: Border.all(color: FratheliColors.border)),
          child: Icon(icon, size: 16),
        ),
      );
}

class _DeliverySelector extends StatelessWidget {
  final CartController cart;
  final VoidCallback onExternal;

  const _DeliverySelector({required this.cart, required this.onExternal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('FORMA DE ENTREGA'),
        _radio(
          context,
          value: FreightMode.calculated,
          label: 'Calcular pelo CEP',
          onChanged: cart.setCalculatedMode,
        ),
        _radio(
          context,
          value: FreightMode.combine,
          label: 'Frete a combinar',
          onChanged: cart.setFreightToCombine,
        ),
        FutureBuilder<bool>(
          future: AuthService.isAdmin(),
          builder: (context, snapshot) {
            if (snapshot.data != true) return const SizedBox.shrink();
            return _radio(
              context,
              value: FreightMode.external,
              label: 'Compra externa (admin)',
              onChanged: () {
                cart.setExternalMode();
                onExternal();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _radio(
    BuildContext context, {
    required FreightMode value,
    required String label,
    required VoidCallback onChanged,
  }) {
    final selected = cart.freightMode == value;
    return InkWell(
      onTap: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? FratheliColors.cherry : FratheliColors.muted,
                ),
              ),
              child: selected
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        color: FratheliColors.cherry,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final CartController cart;

  const _Totals({required this.cart});

  @override
  Widget build(BuildContext context) {
    final freight = cart.freightMode == FreightMode.combine
        ? 'A combinar'
        : cart.freightValue == null
            ? 'A calcular'
            : brl(cart.freightValue!);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: FratheliColors.border),
          bottom: BorderSide(color: FratheliColors.border),
        ),
      ),
      child: Column(
        children: [
          _row('Subtotal', brl(cart.subtotal)),
          const SizedBox(height: 8),
          _row('Frete', freight),
          const SizedBox(height: 14),
          _row('Total', brl(cart.totalWithFreight), total: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool total = false}) => Row(
        children: [
          Text(label, style: TextStyle(fontWeight: total ? FontWeight.w700 : FontWeight.w400)),
          const Spacer(),
          Text(
            value,
            style: total
                ? GoogleFonts.libreCaslonDisplay(fontSize: 25)
                : const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      );
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final double width;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _DialogField({
    required this.controller,
    required this.label,
    this.width = 328,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
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
