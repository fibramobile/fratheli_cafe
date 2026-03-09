/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../controllers/cart_controller.dart';
import '../../utils/formatters.dart';
import 'package:http/http.dart' as http;

class CartDrawer extends StatelessWidget {
  final TextEditingController cepController;
  final VoidCallback onClose;
  final Function(String) onCepSaved;
  final VoidCallback onCheckout;
  final VoidCallback onClear;
  final Future<void> Function(String cep) onCalculateFreight;

  const CartDrawer({
    required this.cepController,
    required this.onClose,
    required this.onCepSaved,
    required this.onCheckout,
    required this.onClear,
    required this.onCalculateFreight,
  });

  Future<void> showExternalPurchaseDialog(BuildContext context) async {
    final cart = context.read<CartController>();

    final titleCtrl = TextEditingController(text: cart.externalTitle ?? '');
    final descCtrl = TextEditingController(text: cart.externalDescription ?? '');

    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Compra externa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ex: Retirada na loja / Compra via Instagram',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Detalhes…',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // volta pro calculado (ou mantenha como estava)
                    cart.setCalculatedMode();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final t = titleCtrl.text.trim();
                    if (t.isEmpty) {
                      setLocal(() => error = 'Título é obrigatório');
                      return;
                    }
                    cart.setExternalPurchase(
                      title: t,
                      description: descCtrl.text,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    final cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    final phoneMask = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    final cepMask = MaskTextInputFormatter(
      mask: '#####-###',
      filter: {"#": RegExp(r'[0-9]')},
    );

    return Container(
      width: 360,
      color: const Color(0xFF131316),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Seu carrinho",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Itens
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
              child: Text(
                'Seu carrinho está vazio.',
                style: TextStyle(color: Colors.white60),
              ),
            )
                : ListView(
              children: cart.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${item.product.name} (${item.grind})\nSKU: ${item.product.sku}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => cart.changeQty(
                                item.product.sku, item.grind, -1),
                          ),
                          Text("${item.quantity}"),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => cart.changeQty(
                                item.product.sku, item.grind, 1),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ✅ ENTREGA (NOVO)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Entrega",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                RadioListTile<FreightMode>(
                  value: FreightMode.calculated,
                  groupValue: cart.freightMode,
                  onChanged: (v) {
                    if (v == null) return;
                    cart.setCalculatedMode(); // opcional, se você criou
                  },
                  title: const Text("Calcular frete pelo CEP"),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),

                /*
                RadioListTile<FreightMode>(
                  value: FreightMode.free,
                  groupValue: cart.freightMode,
                  onChanged: (v) {
                    if (v == null) return;
                    cart.setFreeFreight();
                  },
                  title: const Text("Frete grátis"),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),
                */

                RadioListTile<FreightMode>(
                  value: FreightMode.combine,
                  groupValue: cart.freightMode,
                  onChanged: (v) {
                    if (v == null) return;
                    cart.setFreightToCombine();
                  },
                  title: const Text("Frete a combinar"),
                  subtitle: const Text("Você combina/paga no WhatsApp após o pedido."),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),
                /*
                RadioListTile<FreightMode>(
                  value: FreightMode.external,
                  groupValue: cart.freightMode,
                  onChanged: (_) async {
                    // marca e abre o dialog
                    cart.freightMode = FreightMode.external;
                    cart.notifyListeners(); // se preferir, crie um setFreightMode()
                    await showExternalPurchaseDialog(context);
                  },
                  title: const Text('Compra externa'),
                  subtitle: Text(
                    cart.externalTitle?.isNotEmpty == true
                        ? 'Título: ${cart.externalTitle}'
                        : 'Informe um título (obrigatório).',
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),
                */
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ✅ CEP + CALCULAR FRETE (SÓ SE FOR calculated)
          if (cart.freightMode == FreightMode.calculated) ...[
            TextField(
              controller: cepController,
              keyboardType: TextInputType.number,
              inputFormatters: [cepMask],
              decoration: const InputDecoration(
                labelText: "CEP",
                hintText: "00000-000",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final cep = cepController.text.trim();
                  final rawCep = cep.replaceAll(RegExp(r'\D'), '');

                  if (rawCep.length != 8) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('CEP inválido'),
                        content: const Text(
                            'Digite um CEP com 8 dígitos para calcular o frete.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  onCepSaved(cep); // salva com máscara
                  await onCalculateFreight(rawCep); // manda só números
                },
                child: const Text("Calcular Frete"),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Totais
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Subtotal"),
                  Text(brl(cart.subtotal)),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Frete"),
                  Text(() {
                   // if (cart.freightMode == FreightMode.free) return "grátis";
                    if (cart.freightMode == FreightMode.combine) return "a combinar";

                    // calculated
                    return cart.freightValue != null
                        ? brl(cart.freightValue!)
                        : "a calcular";
                  }()),
                ],
              ),

              if ((cart.freightService != null && cart.freightService!.isNotEmpty) ||
                  (cart.freightDeadline != null && cart.freightDeadline!.isNotEmpty)) ...[
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    (cart.freightDeadline != null &&
                        cart.freightDeadline!.isNotEmpty)
                        ? "${cart.freightService ?? ''} (${cart.freightDeadline})"
                        : "${cart.freightService ?? ''}",
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],

              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(brl(cart.totalWithFreight)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Finalizar pedido
          ElevatedButton(
            onPressed: () async {
              final cart = context.read<CartController>();

              // 1) Carrinho vazio
              if (cart.items.isEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Carrinho vazio'),
                    content: const Text(
                      'Adicione pelo menos um produto antes de finalizar o pedido.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
                return;
              }

              // 2) Compra externa: exige título e vai DIRETO pro Pix (bypass dados)
              if (cart.freightMode == FreightMode.external) {
                if (!cart.isExternalOk) {
                  await showExternalPurchaseDialog(context);
                  if (!cart.isExternalOk) return;
                }
                cart.customerName = cart.externalTitle?.trim(); // ✅ título vira nome
                onCheckout(); // ✅ direto Pix
                return;
              }

              // 3) Só exige CEP e frete calculado se o modo for "calculated"
              if (cart.freightMode == FreightMode.calculated) {
                final cep = cepController.text.trim();
                final rawCep = cep.replaceAll(RegExp(r'\D'), '');

                if (rawCep.length != 8) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('CEP obrigatório'),
                      content: const Text('Informe um CEP válido para calcular o frete.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                if (cart.freightValue == null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Frete não calculado'),
                      content: const Text('Calcule o frete antes de finalizar o pedido.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // Salva o CEP no controller
                onCepSaved(cep);
              }

              // 4) Para os outros modos (calculated/free/combine): pede dados do cliente
              final result = await showDialog<Map<String, String>>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  final formKey = GlobalKey<FormState>();

                  final nameController = TextEditingController();
                  final phoneController = TextEditingController();
                  final cpfController = TextEditingController();
                  final addressController = TextEditingController();

                  bool isLogging = false;
                  bool isLogged = false;

                  void fillFields({
                    required String nome,
                    required String telefone,
                    required String cpf,
                    required String endereco,
                  }) {
                    nameController.text = nome;
                    phoneController.text = telefone;
                    cpfController.text = cpf;
                    addressController.text = endereco;
                  }

                  return StatefulBuilder(
                    builder: (ctx, setState) {
                      Future<void> handleLogin() async {
                        try {
                          setState(() => isLogging = true);

                          // EXEMPLO (simulado):
                          await Future.delayed(const Duration(milliseconds: 400));
                          fillFields(
                            nome: "Francis do Nascimento Soares",
                            telefone: "(27) 99999-9999",
                            cpf: "000.000.000-00",
                            endereco: "Rua X, 123, Bairro Y, Alfredo Chaves - ES",
                          );

                          setState(() => isLogged = true);
                        } finally {
                          if (ctx.mounted) setState(() => isLogging = false);
                        }
                      }

                      return AlertDialog(
                        backgroundColor: const Color(0xFF141418),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Dados para envio'),
                        content: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isLogged
                                            ? "✅ Logado (dados preenchidos)"
                                            : "Quer preencher automático?",
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    /*
                                    ElevatedButton.icon(
                                      onPressed: isLogging ? null : handleLogin,
                                      icon: isLogging
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                          : const Icon(Icons.login),
                                      label: Text(isLogging ? "Entrando..." : "Entrar"),
                                    ),
                                    */
                                  ],
                                ),
                                const SizedBox(height: 12),

                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(labelText: 'Nome completo'),
                                  validator: (v) {
                                    if (v == null || v.trim().length < 3) {
                                      return 'Informe o nome completo';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefone (WhatsApp)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [phoneMask],
                                  validator: (v) {
                                    if (v == null ||
                                        v.isEmpty ||
                                        phoneMask.getUnmaskedText().length < 10) {
                                      return 'Informe um telefone válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: cpfController,
                                  decoration: const InputDecoration(labelText: 'CPF'),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [cpfMask],
                                  validator: (v) {
                                    if (v == null ||
                                        v.isEmpty ||
                                        cpfMask.getUnmaskedText().length != 11) {
                                      return 'Informe um CPF válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Endereço completo de entrega',
                                    hintText: 'Rua, número, bairro, cidade, UF, complemento',
                                  ),
                                  maxLines: 3,
                                  validator: (v) {
                                    if (v == null || v.trim().length < 10) {
                                      return 'Descreva o endereço completo';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                Navigator.of(ctx).pop({
                                  'nome': nameController.text.trim(),
                                  'telefone': phoneController.text.trim(),
                                  'cpf': cpfController.text.trim(),
                                  'endereco': addressController.text.trim(),
                                });
                              }
                            },
                            child: const Text('Continuar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (result == null) return;

              cart.setCustomerData(
                name: result['nome'] ?? '',
                phone: result['telefone'] ?? '',
                cpf: result['cpf'] ?? '',
                address: result['endereco'] ?? '',
              );

              onCheckout();
            },
            child: const Text("Finalizar pedido"),
          ),


          TextButton(
            onPressed: onClear,
            child: const Text("Limpar carrinho"),
          ),
        ],
      ),
    );
  }
}
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/cart_controller.dart';
import '../../services/auth_service.dart';
import '../../theme/fratheli_colors.dart';
import '../../utils/formatters.dart';
import '../../services/order_service.dart';

// ✅ ajuste o caminho conforme seu projeto:

class CartDrawer extends StatelessWidget {
  final TextEditingController cepController;
  final VoidCallback onClose;
  final Function(String) onCepSaved;
  final VoidCallback onCheckout;
  final VoidCallback onClear;
  final Future<void> Function(String cep) onCalculateFreight;
  static const String kWebBaseUrl = "https://frathelicafe.com.br";

  const CartDrawer({
    super.key,
    required this.cepController,
    required this.onClose,
    required this.onCepSaved,
    required this.onCheckout,
    required this.onClear,
    required this.onCalculateFreight,
  });

  Future<void> showExternalPurchaseDialog(BuildContext context) async {
    final cart = context.read<CartController>();

    final titleCtrl = TextEditingController(text: cart.externalTitle ?? '');
    final descCtrl = TextEditingController(text: cart.externalDescription ?? '');

    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: FratheliColors.surface,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Compra externa',
                style: TextStyle(color: FratheliColors.text),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: const TextStyle(color: FratheliColors.text),
                    decoration: InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ex: Retirada na loja / Compra via Instagram',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(color: FratheliColors.text),
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Detalhes…',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    cart.setCalculatedMode();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: FratheliColors.text2),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FratheliColors.gold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final t = titleCtrl.text.trim();
                    if (t.isEmpty) {
                      setLocal(() => error = 'Título é obrigatório');
                      return;
                    }
                    cart.setExternalPurchase(
                      title: t,
                      description: descCtrl.text,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _buildItems(CartController cart) {
    return cart.items.map((i) {
      final unit = double.tryParse(i.product.price.toString()) ?? 0.0;
      final qty = i.quantity;

      return {
        "sku": i.product.sku,
        "qty": qty,
        "name": i.product.name,
        "grind": i.grind,
        "unitPrice": unit,
        "lineTotal": unit * qty,
      };
    }).toList();
  }
/*
  Map<String, dynamic> _buildPayload(CartController cart) {
    final items = _buildItems(cart);

    final shipping = (cart.freightMode == FreightMode.calculated)
        ? (cart.freightValue ?? 0)
        : 0;

    return {
      "items": items,
      "subtotal": cart.subtotal,
      "shipping": shipping,
      "shippingService": cart.freightService ?? "",
      "shippingDeadline": cart.freightDeadline ?? "",

      "freightMode": cart.freightMode.name,
      "externalTitle": cart.externalTitle ?? "",
      "externalDescription": cart.externalDescription ?? "",
      "cep": cart.cep ?? "",

      "total": cart.subtotal + shipping,

      "paymentProvider": "PIX_MANUAL",
      "paymentStatus": "AGUARDANDO_PAGAMENTO",
      "shippingStatus": "AGUARDANDO_PAGAMENTO",

      "customer": {
        "name": cart.customerName ?? "",
        "phone": cart.customerPhone ?? "",
        "cpf": cart.customerCpf ?? "",
        "address": cart.customerAddress ?? "",
      }
    };
  }
*/
  Future<void> _openUrlExternal(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Não foi possível abrir $url');
    }
  }

  Future<void> _goToPixAndClear(BuildContext context, String orderCode) async {
    final url = "$kWebBaseUrl/pagamento_order.html?orderId=$orderCode";
    await _openUrlExternal(url);
    context.read<CartController>().clear();
  }

  Map<String, dynamic> _buildNormalPayload(CartController cart) {
    final items = cart.items.map((i) {
      final unit = double.tryParse(i.product.price.toString()) ?? 0.0;
      final qty = i.quantity;

      return {
        "sku": i.product.sku,
        "qty": qty,
        "name": i.product.name,
        "grind": i.grind,
        "unitPrice": unit,
        "lineTotal": unit * qty,
      };
    }).toList();

    final shippingValue = cart.freightMode == FreightMode.calculated
        ? (cart.freightValue ?? 0.0)
        : 0.0;

    final totalValue = cart.subtotal + shippingValue;

    return {
      "items": items,
      "subtotal": cart.subtotal,
      "shipping": shippingValue,
      "shippingService": cart.freightService ?? "",
      "shippingDeadline": cart.freightDeadline ?? "",
      "total": totalValue,
      "paymentProvider": "PIX_MANUAL",
      "paymentStatus": "AGUARDANDO_PAGAMENTO",
      "shippingStatus": "AGUARDANDO_PAGAMENTO",
      "customer": {
        "name": cart.customerName ?? '',
        "phone": cart.customerPhone ?? '',
        "cpf": cart.customerCpf ?? '',
        "address": cart.customerAddress ?? '',
      }
    };
  }

  Future<void> _showLoginRequiredDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login necessário'),
        content: const Text(
          'Para finalizar o pedido, você precisa entrar na sua conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login'); // ajuste se sua rota for outra
            },
            child: const Text('Fazer login'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildPayload(CartController cart, {required bool isExternal}) {
    final items = cart.items.map((i) {
      final unit = double.tryParse(i.product.price.toString()) ?? 0.0;
      final qty = i.quantity;
      return {
        "sku": i.product.sku,
        "qty": qty,
        "name": i.product.name,
        "grind": i.grind,
        "unitPrice": unit,
        "lineTotal": unit * qty,
      };
    }).toList();

    final shipping = (cart.freightMode == FreightMode.calculated)
        ? (cart.freightValue ?? 0)
        : 0.0;

    final total = cart.subtotal + shipping;

    // ✅ Payload base (orders)
    final payload = <String, dynamic>{
      "items": items,
      "subtotal": cart.subtotal,
      "shipping": isExternal ? 0 : shipping,
      "shippingService": cart.freightService ?? "",
      "shippingDeadline": cart.freightDeadline ?? "",
      "total": isExternal ? cart.subtotal : total,
      "paymentProvider": "PIX_MANUAL",
      "paymentStatus": "AGUARDANDO_PAGAMENTO",
      "shippingStatus": "AGUARDANDO_PAGAMENTO",
      "customer": {
        "name": cart.customerName ?? "",
        "phone": cart.customerPhone ?? "",
        "cpf": cart.customerCpf ?? "",
        "address": cart.customerAddress ?? "",
      },
    };

    // ✅ EXTERNA: adiciona bloco que o PHP espera
    if (isExternal) {
      payload["external"] = {
        "title": (cart.externalTitle ?? "").trim(),
        "description": (cart.externalDescription ?? "").trim(),
      };
    }

    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    final cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    final phoneMask = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    final cepMask = MaskTextInputFormatter(
      mask: '#####-###',
      filter: {"#": RegExp(r'[0-9]')},
    );

    return Container(
      width: 360,
      color: FratheliColors.bg2, // ou a cor que estiver usando
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ HEADER FIXO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Seu carrinho",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: FratheliColors.text,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: FratheliColors.text),
              ),
            ],
          ),
          const Divider(color: FratheliColors.border, height: 18),

          // ✅ SCROLL DO CARRINHO INTEIRO
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ ITENS (sem Expanded aqui!)
                  if (cart.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Seu carrinho está vazio.',
                          style: TextStyle(color: FratheliColors.text2),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FratheliColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: FratheliColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${item.product.name} (${item.grind})\nSKU: ${item.product.sku}",
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.25,
                                    color: FratheliColors.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: FratheliColors.text),
                                    onPressed: () => cart.changeQty(
                                      item.product.sku,
                                      item.grind,
                                      -1,
                                    ),
                                  ),
                                  Text(
                                    "${item.quantity}",
                                    style: const TextStyle(
                                      color: FratheliColors.text,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: FratheliColors.text),
                                    onPressed: () => cart.changeQty(
                                      item.product.sku,
                                      item.grind,
                                      1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 10),

                  // ✅ CONTINUAR COMPRANDO (mesmo do X)
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.arrow_back, color: FratheliColors.gold2),
                      label: const Text(
                        "Continuar comprando",
                        style: TextStyle(
                          color: FratheliColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: FratheliColors.surface,
                        side: const BorderSide(color: FratheliColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ ENTREGA
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FratheliColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FratheliColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Entrega",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: FratheliColors.text,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        RadioListTile<FreightMode>(
                          value: FreightMode.calculated,
                          groupValue: cart.freightMode,
                          onChanged: (v) {
                            if (v == null) return;
                            cart.setCalculatedMode();
                          },
                          title: const Text("Calcular frete pelo CEP",
                              style: TextStyle(color: FratheliColors.text)),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          activeColor: FratheliColors.gold2,
                        ),

                        RadioListTile<FreightMode>(
                          value: FreightMode.combine,
                          groupValue: cart.freightMode,
                          onChanged: (v) {
                            if (v == null) return;
                            cart.setFreightToCombine();
                          },
                          title: const Text("Frete a combinar",
                              style: TextStyle(color: FratheliColors.text)),
                          subtitle: const Text(
                            "Você combina/paga no WhatsApp após o pedido.",
                            style: TextStyle(color: FratheliColors.text2),
                          ),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          activeColor: FratheliColors.gold2,
                        ),

                        FutureBuilder<bool>(
                          future: AuthService.isAdmin(),
                          builder: (context, snap) {
                            final admin = snap.data == true;
                            if (!admin) return const SizedBox.shrink();

                            return RadioListTile<FreightMode>(
                              value: FreightMode.external,
                              groupValue: cart.freightMode,
                              onChanged: (_) async {
                                cart.setExternalMode();
                                await showExternalPurchaseDialog(context);
                                if (!cart.isExternalOk) cart.setCalculatedMode();
                              },
                              title: const Text(
                                "Compra externa",
                                style: TextStyle(color: FratheliColors.text),
                              ),
                              subtitle: Text(
                                cart.externalTitle?.isNotEmpty == true
                                    ? "Título: ${cart.externalTitle}"
                                    : "Ex: Retirada na loja / Compra via Instagram",
                                style: const TextStyle(color: FratheliColors.text2),
                              ),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              activeColor: FratheliColors.gold2,
                            );
                          },
                        ),
                        
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ CEP + CALCULAR (só se calculated)
                  if (cart.freightMode == FreightMode.calculated) ...[
                    FutureBuilder<Map<String, dynamic>?>(
                      future: AuthService.fetchClientProfile(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final profile = snapshot.data;
                          final address = profile?['address'];

                          String savedCep = '';

                          if (address is Map) {
                            savedCep = ((address['zip'] ?? address['cep']) ?? '').toString().trim();
                          }

                          if (cepController.text.trim().isEmpty && savedCep.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (cepController.text.trim().isEmpty) {
                                cepController.text = savedCep;
                              }
                            });
                          }
                        }

                        return TextField(
                          controller: cepController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [cepMask],
                          style: const TextStyle(color: FratheliColors.text),
                          decoration: InputDecoration(
                            labelText: "CEP",
                            hintText: "00000-000",
                            filled: true,
                            fillColor: FratheliColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: FratheliColors.border),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FratheliColors.gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: () async {
                          final cep = cepController.text.trim();
                          final rawCep = cep.replaceAll(RegExp(r'\D'), '');

                          if (rawCep.length != 8) {
                            showDialog(
                              context: context,
                              builder: (_) => const AlertDialog(
                                title: Text('CEP inválido'),
                                content: Text('Digite um CEP válido para calcular o frete.'),
                              ),
                            );
                            return;
                          }

                          onCepSaved(cep);
                          await onCalculateFreight(rawCep);
                        },
                        child: const Text("Calcular Frete"),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ✅ TOTAIS
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FratheliColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FratheliColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal",
                                style: TextStyle(color: FratheliColors.text2, fontWeight: FontWeight.w700)),
                            Text(brl(cart.subtotal),
                                style: const TextStyle(color: FratheliColors.text, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Frete",
                                style: TextStyle(color: FratheliColors.text2, fontWeight: FontWeight.w700)),
                            Text(
                              cart.freightMode == FreightMode.combine
                                  ? "a combinar"
                                  : (cart.freightValue != null ? brl(cart.freightValue!) : "a calcular"),
                              style: const TextStyle(color: FratheliColors.text, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: FratheliColors.border),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total",
                                style: TextStyle(color: FratheliColors.text, fontWeight: FontWeight.w900)),
                            Text(brl(cart.totalWithFreight),
                                style: const TextStyle(color: FratheliColors.text, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ FINALIZAR
    /*
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final cart = context.read<CartController>();

                        // 1) Carrinho vazio
                        if (cart.items.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Carrinho vazio'),
                              content: const Text(
                                'Adicione pelo menos um produto antes de finalizar o pedido.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        // 2) Compra externa: exige título e vai DIRETO pro Pix (bypass dados)
                        if (cart.freightMode == FreightMode.external) {
                          if (!cart.isExternalOk) {
                            await showExternalPurchaseDialog(context);
                            if (!cart.isExternalOk) return;
                          }
                          cart.customerName = cart.externalTitle?.trim(); // ✅ título vira nome
                          onCheckout(); // ✅ direto Pix
                          return;
                        }

                        // 3) Só exige CEP e frete calculado se o modo for "calculated"
                        if (cart.freightMode == FreightMode.calculated) {
                          final cep = cepController.text.trim();
                          final rawCep = cep.replaceAll(RegExp(r'\D'), '');

                          if (rawCep.length != 8) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('CEP obrigatório'),
                                content: const Text('Informe um CEP válido para calcular o frete.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Fechar'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          if (cart.freightValue == null) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Frete não calculado'),
                                content: const Text('Calcule o frete antes de finalizar o pedido.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Fechar'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          // Salva o CEP no controller
                          onCepSaved(cep);
                        }

                        // 4) Para os outros modos (calculated/free/combine): pede dados do cliente
                        final result = await showDialog<Map<String, String>>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) {
                            final formKey = GlobalKey<FormState>();

                            final nameController = TextEditingController();
                            final phoneController = TextEditingController();
                            final cpfController = TextEditingController();
                            final addressController = TextEditingController();

                            bool didPrefill = false;

                            Future<void> prefillFromProfile() async {
                              try {
                                final data = await AuthService.fetchClientProfile(); // GET /api/account/...
                                // esperado: { cpf, phone, address_json }
                                if (data == null) return;

                                final cpf = (data['cpf'] ?? '').toString();
                                final phone = (data['phone'] ?? '').toString();
                                cpfController.text = cpf;
                                phoneController.text = phone;

                                final addr = data['address'];
                                if (addr is Map) {
                                  final street = (addr['street'] ?? '').toString();
                                  final cep = (addr['cep'] ?? '').toString();
                                  addressController.text = cep.isNotEmpty ? "$street\nCEP $cep" : street;
                                } else if (data['address_json'] != null) {
                                  // se vier como string JSON
                                  try {
                                    final m = jsonDecode(data['address_json'].toString());
                                    if (m is Map) {
                                      final street = (m['street'] ?? '').toString();
                                      final cep = (m['cep'] ?? '').toString();
                                      addressController.text = cep.isNotEmpty ? "$street\nCEP $cep" : street;
                                    }
                                  } catch (_) {}
                                }
                              } catch (_) {
                                // se falhar, segue sem preencher
                              }
                            }


                            bool isLogging = false;
                            bool isLogged = false;

                            void fillFields({
                              required String nome,
                              required String telefone,
                              required String cpf,
                              required String endereco,
                            }) {
                              nameController.text = nome;
                              phoneController.text = telefone;
                              cpfController.text = cpf;
                              addressController.text = endereco;
                            }

                            return StatefulBuilder(
                              builder: (ctx, setState) {
                                if (!didPrefill) {
                                  didPrefill = true;
                                  Future.microtask(() async {
                                    await prefillFromProfile();
                                    if (ctx.mounted) setState(() {});
                                  });
                                }
                                Future<void> handleLogin() async {
                                  try {
                                    setState(() => isLogging = true);

                                    // EXEMPLO (simulado):
                                    await Future.delayed(const Duration(milliseconds: 400));
                                    fillFields(
                                      nome: "Francis do Nascimento Soares",
                                      telefone: "(27) 99999-9999",
                                      cpf: "000.000.000-00",
                                      endereco: "Rua X, 123, Bairro Y, Alfredo Chaves - ES",
                                    );

                                    setState(() => isLogged = true);
                                  } finally {
                                    if (ctx.mounted) setState(() => isLogging = false);
                                  }
                                }

                                return AlertDialog(
                                  backgroundColor: const Color(0xFF141418),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Dados para envio'),
                                  content: Form(
                                    key: formKey,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  isLogged
                                                      ? "✅ Logado (dados preenchidos)"
                                                      : "Quer preencher automático?",
                                                  style: const TextStyle(color: Colors.white70),
                                                ),
                                              ),
                                              /*
                                    ElevatedButton.icon(
                                      onPressed: isLogging ? null : handleLogin,
                                      icon: isLogging
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                          : const Icon(Icons.login),
                                      label: Text(isLogging ? "Entrando..." : "Entrar"),
                                    ),
                                    */
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          TextFormField(
                                            controller: nameController,
                                            decoration: const InputDecoration(labelText: 'Nome completo'),
                                            validator: (v) {
                                              if (v == null || v.trim().length < 3) {
                                                return 'Informe o nome completo';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: phoneController,
                                            decoration: const InputDecoration(
                                              labelText: 'Telefone (WhatsApp)',
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [phoneMask],
                                            validator: (v) {
                                              if (v == null ||
                                                  v.isEmpty ||
                                                  phoneMask.getUnmaskedText().length < 10) {
                                                return 'Informe um telefone válido';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: cpfController,
                                            decoration: const InputDecoration(labelText: 'CPF'),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [cpfMask],
                                            validator: (v) {
                                              if (v == null ||
                                                  v.isEmpty ||
                                                  cpfMask.getUnmaskedText().length != 11) {
                                                return 'Informe um CPF válido';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: addressController,
                                            decoration: const InputDecoration(
                                              labelText: 'Endereço completo de entrega',
                                              hintText: 'Rua, número, bairro, cidade, UF, complemento',
                                            ),
                                            maxLines: 3,
                                            validator: (v) {
                                              if (v == null || v.trim().length < 10) {
                                                return 'Descreva o endereço completo';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (!(formKey.currentState?.validate() ?? false)) return;

                                        // ✅ salva/atualiza perfil no SQL
                                        try {
                                          await AuthService.upsertClientProfile(
                                            cpf: cpfController.text.trim(),
                                            phone: phoneController.text.trim(),
                                            address: {
                                              'street': addressController.text.trim(),
                                              // se quiser guardar o cep do carrinho também:
                                              'cep': cepController.text.trim(),
                                            },
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Não consegui salvar seu cadastro: $e')),
                                            );
                                          }
                                          // mesmo com erro, pode deixar continuar:
                                        }

                                        Navigator.of(ctx).pop({
                                          'nome': nameController.text.trim(),
                                          'telefone': phoneController.text.trim(),
                                          'cpf': cpfController.text.trim(),
                                          'endereco': addressController.text.trim(),
                                        });
                                      },
                                      child: const Text('Continuar'),
                                    ),

                                  ],
                                );
                              },
                            );
                          },
                        );

                        if (result == null) return;

                        cart.setCustomerData(
                          name: result['nome'] ?? '',
                          phone: result['telefone'] ?? '',
                          cpf: result['cpf'] ?? '',
                          address: result['endereco'] ?? '',
                        );

                        onCheckout();
                      },
                      child: const Text("Finalizar pedido"),
                    ),

                  ),
                  */
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final cart = context.read<CartController>();

                        // 1️⃣ Carrinho vazio
                        if (cart.items.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => const AlertDialog(
                              title: Text('Carrinho vazio'),
                              content: Text(
                                'Adicione pelo menos um produto antes de finalizar o pedido.',
                              ),
                            ),
                          );
                          return;
                        }

                        // ✅ COMPRA EXTERNA: exige título, mas AINDA cria o pedido aqui
                        /*
                        if (cart.freightMode == FreightMode.external) {
                          if (!cart.isExternalOk) {
                            await showExternalPurchaseDialog(context);
                            if (!cart.isExternalOk) return; // cancelou
                          }

                          // Preenche customer com algo mínimo (pra backend não quebrar)
                          cart.setCustomerData(
                            name: cart.externalTitle!.trim(),
                            phone: (cart.customerPhone?.trim().isNotEmpty == true) ? cart.customerPhone!.trim() : "-",
                            cpf: (cart.customerCpf?.trim().isNotEmpty == true) ? cart.customerCpf!.trim() : "-",
                            address: (cart.externalDescription?.trim().isNotEmpty == true)
                                ? cart.externalDescription!.trim()
                                : "Compra externa",
                          );

                          // ✅ pula CEP e pula dialog de endereço/CPF e continua o fluxo
                        }
                        */
                        if (cart.freightMode == FreightMode.external) {
                          final isAdmin = await AuthService.isAdmin();
                          if (!isAdmin) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Apenas administradores podem usar compra externa.')),
                              );
                            }
                            cart.setCalculatedMode();
                            return;
                          }

                          if (!cart.isExternalOk) {
                            await showExternalPurchaseDialog(context);
                            if (!cart.isExternalOk) return;
                          }

                          cart.setCustomerData(
                            name: (cart.externalTitle ?? "Compra externa").trim(),
                            phone: (cart.customerPhone?.trim().isNotEmpty == true) ? cart.customerPhone!.trim() : "-",
                            cpf: (cart.customerCpf?.trim().isNotEmpty == true) ? cart.customerCpf!.trim() : "-",
                            address: (cart.externalDescription?.trim().isNotEmpty == true)
                                ? cart.externalDescription!.trim()
                                : "Compra externa",
                          );

                          final payload = _buildPayload(cart, isExternal: true);

                          final orderCode = await OrderService.createExternalOrder(payload);
                          await _goToPixAndClear(context, orderCode);
                          return;
                        }

                        // 2️⃣ Validação de frete calculado
                        if (cart.freightMode == FreightMode.calculated) {
                          final cep = cepController.text.trim();
                          final rawCep = cep.replaceAll(RegExp(r'\D'), '');

                          if (rawCep.length != 8) {
                            showDialog(
                              context: context,
                              builder: (_) => const AlertDialog(
                                title: Text('CEP obrigatório'),
                                content: Text('Informe um CEP válido para calcular o frete.'),
                              ),
                            );
                            return;
                          }

                          if (cart.freightValue == null) {
                            showDialog(
                              context: context,
                              builder: (_) => const AlertDialog(
                                title: Text('Frete não calculado'),
                                content: Text('Calcule o frete antes de finalizar o pedido.'),
                              ),
                            );
                            return;
                          }

                          onCepSaved(cep);
                        }



                        // 2.5️⃣ Verifica autenticação
                        final token = await AuthService.getToken();
                        if (token == null || token.trim().isEmpty) {
                          await _showLoginRequiredDialog(context);
                          return;
                        }

// 2.6️⃣ Carrega dados para pré-preencher o formulário
                        String initialName = '';
                        String initialPhone = '';
                        String initialCpf = '';
                        String initialAddress = '';

                        final user = await AuthService.getUser();
                        if (user != null) {
                          initialName = (user['name'] ?? '').toString().trim();
                        }

                        final profile = await AuthService.fetchClientProfile();
                        if (profile != null) {
                          initialPhone = (profile['phone'] ?? '').toString().trim();
                          initialCpf = (profile['cpf'] ?? '').toString().trim();

                          final address = profile['address'];

                          if (address is Map) {
                            final street = (address['street'] ?? '').toString().trim();
                            final number = (address['number'] ?? '').toString().trim();
                            final neighborhood = (address['neighborhood'] ?? '').toString().trim();
                            final city = (address['city'] ?? '').toString().trim();
                            final state = (address['state'] ?? '').toString().trim();
                            final typedCep = cepController.text.trim();
                            final zip = typedCep.isNotEmpty
                                ? typedCep
                                : ((address['zip'] ?? address['cep']) ?? '').toString().trim();
                            final complement = (address['complement'] ?? '').toString().trim();

                            final parts = <String>[
                              if (street.isNotEmpty) street,
                              if (number.isNotEmpty) number,
                              if (complement.isNotEmpty) complement,
                              if (neighborhood.isNotEmpty) neighborhood,
                              if (city.isNotEmpty) city,
                              if (state.isNotEmpty) state,
                              if (zip.isNotEmpty) 'CEP: $zip',
                            ];

                            initialAddress = parts.join(', ');
                          } else {
                            initialAddress = (profile['address'] ?? '').toString().trim();
                          }
                        }

// 3️⃣ Dialog para dados do cliente
                        final result = await showDialog<Map<String, String>>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) {
                            final formKey = GlobalKey<FormState>();
                            final nameController = TextEditingController(text: initialName);
                            final phoneController = TextEditingController(text: initialPhone);
                            final cpfController = TextEditingController(text: initialCpf);
                            final addressController = TextEditingController(text: initialAddress);

                            return AlertDialog(
                              backgroundColor: FratheliColors.surface,
                              surfaceTintColor: Colors.transparent,
                              title: const Text(
                                'Dados para envio',
                                style: TextStyle(
                                  color: FratheliColors.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              content: Form(
                                key: formKey,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: nameController,
                                        style: const TextStyle(color: FratheliColors.text),
                                        decoration: const InputDecoration(
                                          labelText: 'Nome completo',
                                          labelStyle: TextStyle(color: FratheliColors.text2),
                                          filled: true,
                                          fillColor: FratheliColors.surfaceAlt,
                                        ),
                                        validator: (v) =>
                                        v == null || v.trim().length < 3
                                            ? 'Informe o nome completo'
                                            : null,
                                      ),

                                      const SizedBox(height: 10),

                                      TextFormField(
                                        controller: phoneController,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [phoneMask],
                                        style: const TextStyle(color: FratheliColors.text),
                                        decoration: const InputDecoration(
                                          labelText: 'Telefone (WhatsApp)',
                                          labelStyle: TextStyle(color: FratheliColors.text2),
                                          filled: true,
                                          fillColor: FratheliColors.surfaceAlt,
                                        ),
                                        validator: (v) {
                                          final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                                          if (digits.length < 10) return 'Telefone inválido';
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 10),

                                      TextFormField(
                                        controller: cpfController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [cpfMask],
                                        style: const TextStyle(color: FratheliColors.text),
                                        decoration: const InputDecoration(
                                          labelText: 'CPF',
                                          labelStyle: TextStyle(color: FratheliColors.text2),
                                          filled: true,
                                          fillColor: FratheliColors.surfaceAlt,
                                        ),
                                        validator: (v) {
                                          final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                                          if (digits.length != 11) return 'CPF inválido';
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 10),

                                      TextFormField(
                                        controller: addressController,
                                        style: const TextStyle(color: FratheliColors.text),
                                        decoration: const InputDecoration(
                                          labelText: 'Endereço completo',
                                          labelStyle: TextStyle(color: FratheliColors.text2),
                                          filled: true,
                                          fillColor: FratheliColors.surfaceAlt,
                                        ),
                                        maxLines: 3,
                                        validator: (v) =>
                                        v == null || v.trim().length < 10
                                            ? 'Endereço inválido'
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: FratheliColors.text2),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FratheliColors.gold,
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: () {
                                    if (!(formKey.currentState?.validate() ?? false)) return;

                                    Navigator.pop(ctx, {
                                      'nome': nameController.text.trim(),
                                      'telefone': phoneController.text.trim(),
                                      'cpf': cpfController.text.trim(),
                                      'endereco': addressController.text.trim(),
                                    });
                                  },
                                  child: const Text('Continuar'),
                                ),
                              ],
                            );
                          },
                        );

                        if (result == null) return;

                        final cep = cepController.text.trim();
                        var finalAddress = (result['endereco'] ?? '').trim();

                        finalAddress = finalAddress.replaceAll(
                          RegExp(r'\s*CEP:\s*\d{5}-?\d{3}', caseSensitive: false),
                          '',
                        ).trim();

                        if (cep.isNotEmpty) {
                          finalAddress = '$finalAddress\nCEP: $cep';
                        }

                        cart.setCustomerData(
                          name: result['nome'] ?? '',
                          phone: result['telefone'] ?? '',
                          cpf: result['cpf'] ?? '',
                          address: finalAddress,
                        );

                        // 4️⃣ Montar payload do pedido
                        final items = cart.items.map((i) {
                          final unit = double.tryParse(i.product.price.toString()) ?? 0.0;
                          final qty = i.quantity;

                          return {
                            "sku": i.product.sku,
                            "qty": qty,
                            "name": i.product.name,
                            "grind": i.grind,
                            "unitPrice": unit,
                            "lineTotal": unit * qty,
                          };
                        }).toList();

                        /*
                        final payload = {
                          "items": items,
                          "subtotal": cart.subtotal,
                          "shipping": cart.freightMode == FreightMode.combine
                              ? 0
                              : (cart.freightValue ?? 0),
                          "shippingService": cart.freightService ?? "",
                          "shippingDeadline": cart.freightDeadline ?? "",
                          "total": cart.totalWithFreight,
                          "paymentProvider": "PIX_MANUAL",
                          "paymentStatus": "AGUARDANDO_PAGAMENTO",
                          "shippingStatus": "AGUARDANDO_PAGAMENTO",
                          "customer": {
                            "name": cart.customerName,
                            "phone": cart.customerPhone,
                            "cpf": cart.customerCpf,
                            "address": cart.customerAddress,
                          }
                        };
                        */
                        final payload = _buildNormalPayload(cart);
/*
                        // 5️⃣ Salvar pedido no backend
                        try {
                          final created = await OrderService.createOrder(payload);
                          //final orderId = (created['id'] ?? '').toString();
                          final orderId = (created['order']?['id'] ?? '').toString(); // ✅ certo
                          cart.lastOrderId = orderId;
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao salvar pedido: $e')),
                            );
                          }
                          return;
                        }
                        */

                        // 5️⃣ Salvar pedido no backend
                        try {
                          final orderCode = await OrderService.createOrder(payload);
                          cart.lastOrderId = orderCode;
                        } catch (e) {
                          final msg = e.toString().toLowerCase();

                          if (context.mounted) {
                            if (msg.contains('usuário não autenticado') ||
                                msg.contains('usuario não autenticado') ||
                                msg.contains('usuario nao autenticado') ||
                                msg.contains('unauthorized') ||
                                msg.contains('401') ||
                                msg.contains('token inválido') ||
                                msg.contains('token invalido')) {
                              await _showLoginRequiredDialog(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao salvar pedido: $e')),
                              );
                            }
                          }
                          return;
                        }

                        // 6️⃣ Seguir para o PIX
                        onCheckout();
                      },
                      child: const Text("Finalizar pedido"),
                    ),
                  ),


    const SizedBox(height: 6),

                  TextButton(
                    onPressed: onClear,
                    child: const Text(
                      "Limpar carrinho",
                      style: TextStyle(
                        color: FratheliColors.gold2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }
}

