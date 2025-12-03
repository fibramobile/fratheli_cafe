import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fratheli_cafe_web/views/widgets/accent_button.dart';
import 'package:fratheli_cafe_web/views/widgets/cart_button.dart';
import 'package:fratheli_cafe_web/views/widgets/cart_drawer.dart';
import 'package:fratheli_cafe_web/views/widgets/chip_bullet.dart';
import 'package:fratheli_cafe_web/views/widgets/header_link.dart';
import 'package:fratheli_cafe_web/views/widgets/secondary_button.dart';
import 'package:fratheli_cafe_web/views/widgets/section_header.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../utils/formatters.dart';
import '../views/widgets/section_wrapper.dart';
import 'dart:async'; // 👈 para o Timer do autoplay

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final _cepController = TextEditingController();
  bool _cartOpen = false;
  int? _visitas; // contador de visualizações
  bool _showAllFeedbacks = false;

  // --------- PRODUTOS (carregados via JSON) ----------
  List<Product> _products = [];
  bool _loadingProducts = true;
  String? _productsError;

  // 👇 NOVO: controle do carrossel de banners
  late final PageController _bannerController;
  int _currentBanner = 0;

  // Lista de banners (você cria essas imagens depois)
  final List<String> _banners = const [
    'assets/banners/banner_black_coffee.jpg',
    'assets/banners/banner_combos.jpg',
    'assets/banners/banner_novidades.jpg',
  ];

  // Config do site antigo
  static const instagramUrl = 'https://www.instagram.com/fratheli_cafe';
  static const whatsappBase = 'https://wa.me/5527996033401';
  // Base da API (onde está o api.php)
  //static const String kApiBaseUrl = "https://smapps.16mb.com/fratheli/site";
  static const String kApiBaseUrl = "https://frathelicafe.com.br/api";

// Base do site/web (onde está o pagamento_order.html)
//  static const String kWebBaseUrl = "https://smapps.16mb.com/fratheli/fratheli_site_pro_v2";
static const String kWebBaseUrl = "https://frathelicafe.com.br";
  final _cafesKey = GlobalKey();
  final _processoKey = GlobalKey();
  final _origemKey = GlobalKey();
  final _contatoKey = GlobalKey();

  ///---------------------------------------------------
  /// 👇 Feedbacks
  /// --------------------------------------------------

  List<Map<String, dynamic>> _feedbacks = [];

  final _nomeFeedbackController = TextEditingController();
  final _mensagemFeedbackController = TextEditingController();
  String? _estadoFeedback;

// Lista simples de estados (UFs)
  final List<String> _estados = const [
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA',
    'MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN',
    'RS','RO','RR','SC','SP','SE','TO',
  ];

  ///
  ///
  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;

      // Só anima se o PageController estiver anexado a um PageView
      if (!_bannerController.hasClients) return;

      if (_banners.length <= 1) return;

      final next = (_currentBanner + 1) % _banners.length;

      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    // 👇 carrega quantidade de visitas
    _carregarVisitas();
    _carregarFeedbacks(); // 👈 novo
    _loadProductsFromJson(); // 👈 AQUI CARREGA OS PRODUTOS

  }

  /// ---------------------------------------------------
  /// CARREGAR PRODUTOS A PARTIR DO JSON DE PRECIFICAÇÃO
  /// ---------------------------------------------------
  Future<void> _loadProductsFromJson() async {
    try {
      final uri = Uri.parse(
        'https://smapps.16mb.com/fratheli/app/pricings_data.php',
      );
      final resp = await http.get(uri);

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final List<dynamic> data = jsonDecode(resp.body) as List<dynamic>;

      // Mapa: nome do produto -> preço final 250g
      final Map<String, double> price250ByName = {};

      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final productName = (map['productName'] as String).trim();
        final markupPercent = (map['markupPercent'] as num).toDouble();
        final items = map['items'] as List<dynamic>;

        double totalCostPerKg = 0.0;
        for (final it in items) {
          final itMap = it as Map<String, dynamic>;
          totalCostPerKg += (itMap['costPerKg'] as num).toDouble();
        }

        // preço de venda por kg = custo * (1 + markup/100)
        final salePricePerKg = totalCostPerKg * (1 + markupPercent / 100);
        final price250 = salePricePerKg * 0.25; // 250g = 0.25 kg

        price250ByName[productName] =
            double.parse(price250.toStringAsFixed(2));
      }

      // Helper pra não quebrar se não achar algo no JSON
      double _p(String name, double fallback) {
        return price250ByName[name] ?? fallback;
      }

      // Agora montamos a lista de Product usando o JSON
      final List<Product> loaded = [
        Product(
          sku: "BUGIA-250",
          name: "Mel de Bugia - 250g",
          description:
          "Perfil floral intenso, extremamente aromático, notas de ervas frescas e camomila. Mel produzido pela abelha Uruçu Amarela (Bugia).",
          imagePath: "assets/img/cafe_bugia.jpg",
          price: _p("Mel de Bugia", 35.90),
          // preço “antigo” = 15% acima
          originalPrice: double.parse(
            (_p("Mel de Bugia", 35.90) * 1.15).toStringAsFixed(2),
          ),
          tag: "ORIGEN",
          tagAlt: false,
          meta: "Edição especial com mel de abelha nativa",
          inStock: true,
        ),
        Product(
          sku: "TIUBA-250",
          name: "Mel de Tiúba - 250g",
          description:
          "Sabor marcante, toque frutado com acidez elegante. Mel potiguar muito valorizado pela medicina popular.",
          imagePath: "assets/img/cafe_tiuba_pack.jpg",
          price: _p("Mel de Tiúba", 38.90),
          originalPrice: double.parse(
            (_p("Mel de Tiúba", 38.90) * 1.15).toStringAsFixed(2),
          ),
          tag: "PREMIUM",
          tagAlt: true,
          meta: "Abelha Rara – microlote exclusivo",
          inStock: true,
        ),
        Product(
          sku: "JATAI-250",
          name: "Mel de Jataí - 250g",
          description:
          "Mel leve, extremamente puro, textura fina e aroma suave. Um dos méis nativos mais apreciados do Brasil.",
          imagePath: "assets/img/cafe_jatai_pack.jpg",
          price: _p("Mel de Jataí", 42.90),
          originalPrice: double.parse(
            (_p("Mel de Jataí", 42.90) * 1.15).toStringAsFixed(2),
          ),
          tag: "LIMITADO",
          tagAlt: false,
          meta: "Produção limitada",
          inStock: false,
        ),
        Product(
          sku: "FLOR-250",
          name: "Flor da Mata - 250g",
          description:
          "Café artesanal gourmet com notas doces, corpo médio e finalização limpa. Perfil equilibrado e muito agradável.",
          imagePath: "assets/img/cafe_flor_da_mata.jpg",
          price: _p("Flor da Mata", 30.90), // no JSON tem um espaço no fim
          originalPrice: double.parse(
            (_p("Flor da Mata", 30.90) * 1.15).toStringAsFixed(2),
          ),
          tag: "MICROLOTE",
          tagAlt: false,
          meta: "Torra fresca sob demanda",
          inStock: false,
        ),
        // Esses ainda não estão no JSON, então mantemos preço manual por enquanto:
        Product(
          sku: "ROCA-250",
          name: "Cheiro de Roça - 250g",
          description:
          "Café tradicional das montanhas capixabas, sabor encorpado, notas de chocolate e amendoas. Ideal para o dia a dia.",
          imagePath: "assets/img/cafe_cheiro_de_roca.jpg",
          price: _p("Cheiro de Roça", 27.90),
          originalPrice: 32.00,
          tag: "Intenso",
          tagAlt: true,
          meta: "Sabor de roça",
          inStock: false,
        ),
        Product(
          sku: "PURE-250",
          name: "Pure - 250g",
          description:
          "Café tradicional das montanhas capixabas, sabor encorpado. Ideal para o dia a dia.",
          imagePath: "assets/img/cafe_cheiro_de_roca.jpg",
          price: _p("Pure", 25.80),
          originalPrice: 32.00,
          tag: "Intenso",
          tagAlt: true,
          meta: "Sabor clássico do interior",
          inStock: true,
        ),
      ];

      setState(() {
        _products = loaded;
        _loadingProducts = false;
        _productsError = null;
      });
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
      setState(() {
        _loadingProducts = false;
        _productsError = 'Não foi possível carregar os produtos.';
      });
    }
  }


  Future<void> _carregarVisitas() async {
    try {
      final uri = Uri.parse('https://frathelicafe.com.br/contador_visitas.php');
      final resp = await http.get(uri);

      if (resp.statusCode != 200) return;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (data['ok'] == true && data['total'] != null) {
        setState(() {
          _visitas = (data['total'] as num).toInt();
        });
      }
    } catch (e) {
      // Se der erro, só ignora — não vamos travar o site por causa disso
      print('Erro ao carregar visitas: $e');
    }
  }

  Future<void> _carregarFeedbacks() async {
    try {
      final uri = Uri.parse('https://frathelicafe.com.br/feedback_listar.php');
      final resp = await http.get(uri);

      if (resp.statusCode != 200) return;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['ok'] == true && data['items'] is List) {
        setState(() {
          _feedbacks =
              (data['items'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar feedbacks: $e');
    }
  }

  Future<void> _enviarFeedback() async {
    final nome = _nomeFeedbackController.text.trim();
    final estado = _estadoFeedback;
    final mensagem = _mensagemFeedbackController.text.trim();

    if (nome.isEmpty || estado == null || mensagem.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Campos obrigatórios'),
          content: const Text(
            'Por favor, preencha seu nome, selecione o estado e escreva seu feedback.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(_).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse('https://frathelicafe.com.br/feedback_enviar.php');

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'estado': estado,
          'mensagem': mensagem,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 200 && data['ok'] == true) {
        // Limpa campos
        _nomeFeedbackController.clear();
        _mensagemFeedbackController.clear();
        setState(() {
          _estadoFeedback = null;
        });

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Feedback enviado'),
            content: const Text(
              'Obrigado! Seu feedback foi recebido e será exibido no site após aprovação.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(_).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(data['erro'] ?? 'Falha ao enviar feedback');
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text('Não foi possível enviar seu feedback.\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(_).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }
/*
  Widget _buildFeedbackSection(bool isMobile) {
    final crossAxisCount = isMobile ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'O que dizem sobre os cafés Frathéli',
          subtitle: 'Depoimentos de quem já sentiu o sabor da nossa montanha na xícara.',
        ),
        const SizedBox(height: 18),

        // Lista de feedbacks aprovados
        if (_feedbacks.isNotEmpty)
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _feedbacks.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              // cards mais baixinhos
              childAspectRatio: isMobile ? 3 / 1.6 : 3 / 1.1,
            ),
            itemBuilder: (context, index) {
              final fb = _feedbacks[index];
              final nome = fb['nome'] ?? '';
              final estado = fb['estado'] ?? '';
              final mensagem = fb['mensagem'] ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mensagem,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$nome · $estado',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        else
          const Text(
            'Ainda não temos feedbacks publicados. Seja o primeiro a compartilhar sua experiência!',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

        const SizedBox(height: 28),

        // FORMULÁRIO CENTRALIZADO E MAIS ESTREITO
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deixe seu feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Nome + UF
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 260,
                      child: TextField(
                        controller: _nomeFeedbackController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 160,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Estado (UF)',
                          border: OutlineInputBorder(),
                        ),
                        value: _estadoFeedback,
                        items: _estados.map((uf) {
                          return DropdownMenuItem(
                            value: uf,
                            child: Text(uf),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _estadoFeedback = value);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Campo de feedback com altura controlada
                SizedBox(
                  height: 140,
                  child: TextField(
                    controller: _mensagemFeedbackController,
                    expands: true,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Seu feedback',
                      hintText:
                      'Conte como foi sua experiência com os cafés Frathéli...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _enviarFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Enviar feedback',
                        style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
*/
  Widget _buildFeedbackSection(bool isMobile) {
    final crossAxisCount = isMobile ? 1 : 2;

    // 🔁 Ordena para mostrar os mais recentes primeiro
    final feedbacksOrdered = List<Map<String, dynamic>>.from(_feedbacks.reversed);

    // 🔢 Quantos serão exibidos (4 ou todos)
    final visibleCount = _showAllFeedbacks
        ? feedbacksOrdered.length
        : min(4, feedbacksOrdered.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'O que dizem sobre os cafés Frathéli',
          subtitle: 'Depoimentos de quem já sentiu o sabor da nossa montanha na xícara.',
        ),
        const SizedBox(height: 18),

        // Lista de feedbacks aprovados
        if (feedbacksOrdered.isNotEmpty) ...[
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: visibleCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: isMobile ? 3 / 1.6 : 3 / 1.1,
            ),
            itemBuilder: (context, index) {
              final fb = feedbacksOrdered[index];
              final nome = fb['nome'] ?? '';
              final estado = fb['estado'] ?? '';
              final mensagem = fb['mensagem'] ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mensagem,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$nome · $estado',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 🔘 Botão Ver mais / Ver menos
          if (feedbacksOrdered.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllFeedbacks = !_showAllFeedbacks;
                    });
                  },
                  child: Text(
                    _showAllFeedbacks ? 'Ver menos depoimentos' : 'Ver mais depoimentos',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ]
        else
          const Text(
            'Ainda não temos feedbacks publicados. Seja o primeiro a compartilhar sua experiência!',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

        const SizedBox(height: 28),

        // ---------- FORMULÁRIO (igual ao anterior, mas centralizado/compacto) ----------
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deixe seu feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 260,
                      child: TextField(
                        controller: _nomeFeedbackController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 160,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Estado (UF)',
                          border: OutlineInputBorder(),
                        ),
                        value: _estadoFeedback,
                        items: _estados.map((uf) {
                          return DropdownMenuItem(
                            value: uf,
                            child: Text(uf),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _estadoFeedback = value);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 140,
                  child: TextField(
                    controller: _mensagemFeedbackController,
                    expands: true,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Seu feedback',
                      hintText:
                      'Conte como foi sua experiência com os cafés Frathéli...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _enviarFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Enviar feedback',
                        style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
/*
  Future<void> _enviarPedidoParaApi(CartController cart) async {
    final cep = _cepController.text.trim();

    // 🔹 Esses dados vêm do cart.setCustomerData(...) que você já chama no CartDrawer
    final client = {
      "name": cart.customerName ?? "",
      "cpf": cart.customerCpf ?? "",
      "phone": cart.customerPhone ?? "",
      "email": "", // se depois você pedir email no form, preenche aqui
      "address": {
        // vou colocar tudo no "street" pra não complicar split agora
        "street": cart.customerAddress ?? "",
        "number": "",
        "neighborhood": "",
        "city": "",
        "state": "",
        "cep": cep,
      }
    };

    // Itens do carrinho
    final items = cart.items.map((item) {
      return {
        "sku": item.product.sku,
        "name": "${item.product.name} (${item.grind})",
        "qty": item.quantity,
        "unitPrice": item.product.price,
      };
    }).toList();

    // 🔹 Agora usando frete real
    final double shipping = cart.freightValue ?? 0.0;
    final double total = cart.totalWithFreight;

    //const apiUrl = "https://frathelicafe.com.br/api.php?action=create-order";
    const apiUrl = "https://smapps.16mb.com/fratheli/site/api.php?action=create-order"; ///TESTE


    try {
      final resp = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "client": client,
          "items": items,
          "shipping": shipping,
          "total": total,
        }),
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pedido registrado! Nº: ${data["orderId"]}"),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao registrar pedido: ${data["error"] ?? "tente novamente"}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Falha ao enviar pedido: $e"),
        ),
      );
    }
  }
  */

  Future<String?> _enviarPedidoParaApi(CartController cart) async {
    final cep = _cepController.text.trim();

    final client = {
      "name": cart.customerName ?? "",
      "cpf": cart.customerCpf ?? "",
      "phone": cart.customerPhone ?? "",
      "email": "",
      "address": {
        "street": cart.customerAddress ?? "",
        "number": "",
        "neighborhood": "",
        "city": "",
        "state": "",
        "cep": cep,
      }
    };

    final items = cart.items.map((item) {
      return {
        "sku": item.product.sku,
        "name": "${item.product.name} (${item.grind})",
        "qty": item.quantity,
        "unitPrice": item.product.price,
      };
    }).toList();

    final double shipping = cart.freightValue ?? 0.0;
    final double total = cart.totalWithFreight;

    const apiUrl = "$kApiBaseUrl/api.php?action=create-order";

    try {
      final resp = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "client": client,
          "items": items,
          "shipping": shipping,
          "total": total,
        }),
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200 && data["success"] == true) {
        final orderId = data["orderId"] as String?;
        if (orderId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Pedido registrado! Nº: $orderId"),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return orderId;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao registrar pedido: ${data["error"] ?? "tente novamente"}",
            ),
          ),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Falha ao enviar pedido: $e"),
        ),
      );
      return null;
    }
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _cepController.dispose();
    _bannerController.dispose(); // 👈 não esquecer
    _nomeFeedbackController.dispose();
    _mensagemFeedbackController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  String _buildWhatsUrl(String text) {
    final join = whatsappBase.contains('?') ? '&' : '?';
    return '$whatsappBase${join}text=${Uri.encodeComponent(text)}';
  }

  void _openCart() {
    setState(() => _cartOpen = true);
  }

  void _closeCart() {
    setState(() => _cartOpen = false);
  }

/*
  // HERO / CARROSSEL DE BANNERS
  Widget _buildHeroSection(bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1300), // 👈 reduz largura máxima
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 40, // 👈 margem maior em cima/baixo
            horizontal: 60, // 👈 margem mediana nas laterais
          ),
          child: AspectRatio(
            aspectRatio: 16 / 6.3, // 👈 ligeiramente mais “alto”
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28), // 👈 bordas maiores
              child: Stack(
                children: [
                  // BANNERS
                  PageView.builder(
                    controller: _bannerController,
                    itemCount: _banners.length,
                    onPageChanged: (index) {
                      setState(() => _currentBanner = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _banners[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),

                  // SETA ESQUERDA
                  if (!isMobile)
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _CarouselArrow(
                          icon: Icons.chevron_left,
                          onTap: () {
                            final prev = _currentBanner == 0
                                ? _banners.length - 1
                                : _currentBanner - 1;
                            _bannerController.animateToPage(
                              prev,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),

                  // SETA DIREITA
                  if (!isMobile)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _CarouselArrow(
                          icon: Icons.chevron_right,
                          onTap: () {
                            final next = (_currentBanner + 1) % _banners.length;
                            _bannerController.animateToPage(
                              next,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),

                  // INDICADORES
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (index) {
                        final isActive = index == _currentBanner;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 20 : 10,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  */

  // HERO
  Widget _buildHeroSection(bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 38),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: isMobile ? 0 : 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Microlotes de café especial com identidade de montanha',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cafés de origem única produzidos no Sítio Sombra da Mata, '
                          'em Alfredo Chaves–ES (700 m), com manejo cuidadoso, '
                          'torra artesanal e edições exclusivas com mel de abelhas nativas.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChipBullet('100% Arábica · Catucaí 2SL · Arara · Catuaí'),
                        ChipBullet('Microlotes rastreáveis'),
                        ChipBullet('Venda direta do produtor'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        AccentButton(
                          label: 'Comprar pelo WhatsApp',
                          icon: FontAwesomeIcons.whatsapp,
                          color: Colors.green,
                          textColor: Colors.white,
                          onTap: () {
                            const msg =
                                'Olá! Gostaria de saber mais sobre os cafés Frathéli.';
                            _openWhats(msg);
                          },
                        ),
                        SecondaryButton(
                          label: 'Conhecer os cafés',
                          onTap: () => _scrollTo(_cafesKey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 38, height: 38),
              Expanded(
                flex: isMobile ? 0 : 9,
                child: Align(
                  alignment:
                  isMobile ? Alignment.center : Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border:
                      Border.all(color: Colors.white.withOpacity(0.06)),
                      gradient: const RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.2,
                        colors: [
                          Color.fromARGB(48, 212, 175, 55),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 380, // 👈 limite para desktop
                        maxHeight: 450,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/img/ad_preview.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  Future<void> _calcularFrete(BuildContext context, String cep) async {
    final cart = context.read<CartController>();

    try {
      final uri = Uri.parse(
        'https://frathelicafe.com.br/cotacao_frete.php?cep=$cep',
      );

      final resp = await http.get(uri);

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (data['ok'] != true) {
        throw Exception(data['erro'] ?? 'Falha ao calcular frete');
      }

      final opcoes = (data['opcoes'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (opcoes.isEmpty) {
        throw Exception('Nenhuma opção de frete retornada.');
      }

      // Dialog para escolher uma opção
      final selecionada = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: const Color(0xFF141418),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Opções de frete',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: opcoes.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final op = opcoes[index];
                          final nome = op['transportadora'] as String? ?? 'Frete';
                          final valor = (op['valor'] as num).toDouble();
                          final prazo = op['prazo'] as String? ?? '';

                          return ListTile(
                            onTap: () => Navigator.of(context).pop(op),
                            title: Text(
                              nome,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              prazo,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            trailing: Text(
                              brl(valor),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (selecionada != null) {
        final valor = (selecionada['valor'] as num).toDouble();
        final nome = selecionada['transportadora'] as String? ?? 'Frete';
        final prazo = selecionada['prazo'] as String? ?? '';

        cart.setFreight(
          value: valor,
          service: nome,
          prazo: prazo,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Frete selecionado: ${brl(valor)} — $nome'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text('Não foi possível calcular o frete.\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }
*/

  Future<void> _calcularFrete(BuildContext context, String cep) async {
    final cart = context.read<CartController>();

    try {
      // ---- NOVO: calcular quantidade total de pacotes ----
      final totalPacotes = cart.items.fold<int>(
        0,
            (soma, item) => soma + item.quantity,
      );

      print('📦 Total de pacotes enviados para o servidor: $totalPacotes');

      // ---- NOVO: enviar também a quantidade ----
      final uri = Uri.parse(
        'https://frathelicafe.com.br/cotacao_frete.php',
      ).replace(
        queryParameters: {
          'cep': cep,
          'qtd': totalPacotes.toString(),
        },
      );

      final resp = await http.get(uri);

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (data['ok'] != true) {
        throw Exception(data['erro'] ?? 'Falha ao calcular frete');
      }

      final opcoes = (data['opcoes'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (opcoes.isEmpty) {
        throw Exception('Nenhuma opção de frete retornada.');
      }

      // Dialog para escolher uma opção
      final selecionada = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: const Color(0xFF141418),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Opções de frete',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: opcoes.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final op = opcoes[index];
                          final nome = op['transportadora'] as String? ?? 'Frete';
                          final valor = (op['valor'] as num).toDouble();
                          final prazo = op['prazo'] as String? ?? '';

                          return ListTile(
                            onTap: () => Navigator.of(context).pop(op),
                            title: Text(
                              nome,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              prazo,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            trailing: Text(
                              brl(valor),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (selecionada != null) {
        final valor = (selecionada['valor'] as num).toDouble();
        final nome = selecionada['transportadora'] as String? ?? 'Frete';
        final prazo = selecionada['prazo'] as String? ?? '';

        cart.setFreight(
          value: valor,
          service: nome,
          prazo: prazo,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Frete selecionado: ${brl(valor)} — $nome'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF141418),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'CEP não encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          content: const Text(
            'Não conseguimos calcular o frete para este CEP.\n\n'
                'Verifique se o número está correto e tente novamente.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Ok, entendi',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      );
    }

  }

  ///----------------------------------------------------
  ///                     Build Principal
  /// ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 960;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0B0C),
                  Color(0xFF0E0F14),
                  Color(0xFF0B0B0C),
                ],
              ),
            ),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, cart, isMobile),
                ),
                SliverToBoxAdapter(
                  child: _buildHeroSection(isMobile),
                ),
                SliverToBoxAdapter(
                  child: SectionWrapper(
                    key: _cafesKey,
                    child: _buildCafesSection(context, isMobile),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SectionWrapper(
                    key: _processoKey,
                    alt: true,
                    child: _buildProcessSection(isMobile),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SectionWrapper(
                    key: _origemKey,
                    child: _buildOriginSection(isMobile),
                  ),
                ),
                // 👇 NOVO: feedbacks
                SliverToBoxAdapter(
                  child: SectionWrapper(
                    child: _buildFeedbackSection(isMobile),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SectionWrapper(
                    key: _contatoKey,
                    child: _buildContactSection(),
                  ),
                ),
                SliverToBoxAdapter(child: _buildFooter()),
              ],
            ),
          ),

          // Backdrop do carrinho
          if (_cartOpen)
            GestureDetector(
              onTap: _closeCart,
              child: Container(
                color: Colors.black.withOpacity(0.55),
              ),
            ),

          // Drawer do carrinho
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            top: 0,
            bottom: 0,
            right: _cartOpen ? 0.0 : -min(width, 360.0),
            child: CartDrawer(
              cepController: _cepController,
              onClose: _closeCart,
              onCepSaved: (cep) {
                context.read<CartController>().setCep(cep);
               /*
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'CEP registrado! Vamos calcular o frete e te enviar o orçamento pelo WhatsApp.',
                    ),
                  ),
                );
                */
              },
/*
              onCheckout: () async {
                if (cart.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seu carrinho está vazio.'),
                    ),
                  );
                  return;
                }

                // 1) Envia o pedido para a API PHP (salva clients.json e orders.json)
                await _enviarPedidoParaApi(cart);

                // 2) Mantém o fluxo atual pelo WhatsApp (por enquanto)
                final msg = cart.buildWhatsMessage();
                _openUrl(_buildWhatsUrl(msg));
              },
*/
              onCheckout: () async {
                if (cart.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seu carrinho está vazio.'),
                    ),
                  );
                  return;
                }

                // 1) Registra pedido na API e pega orderId
                final orderId = await _enviarPedidoParaApi(cart);

                if (orderId == null) {
                  // se deu erro, não segue
                  return;
                }

                // 2) Abre a página de pagamento desse pedido
                //final url = "https://frathelicafe.com.br/pagamento.html?orderId=$orderId";
                final url = "$kWebBaseUrl/pagamento_order.html?orderId=$orderId";
                _openUrl(url);
              },

/*
              onCheckout: () {
                if (cart.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seu carrinho está vazio.'),
                    ),
                  );
                  return;
                }
                final msg = cart.buildWhatsMessage();
                _openUrl(_buildWhatsUrl(msg));
              },
              */
              onClear: () => context.read<CartController>().clear(),
              onCalculateFreight: (cep) => _calcularFrete(context, cep), // 👈
            ),
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader(
      BuildContext context, CartController cart, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0C).withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0x15FFFFFF)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/img/logo_branco.png',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 10),
                  const Text.rich(
                    TextSpan(
                      text: 'FRATHÉLI ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.04,
                      ),
                      children: [
                        TextSpan(
                          text: 'CAFÉ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isMobile)
                Row(
                  children: [
                    HeaderLink(
                      label: 'Cafés especiais',
                      onTap: () => _scrollTo(_cafesKey),
                    ),
                    HeaderLink(
                      label: 'Processo',
                      onTap: () => _scrollTo(_processoKey),
                    ),
                    HeaderLink(
                      label: 'Origem',
                      onTap: () => _scrollTo(_origemKey),
                    ),
                    HeaderLink(
                      label: 'Contato',
                      onTap: () => _scrollTo(_contatoKey),
                    ),
                    const SizedBox(width: 10),
                    AccentButton(
                      label: 'Instagram',
                      icon: FontAwesomeIcons.instagram,
                      color: Color(0xFFE1306C),
                      textColor: Colors.white,
                      onTap: () => _openUrl(instagramUrl),
                    ),
                    const SizedBox(width: 12),
                    CartButton(
                      count: cart.totalItems,
                      onTap: _openCart,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    CartButton(
                      count: cart.totalItems,
                      onTap: _openCart,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _openWhats(String msg) async {
    final join = whatsappBase.contains('?') ? '&' : '?';
    final url = '$whatsappBase${join}text=${Uri.encodeComponent(msg)}';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  // SEÇÃO CAFÉS
  /*
  Widget _buildCafesSection(BuildContext context, bool isMobile) {
    final products = _products;
    final crossAxisCount = isMobile ? 1 : MediaQuery.of(context).size.width < 960 ? 2 : 3;
    final cartController = context.read<CartController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Cafés especiais Frathéli',
          subtitle:
          'Microlotes limitados, perfis sensoriais únicos e torra fresca sob demanda.',
        ),
        const SizedBox(height: 18),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 4 / 5,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              onAdd: (grind) {
                cartController.addProduct(product, grind);
                _openCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} ($grind) adicionado ao carrinho.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );


          },
        ),
      ],
    );
  }
  */
  Widget _buildCafesSection(BuildContext context, bool isMobile) {
    final cartController = context.read<CartController>();
    final crossAxisCount =
    isMobile ? 1 : MediaQuery.of(context).size.width < 960 ? 2 : 3;

    if (_loadingProducts) {
      // enquanto busca o JSON, mostra um loading
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_productsError != null) {
      // se deu erro no carregamento
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Cafés especiais Frathéli',
            subtitle:
            'Microlotes limitados, perfis sensoriais únicos e torra fresca sob demanda.',
          ),
          const SizedBox(height: 12),
          Text(
            _productsError!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
      );
    }

    if (_products.isEmpty) {
      // não deu erro, mas veio vazio
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'Cafés especiais Frathéli',
            subtitle:
            'Microlotes limitados, perfis sensoriais únicos e torra fresca sob demanda.',
          ),
          SizedBox(height: 12),
          Text(
            'Nenhum produto disponível no momento.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    final products = _products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Cafés especiais Frathéli',
          subtitle:
          'Microlotes limitados, perfis sensoriais únicos e torra fresca sob demanda.',
        ),
        const SizedBox(height: 18),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 4 / 5,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              onAdd: (grind) {
                cartController.addProduct(product, grind);
                _openCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${product.name} ($grind) adicionado ao carrinho.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }


  // SEÇÃO PROCESSO
  Widget _buildProcessSection(bool isMobile) {
    final steps = [
      {
        'title': 'Colheita seletiva',
        'desc':
        'Colhemos manualmente apenas frutos maduros, garantindo doçura natural e uniformidade no lote.',
      },
      {
        'title': 'Beneficiamento com mel de abelhas nativas',
        'desc':
        'Processo de secagem natural, grãos untados com mel de abelhas nativas, classificação e separação artesanal',
      },
      {
        'title': 'Torra profissional',
        'desc':
        'Perfil de torra ideal para realçar as melhores notas sensoriais.',
      },
    ];

    final crossAxisCount = isMobile ? 1 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Nosso processo',
          subtitle:
          'Do pé de café à xícara, cada etapa é controlada pelo próprio produtor.',
        ),
        const SizedBox(height: 18),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: steps.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: isMobile ? 4 / 2 : 4 / 3,
          ),
          itemBuilder: (context, index) {
            final step = steps[index];
            return _ProcessCard(
              index: index + 1,
              title: step['title']!,
              description: step['desc']!,
            );
          },
        ),
      ],
    );
  }

  // SEÇÃO ORIGEM
  Widget _buildOriginSection(bool isMobile) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: isMobile ? 0 : 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Origem Frathéli Café',
                subtitle:
                'Cafés de montanha capixaba com integração à meliponicultura.',
              ),
              const SizedBox(height: 12),
              Text(
                'O Frathéli Café nasce no Sítio Sombra da Mata, em Alfredo Chaves–ES, '
                    'região de montanha acima de 700 m de altitude, com clima ameno, brisas frescas '
                    'e solo propício para cafés doces e complexos.',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                  "Cultivamos de forma familiar, com práticas sustentáveis, "
                      "preservação da natureza e integração com abelhas nativas."
                      " Cada microlote é rastreável, artesanal e expressa o terroir da nossa região.",
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChipBullet('Cafés de montanha capixaba'),
                  ChipBullet('Catucaí 2SL e seleções especiais'),
                  ChipBullet('Integração com meliponicultura (abelhas nativas)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18, height: 18),
        Expanded(
          flex: isMobile ? 0 : 9,
          child: Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0E0F14),
                    Color(0xFF0A0B0D),
                  ],
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/img/logo_branco.png',
                  width: 86,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SEÇÃO CONTATO
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const
        SectionHeader(
          title: 'Fale com a Frathéli Café',
          subtitle: 'Pedidos, parcerias, atacado e projetos especiais de café.',
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AccentButton(
                label: 'WhatsApp',
                icon: FontAwesomeIcons.whatsapp,
                color: Colors.green,
                textColor: Colors.white,
                onTap: () {
                  const msg =
                      'Olá! Gostaria de saber mais sobre os cafés Frathéli.';
                  _openWhats(msg);
                },
              ),
              SecondaryButton(
                label: '@fratheli_cafe',
                onTap: () => _openUrl(instagramUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // FOOTER
  Widget _buildFooter() {
    final year = DateTime.now().year;
    final visitasTexto = _visitas != null
        ? ' · $_visitas visitas registradas'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          '© $year Frathéli Café · Cafés especiais · Alfredo Chaves–ES$visitasTexto',
          style: const TextStyle(
            color: Color(0xFF8F94A3),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
 /*
  // PRODUTOS
  List<Product> get _products => const [
    Product(
      sku: "BUGIA-250",
      name: "Mel de Bugia - 250g",
      description:
      "Perfil floral intenso, extremamente aromático, notas de ervas frescas e camomila. Mel produzido pela abelha Uruçu Amarela (Bugia).",
      imagePath: "assets/img/cafe_bugia.jpg",
      price: 35.90,          // preço atual (com desconto)
      originalPrice: 52.90,  // 👈 preço antigo (vai aparecer cortado)
      tag: "ORIGEN",
      tagAlt: false,
      meta: "Edição especial com mel de abelha nativa",
      inStock: true,
    ),
    Product(
      sku: "TIUBA-250",
      name: "Mel de Tiúba - 250g",
      description:
      "Sabor marcante, toque frutado com acidez elegante. Mel potiguar muito valorizado pela medicina popular.",
      imagePath: "assets/img/cafe_tiuba_pack.jpg",
      price: 38.90,
      originalPrice: 55.90,
      tag: "PREMIUM",
      tagAlt: true,
      meta: "Abelha Rara – microlote exclusivo",
      inStock: true,
    ),
    Product(
      sku: "JATAI-250",
      name: "Mel de Jataí - 250g",
      description:
      "Mel leve, extremamente puro, textura fina e aroma suave. Um dos méis nativos mais apreciados do Brasil.",
      imagePath: "assets/img/cafe_jatai_pack.jpg",
      price: 42.90,
      originalPrice: 60.00,
      tag: "LIMITADO",
      tagAlt: false,
      meta: "Produção limitada",
      inStock: false,
    ),
    Product(
      sku: "FLOR-250",
      name: "Flor da Mata - 250g",
      description:
      "Café artesanal gourmet com notas doces, corpo médio e finalização limpa. Perfil equilibrado e muito agradável.",
      imagePath: "assets/img/cafe_flor_da_mata.jpg",
      price: 30.90,
      originalPrice: 35.90,
      tag: "MICROLOTE",
      tagAlt: false,
      meta: "Torra fresca sob demanda",
      inStock: false,
    ),
    Product(
      sku: "ROCA-250",
      name: "Cheiro de Roça - 250g",
      description:
      "Café tradicional das montanhas capixabas, sabor encorpado, notas de chocolate e amendoas. Ideal para o dia a dia.",
      imagePath: "assets/img/cafe_cheiro_de_roca.jpg",
      price: 27.90,
      originalPrice: 32.00,
      tag: "Intenso",
      tagAlt: true,
      meta: "Sabor de roça",
      inStock: false,
    ),
    Product(
      sku: "PURE-250",
      name: "Pure - 250g",
      description:
      "Café tradicional das montanhas capixabas, sabor encorpado. Ideal para o dia a dia.",
      imagePath: "assets/img/cafe_cheiro_de_roca.jpg",
      price: 25.80,
      originalPrice: 32.00,
      tag: "Intenso",
      tagAlt: true,
      meta: "Sabor clássico do interior",
      inStock: true,
    ),
  ];
  */
}

void showGrindRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final width = MediaQuery.of(context).size.width;

      return Dialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 380,   // 👈 limite máximo no desktop
            minWidth: 280,   // 👈 não deixa ficar pequeno demais
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione uma opção',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Escolha se deseja o café em grãos ou moído antes de adicionar ao carrinho.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Entendi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final void Function(String grind) onAdd; // recebe "Grão" ou "Moído"

  const _ProductCard({
    required this.product,
    required this.onAdd,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  //String _selectedGrind = 'Grão'; // valor padrão
  String? _selectedGrind; // começa sem nada

  @override
  void initState() {
    super.initState();

    // Se for café que só vende moído, já fixa como "Moído"
    final sku = widget.product.sku;
    if (sku == "ROCA-250" || sku == "FLOR-250") {
      _selectedGrind = "Moído";
    } else {
      _selectedGrind = null; // obriga o cliente a escolher
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // DESCONTO
    final bool hasDiscount =
        product.originalPrice != null && product.originalPrice! > product.price;

    int? discountPercent;
    if (hasDiscount) {
      discountPercent = (((product.originalPrice! - product.price) /
          product.originalPrice!) *
          100)
          .round();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOTO
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: () => showProductImageDialog(context, product),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.asset(
                    product.imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // TAG (opcional)
          if (product.tag != null && product.tag!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: product.tagAlt
                    ? const Color(0xFFD4AF37)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                product.tag!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: product.tagAlt ? Colors.black : Colors.white,
                ),
              ),
            ),

          const SizedBox(height: 6),

          // NOME
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 4),

          // META
          if (product.meta != null && product.meta!.isNotEmpty)
            Text(
              product.meta!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9FA3B3),
              ),
            ),

          const SizedBox(height: 8),

          // 🔥 PREÇO COM DESCONTO (se tiver)
          if (hasDiscount) ...[
            Row(
              children: [
                Text(
                  brl(product.originalPrice!), // preço antigo
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8D98),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "-$discountPercent%",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // PREÇO ATUAL
          Text(
            brl(product.price),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),

          const SizedBox(height: 8),

          // SELETOR GRÃO / MOÍDO
          Row(
            children: [
              if (product.sku != "ROCA-250" && product.sku != "FLOR-250" && product.sku != "PURE-250")
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Grão')),
                  selected: _selectedGrind == 'Grão',
                  labelStyle: const TextStyle(fontSize: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  onSelected: (_) {
                    setState(() => _selectedGrind = 'Grão');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Moído')),
                  selected: _selectedGrind == 'Moído',
                  labelStyle: const TextStyle(fontSize: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  onSelected: (_) {
                    setState(() => _selectedGrind = 'Moído');
                  },
                ),
              ),
            ],
          ),


          const SizedBox(height: 10),

          // BOTÃO
    /*
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () => widget.onAdd(_selectedGrind) // 👈 chama com "Grão/Moído"
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                product.inStock ? const Color(0xFFD4AF37) : Colors.grey[800],
                foregroundColor:
                product.inStock ? Colors.black : Colors.white60,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                product.inStock ? 'Adicionar ao carrinho' : 'Esgotado',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          */

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () {
                final sku = product.sku;
                final precisaEscolher =
                    sku != "ROCA-250" && sku != "FLOR-250" && sku != "PURE-250";

                // Se precisa escolher e ainda não escolheu nada
                if (precisaEscolher && _selectedGrind == null) {
                  showGrindRequiredDialog(context);
                  return;
                }
                // Para os que são só moído, _selectedGrind já vem "Moído" do initState
                widget.onAdd(_selectedGrind ?? 'Moído');
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                product.inStock ? const Color(0xFFD4AF37) : Colors.grey[800],
                foregroundColor:
                product.inStock ? Colors.black : Colors.white60,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                product.inStock ? 'Adicionar ao carrinho' : 'Esgotado',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;

  const _ProcessCard({
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$index. $title",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
/*
class _CartDrawer extends StatelessWidget {
  final TextEditingController cepController;
  final VoidCallback onClose;
  final Function(String) onCepSaved;
  final VoidCallback onCheckout;
  final VoidCallback onClear;

  const _CartDrawer({
    required this.cepController,
    required this.onClose,
    required this.onCepSaved,
    required this.onCheckout,
    required this.onClear,
  });


  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

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

          // CEP
          TextField(
            controller: cepController,
            decoration: const InputDecoration(
              labelText: "CEP",
              hintText: "00000-000",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          /*
          ElevatedButton(
            onPressed: () {
              if (cepController.text.trim().length >= 8) {
                onCepSaved(cepController.text.trim());
              }
            },
            child: const Text("Registrar CEP"),
          ),
          */
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Frete"),
                  Text("a calcular"),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total (sem frete)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(brl(cart.subtotal)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            //onPressed: onCheckout,
            //onPressed: cepController.text.isEmpty ? null : onCheckout,
            onPressed: () {
              if (cepController.text.trim().length >= 8) {
                onCepSaved(cepController.text.trim());
              }
              Future.delayed(const Duration(seconds: 2));
              onCheckout();
            },
            child: const Text("Finalizar pelo WhatsApp"),
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
void showProductImageDialog(BuildContext context, Product product) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: InteractiveViewer(
                minScale: 0.9,
                maxScale: 3.0,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.asset(
                    product.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CarouselArrow({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}


