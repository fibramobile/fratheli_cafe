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
    required this.onCalculateFreight, // 👈
  });

/*
  Future<Map<String, dynamic>> calcularFrete(String cepDestino) async {
    final url = Uri.parse('https://frathelicafe.com.br/cotacao_frete.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cep_destino': cepDestino}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao calcular frete: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  void _mostrarOpcoesFrete(BuildContext context, Map<String, dynamic> dados) {
    final opcoes = dados['opcoes'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Opções de frete"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: opcoes.map((op) {
              return ListTile(
                title: Text(op['transportadora']),
                subtitle: Text("Prazo: ${op['prazo']}"),
                trailing: Text("R\$ ${op['valor']}"),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fechar"),
            )
          ],
        );
      },
    );
  }
*/



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
                            onPressed: () =>
                                cart.changeQty(item.product.sku, item.grind, -1),
                          ),
                          Text("${item.quantity}"),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () =>
                                cart.changeQty(item.product.sku, item.grind, 1),
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
//CEP
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
                if (cep.length < 8) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('CEP inválido'),
                      content: const Text('Digite um CEP com 8 dígitos para calcular o frete.'),
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

                onCepSaved(cep);
                await onCalculateFreight(cep);
              },
              child: const Text("Calcular Frete"),
            ),
          ),

          const SizedBox(height: 16),

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
                  Text(
                    cart.freightValue != null
                        ? "${brl(cart.freightValue!)}"
                        : "a calcular",
                  ),
                ],
              ),
              if (cart.freightService != null) ...[
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${cart.freightService} (${cart.freightDeadline})",
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
/*
          ElevatedButton(
            onPressed: () async {
              final cart = context.read<CartController>();

              // 1) Verifica se carrinho está vazio
              if (cart.items.isEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Carrinho vazio'),
                    content: const Text('Adicione pelo menos um produto antes de finalizar o pedido.'),
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

              // 2) Verifica CEP
              final cep = cepController.text.trim();
              if (cep.length < 8) {
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

              // Salva o CEP no controller (você já fazia isso)
              onCepSaved(cep);

              // 3) Abre diálogo de dados do cliente
              final result = await showDialog<Map<String, String>>(
                context: context,
                builder: (ctx) {
                  final formKey = GlobalKey<FormState>();
                  final nameController = TextEditingController();
                  final phoneController = TextEditingController();
                  final cpfController = TextEditingController();
                  final addressController = TextEditingController();

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
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                              ),
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
                              decoration: const InputDecoration(labelText: 'Telefone (WhatsApp)'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [phoneMask],
                              validator: (v) {
                                if (v == null || v.isEmpty || phoneMask.getUnmaskedText().length < 10) {
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
                                if (v == null || v.isEmpty || cpfMask.getUnmaskedText().length != 11) {
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

              // Se o usuário cancelou o diálogo
              if (result == null) return;

              // 4) Salva no CartController
              cart.setCustomerData(
                name: result['nome'] ?? '',
                phone: result['telefone'] ?? '',
                cpf: result['cpf'] ?? '',
                address: result['endereco'] ?? '',
              );

              // 5) Chama o callback de checkout (que já monta e abre o WhatsApp)
              onCheckout();
            },
            child: const Text("Finalizar pelo WhatsApp"),
          ),
          */

          ElevatedButton(
            onPressed: () async {
              final cart = context.read<CartController>();

              // 1) Carrinho vazio
              if (cart.items.isEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Carrinho vazio'),
                    content: const Text('Adicione pelo menos um produto antes de finalizar o pedido.'),
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

              // 2) CEP válido (apenas dígitos)
              final cep = cepController.text.trim();
// remove tudo que não for número (tira o "-")
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


              // 3) Frete precisa estar calculado
              if (cart.freightValue == null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Frete não calculado'),
                    content: const Text(
                      'Calcule e selecione uma opção de frete antes de finalizar o pedido.',
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

              // Salva o CEP no controller
              onCepSaved(cep);

              // 4) Dialog de dados do cliente (igual você já faz)
              final result = await showDialog<Map<String, String>>(
                context: context,
                barrierDismissible: false, // ⛔ impede fechar clicando fora
                builder: (ctx) {
                  final formKey = GlobalKey<FormState>();
                  final nameController = TextEditingController();
                  final phoneController = TextEditingController();
                  final cpfController = TextEditingController();
                  final addressController = TextEditingController();

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
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                              ),
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

/*
          ElevatedButton(
            onPressed: () {
              if (cepController.text.trim().length < 8) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('CEP obrigatório'),
                    content: const Text('Digite o CEP e calcule o frete antes de finalizar o pedido.'),
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
              onCheckout();
            },
            child: const Text("Finalizar pelo WhatsApp"),
          ),
          */
          TextButton(
            onPressed: onClear,
            child: const Text("Limpar carrinho"),
          ),
        ],
      ),
    );
  }
}
