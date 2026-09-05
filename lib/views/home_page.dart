import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../theme/fratheli_colors.dart';
import '../utils/formatters.dart';
import 'widgets/cart_drawer.dart';
import 'widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _instagramUrl = 'https://www.instagram.com/fratheli_cafe';
  static const _whatsappUrl = 'https://wa.me/5527996033401';
  static const _paymentUrl = 'https://frathelicafe.com.br/pagamento_order.html?orderId=';
  static const _catalogUrl =
      'https://smapps.16mb.com/fratheli/app/products/get_products.php';
  static const _visitUrl = 'https://frathelicafe.com.br/contador_visitas.php';
  static const _freightUrl = 'https://frathelicafe.com.br/cotacao_frete.php';

  final _scrollController = ScrollController();
  final _cepController = TextEditingController();
  final _cafesKey = GlobalKey();
  final _processKey = GlobalKey();
  final _originKey = GlobalKey();
  final _contactKey = GlobalKey();

  List<Product> _products = _fallbackProducts;
  bool _loadingProducts = true;
  bool _cartOpen = false;
  bool _isCheckingOut = false;
  int? _visits;
  Map<String, dynamic>? _user;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadVisits();
    _loadUser();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final catalogUri = Uri.parse(_catalogUrl).replace(
        queryParameters: {
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http
          .get(catalogUri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final raw = decoded is Map ? decoded['products'] : null;
      if (raw is! List) return;
      final imageVersion = decoded is Map
          ? (decoded['updatedAt']?.toString() ?? '')
          : '';
      final loaded = raw
          .whereType<Map>()
          .map((item) {
            final product = Map<String, dynamic>.from(item);
            product['imageVersion'] = imageVersion;
            return Product.fromJson(product);
          })
          .where((product) => product.sku.isNotEmpty && product.name.isNotEmpty)
          .toList();
      if (loaded.isNotEmpty && mounted) setState(() => _products = loaded);
    } catch (_) {
      // Mantém os microlotes da vitrine quando o catálogo remoto está indisponível.
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadVisits() async {
    try {
      final response = await http
          .get(Uri.parse(_visitUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is Map && data['ok'] == true && data['total'] != null && mounted) {
        setState(() => _visits = _toNum(data['total']).toInt());
      }
    } catch (_) {
      // O contador não bloqueia o carregamento do site.
    }
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  Future<void> _openAccount() async {
    final route = _user == null ? '/login' : '/minha_conta';
    await Navigator.pushNamed(context, route);
    await _loadUser();
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.parse(value);
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  Future<void> _calculateFreight(BuildContext context, String cep) async {
    final cart = context.read<CartController>();
    final normalizedCep = cep.replaceAll(RegExp(r'\D'), '');
    final totalPackages = cart.items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    try {
      if (normalizedCep.length != 8) {
        throw Exception('Digite um CEP válido com 8 números.');
      }
      if (totalPackages <= 0) {
        throw Exception('Adicione um café antes de calcular o frete.');
      }

      final uri = Uri.parse(_freightUrl).replace(queryParameters: {
        'cep': normalizedCep,
        'qtd': totalPackages.toString(),
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['erro'] ?? 'Falha ao calcular frete') : 'Resposta inválida');
      }
      final rawOptions = data['opcoes'];
      if (rawOptions is! List || rawOptions.isEmpty) {
        throw Exception('Nenhuma opção de frete disponível para este CEP.');
      }
      final options = rawOptions
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      if (options.isEmpty) {
        throw Exception('A transportadora não retornou opções válidas para este CEP.');
      }
      if (!mounted) return;
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.58),
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: FratheliColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: FratheliColors.border),
          ),
          child: SizedBox(
            width: 520,
            height: math.min(
              620.0,
              MediaQuery.sizeOf(dialogContext).height * 0.82,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ENTREGA PARA SEU CEP',
                              style: TextStyle(
                                color: FratheliColors.cherry,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Escolha o frete',
                              style: GoogleFonts.libreCaslonDisplay(
                                color: FratheliColors.ink,
                                fontSize: 36,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final option = options[index];
                      final service = (option['transportadora'] ?? 'Frete').toString();
                      final deadline = (option['prazo'] ?? '').toString();
                      final price = _toNum(option['valor']).toDouble();
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        title: Text(
                          service,
                          style: const TextStyle(
                            color: FratheliColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: deadline.isEmpty
                            ? null
                            : Text(deadline, style: const TextStyle(color: FratheliColors.muted)),
                        trailing: Text(
                          brl(price),
                          style: const TextStyle(
                            color: FratheliColors.cherry,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () => Navigator.pop(dialogContext, option),
                      );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: FratheliColors.border)),
                  ),
                  child: const Text(
                    'Selecione uma modalidade para incluir o frete no total do pedido.',
                    style: TextStyle(color: FratheliColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (selected == null) return;
      final value = _toNum(selected['valor']).toDouble();
      final service = (selected['transportadora'] ?? 'Frete').toString();
      final deadline = (selected['prazo'] ?? '').toString();
      cart.setFreight(value: value, service: service, prazo: deadline);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Frete selecionado: $service · ${brl(value)}')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Não foi possível calcular', style: GoogleFonts.libreCaslonDisplay(fontSize: 34)),
          content: Text(
            'Confira o CEP e tente novamente.\n\n${error.toString().replaceFirst('Exception: ', '')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkout() async {
    if (_isCheckingOut) return;
    setState(() => _isCheckingOut = true);
    try {
      final cart = context.read<CartController>();
      final orderCode = (cart.lastOrderId ?? '').trim();
      if (orderCode.isEmpty) throw Exception('Pedido ainda não foi criado.');
      await _openUrl('$_paymentUrl${Uri.encodeComponent(orderCode)}');
      cart.clear();
      if (mounted) setState(() => _cartOpen = false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = math.min(width, 430.0);

    return Scaffold(
      backgroundColor: FratheliColors.paper,
      body: Stack(
        children: [
          Column(
            children: [
              const _AnnouncementBar(),
              _PremiumHeader(
                user: _user,
                onAccount: _openAccount,
                onCart: () => setState(() => _cartOpen = true),
                onCafes: () => _scrollTo(_cafesKey),
                onProcess: () => _scrollTo(_processKey),
                onOrigin: () => _scrollTo(_originKey),
                onContact: () => _scrollTo(_contactKey),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      _HeroSection(
                        onProducts: () => _scrollTo(_cafesKey),
                        onProcess: () => _scrollTo(_processKey),
                      ),
                      KeyedSubtree(key: _cafesKey, child: _buildProducts()),
                      KeyedSubtree(key: _processKey, child: const _ProcessSection()),
                      KeyedSubtree(key: _originKey, child: const _OriginSection()),
                      const _ManifestSection(),
                      KeyedSubtree(
                        key: _contactKey,
                        child: _ContactSection(onWhatsApp: () => _openUrl(_whatsappUrl)),
                      ),
                      _Footer(
                        visits: _visits,
                        onProducts: () => _scrollTo(_cafesKey),
                        onProcess: () => _scrollTo(_processKey),
                        onOrigin: () => _scrollTo(_originKey),
                        onInstagram: () => _openUrl(_instagramUrl),
                        onWhatsApp: () => _openUrl(_whatsappUrl),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_cartOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _cartOpen = false),
                child: Container(color: Colors.black54),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            right: _cartOpen ? 0 : -drawerWidth,
            width: drawerWidth,
            child: CartDrawer(
              cepController: _cepController,
              onClose: () => setState(() => _cartOpen = false),
              onCepSaved: context.read<CartController>().setCep,
              onCheckout: _checkout,
              onClear: context.read<CartController>().clear,
              onCalculateFreight: (cep) => _calculateFreight(context, cep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducts() {
    final visible = _products.where((product) {
      if (_filter == 'all') return true;
      final text = '${product.name} ${product.description} ${product.meta}'.toLowerCase();
      if (_filter == 'mel') {
        return text.contains('mel') || text.contains('bugia') || text.contains('tiúba') || text.contains('tiuba');
      }
      return !text.contains('mel') || text.contains('natural') || text.contains('araçari') || text.contains('aracari');
    }).toList();

    return Container(
      color: FratheliColors.paper,
      padding: const EdgeInsets.symmetric(vertical: 96),
      child: _PageWidth(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final mobile = width < 660;
            final columns = mobile ? 1 : width < 980 ? 2 : 3;
            final itemWidth = (width - (columns - 1) * 18) / columns;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 42,
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: mobile ? width : width * .53,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Eyebrow('ESCOLHA PELA EXPERIÊNCIA'),
                          _SectionTitle('Microlotes da safra'),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: mobile ? width : math.min(400.0, width * .38),
                      child: const Text(
                        'Poucos lotes, cada um com uma história e um perfil sensorial próprios. Selecione em grãos ou moído.',
                        style: TextStyle(color: FratheliColors.text2, height: 1.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterButton(label: 'Todos', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                    _FilterButton(label: 'Com mel de abelhas nativas', selected: _filter == 'mel', onTap: () => setState(() => _filter = 'mel')),
                    _FilterButton(label: 'Processo natural', selected: _filter == 'natural', onTap: () => setState(() => _filter = 'natural')),
                  ],
                ),
                const SizedBox(height: 30),
                if (_loadingProducts)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Text('Nenhum café disponível neste filtro.'),
                  )
                else
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: visible.map((product) {
                      return SizedBox(
                        width: itemWidth,
                        child: ProductCard(
                          product: product,
                          onAdd: (grind) {
                            context.read<CartController>().addProduct(product, grind);
                            setState(() => _cartOpen = true);
                          },
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar();

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        color: FratheliColors.espresso,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'SAFRA 2026   •   TORRA FRESCA   •   ENVIAMOS PARA TODO O BRASIL',
            style: GoogleFonts.dmSans(
              color: const Color(0xFFEADFCE),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
      );
}

class _PremiumHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final VoidCallback onAccount;
  final VoidCallback onCart;
  final VoidCallback onCafes;
  final VoidCallback onProcess;
  final VoidCallback onOrigin;
  final VoidCallback onContact;

  const _PremiumHeader({
    required this.user,
    required this.onAccount,
    required this.onCart,
    required this.onCafes,
    required this.onProcess,
    required this.onOrigin,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartController>().totalItems;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;
        final compact = constraints.maxWidth < 620;
        final name = (user?['name'] ?? '').toString().trim();
        final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
        return Container(
          height: compact ? 86 : 114,
          decoration: const BoxDecoration(
            color: Color(0xFA15100D),
            border: Border(bottom: BorderSide(color: Color(0x4DE2B85C))),
          ),
          child: _PageWidth(
            horizontalPadding: compact ? 14 : 28,
            child: Row(
              children: [
                Image.asset(
                  'assets/premium/logo-fratheli.png',
                  width: compact ? 112 : 150,
                  height: compact ? 82 : 108,
                  fit: BoxFit.contain,
                ),
                if (desktop) ...[
                  const Spacer(),
                  _HeaderLink('Cafés', onCafes),
                  _HeaderLink('Processo com mel', onProcess),
                  _HeaderLink('Nossa origem', onOrigin),
                  _HeaderLink('Contato', onContact),
                  const Spacer(),
                ] else
                  const Spacer(),
                InkWell(
                  onTap: onAccount,
                  borderRadius: BorderRadius.circular(40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 27,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x99E2B85C)),
                          ),
                          child: Text(
                            firstName.isEmpty ? '●' : firstName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: FratheliColors.gold2, fontSize: 11),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          Text(
                            firstName.isEmpty ? 'Entrar' : 'Olá, $firstName',
                            style: const TextStyle(
                              color: FratheliColors.cream,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onCart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        if (!compact)
                          const Text(
                            'Sacola',
                            style: TextStyle(color: FratheliColors.cream, fontWeight: FontWeight.w700, fontSize: 13),
                          )
                        else
                          const Icon(Icons.shopping_bag_outlined, color: FratheliColors.cream, size: 21),
                        const SizedBox(width: 7),
                        Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: FratheliColors.cherry, shape: BoxShape.circle),
                          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: FratheliColors.cream,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      );
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onProducts;
  final VoidCallback onProcess;

  const _HeroSection({required this.onProducts, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 920;
        final visual = _HeroVisual(height: desktop ? 670 : 460);
        final copy = _HeroCopy(
          desktop: desktop,
          onProducts: onProducts,
          onProcess: onProcess,
        );
        return Container(
          color: FratheliColors.cream,
          child: desktop
              // A altura acompanha o conteúdo textual. Isso evita overflow em
              // larguras nas quais o título e a descrição ocupam mais linhas.
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 102, child: copy),
                      Expanded(flex: 98, child: visual),
                    ],
                  ),
                )
              : Column(children: [copy, visual]),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool desktop;
  final VoidCallback onProducts;
  final VoidCallback onProcess;

  const _HeroCopy({required this.desktop, required this.onProducts, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final titleSize = desktop ? math.min(84.0, screen * .055) : math.min(62.0, screen * .135);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        desktop ? math.max(52.0, (screen - 1240.0) / 2) : 24.0,
        desktop ? 70.0 : 58.0,
        desktop ? 52.0 : 24.0,
        desktop ? 62.0 : 58.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('SÍTIO SOMBRA DA MATA · ALFREDO CHAVES, ES'),
          Text.rich(
            TextSpan(
              text: 'Café de montanha.\n',
              children: [
                TextSpan(
                  text: 'Identidade',
                  style: GoogleFonts.libreCaslonDisplay(
                    color: FratheliColors.cherry,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const TextSpan(text: ' em cada lote.'),
              ],
            ),
            style: GoogleFonts.libreCaslonDisplay(
              color: FratheliColors.ink,
              fontSize: titleSize,
              height: .98,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 26),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: const Text(
              'Microlotes cultivados em família nas Montanhas Capixabas, com processos pós-colheita que aproximam duas paixões da nossa terra: o café e as abelhas nativas brasileiras.',
              style: TextStyle(color: FratheliColors.text2, fontSize: 16, height: 1.65),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 50,
                child: ElevatedButton(onPressed: onProducts, child: const Text('Escolher meu café')),
              ),
              TextButton(
                onPressed: onProcess,
                child: const Text('Conhecer o processo  ↗'),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroFact('700 m', 'Altitude'),
              _HeroFact('84–86', 'Pontos'),
              _HeroFact('100%', 'Arábica', last: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  final String value;
  final String label;
  final bool last;

  const _HeroFact(this.value, this.label, {this.last = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(right: last ? 0 : 22, left: 18),
        decoration: BoxDecoration(
          border: last ? null : const Border(right: BorderSide(color: FratheliColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.libreCaslonDisplay(fontSize: 24)),
            Text(label, style: const TextStyle(color: FratheliColors.muted, fontSize: 10, letterSpacing: 1.1)),
          ],
        ),
      );
}

class _HeroVisual extends StatelessWidget {
  final double height;

  const _HeroVisual({required this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/premium/hero-fratheli.jpg', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x8F21150F), Colors.transparent],
                  stops: [0, .62],
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: 26,
              child: Container(
                width: 132,
                height: 132,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xCC21150F),
                  border: Border.all(color: const Color(0xB3E2B85C)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ORIGEM', style: TextStyle(color: FratheliColors.gold2, fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 11)),
                    Text('RASTREÁVEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                    SizedBox(height: 5),
                    Text('ALFREDO CHAVES · ES', style: TextStyle(color: Color(0xFFEADFCE), fontSize: 7)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 920;
        final image = SizedBox(
          height: desktop ? 720 : 430,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/premium/processo-mel.jpg', fit: BoxFit.cover),
              const Positioned(
                left: 24,
                bottom: 22,
                child: Text(
                  'PROCESSO AUTORAL · DESDE 2025',
                  style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
        final copy = Container(
          color: FratheliColors.espresso,
          padding: EdgeInsets.symmetric(horizontal: desktop ? 72 : 24, vertical: desktop ? 74 : 66),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('NOSSO DIFERENCIAL', light: true),
              Text(
                'Quando o café encontra o meliponário.',
                style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.cream, fontSize: desktop ? 57 : 48, height: 1.02),
              ),
              const SizedBox(height: 24),
              const Text(
                'Em edições selecionadas, o café cereja descascado recebe mel de abelhas nativas durante a secagem no terreiro suspenso. Um processo experimental, conduzido em pequena escala e acompanhado lote a lote.',
                style: TextStyle(color: Color(0xFFD1C5B5), height: 1.65),
              ),
              const SizedBox(height: 30),
              const _ProcessStep('01', 'Colheita seletiva', 'Somente frutos maduros, colhidos manualmente.'),
              const _ProcessStep('02', 'Cereja descascado', 'A base do processo honey preserva a mucilagem do fruto.'),
              const _ProcessStep('03', 'Mel de abelhas nativas', 'Aplicado cuidadosamente durante a secagem.'),
              const _ProcessStep('04', 'Torra por perfil', 'Desenvolvida para revelar a identidade sensorial do lote.'),
            ],
          ),
        );
        return desktop
            // O texto pode ultrapassar 720 px em algumas larguras e escalas
            // de fonte. A seção passa a adotar a altura real do conteúdo.
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: image),
                    Expanded(child: copy),
                  ],
                ),
              )
            : Column(children: [image, copy]);
      },
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _ProcessStep(this.number, this.title, this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x33F4EFE6)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(number, style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.gold2, fontSize: 21)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: FratheliColors.cream, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(text, style: const TextStyle(color: Color(0xFFB9ADA0), fontSize: 13, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _OriginSection extends StatelessWidget {
  const _OriginSection();

  @override
  Widget build(BuildContext context) => Container(
        color: FratheliColors.paper,
        padding: const EdgeInsets.symmetric(vertical: 98),
        child: _PageWidth(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 760;
              final intro = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Eyebrow('NOSSA ORIGEM'),
                  _SectionTitle('Pequena escala.\nGrande identidade.'),
                ],
              );
              final story = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“Mais do que produzir café, queremos criar experiências que carreguem a história da nossa terra, da nossa família e das Montanhas Capixabas.”',
                    style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.ink, fontSize: 29, height: 1.25),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'A Frathéli nasce no Sítio Sombra da Mata, em Ribeirão de São Antônio, Alfredo Chaves. A capacidade limitada da propriedade não é um obstáculo: é o que nos permite acompanhar cada microlote, experimentar e preservar a personalidade de cada safra.',
                    style: TextStyle(color: FratheliColors.text2, height: 1.65),
                  ),
                  const SizedBox(height: 24),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OriginTag('Produção familiar'),
                      _OriginTag('Origem única'),
                      _OriginTag('Microlotes rastreáveis'),
                    ],
                  ),
                ],
              );
              if (!desktop) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [intro, const SizedBox(height: 36), story]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: intro), const SizedBox(width: 90), Expanded(child: story)]);
            },
          ),
        ),
      );
}

class _OriginTag extends StatelessWidget {
  final String text;
  const _OriginTag(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: FratheliColors.border)),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _ManifestSection extends StatelessWidget {
  const _ManifestSection();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: FratheliColors.cream,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 92),
        child: Column(
          children: [
            const _Eyebrow('MANIFESTO FRATHÉLI'),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Text(
                '“Cada microlote carrega a montanha, o trabalho da família e a coragem de experimentar.”',
                textAlign: TextAlign.center,
                style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.ink, fontSize: 47, height: 1.18),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Café com origem. Café com identidade.', style: TextStyle(color: FratheliColors.cherry, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _ContactSection extends StatelessWidget {
  final VoidCallback onWhatsApp;
  const _ContactSection({required this.onWhatsApp});
  @override
  Widget build(BuildContext context) => Container(
        color: FratheliColors.espresso2,
        padding: const EdgeInsets.symmetric(vertical: 76),
        child: _PageWidth(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 760;
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Eyebrow('ATENDIMENTO DIRETO DO PRODUTOR', light: true),
                  SizedBox(
                    width: desktop ? 690 : constraints.maxWidth,
                    child: Text(
                      'Quer encontrar o café certo para a sua xícara?',
                      style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.cream, fontSize: desktop ? 51 : 43, height: 1.05),
                    ),
                  ),
                ],
              );
              final button = SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onWhatsApp,
                  style: ElevatedButton.styleFrom(backgroundColor: FratheliColors.gold2, foregroundColor: FratheliColors.espresso),
                  child: const Text('Conversar no WhatsApp'),
                ),
              );
              if (!desktop) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 28), button]);
              return Row(children: [Expanded(child: text), const SizedBox(width: 30), button]);
            },
          ),
        ),
      );
}

class _Footer extends StatelessWidget {
  final int? visits;
  final VoidCallback onProducts;
  final VoidCallback onProcess;
  final VoidCallback onOrigin;
  final VoidCallback onInstagram;
  final VoidCallback onWhatsApp;

  const _Footer({
    required this.visits,
    required this.onProducts,
    required this.onProcess,
    required this.onOrigin,
    required this.onInstagram,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: FratheliColors.espresso,
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: _PageWidth(
          child: Column(
            children: [
              Wrap(
                spacing: 80,
                runSpacing: 44,
                children: [
                  SizedBox(
                    width: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/premium/logo-fratheli.png', width: 176, height: 130, fit: BoxFit.contain),
                        const Text('Café com origem. Café com identidade.', style: TextStyle(color: Color(0xFFC9BCAD))),
                      ],
                    ),
                  ),
                  _FooterLinks(title: 'Explore', links: [('Cafés', onProducts), ('Processo', onProcess), ('Origem', onOrigin)]),
                  _FooterLinks(title: 'Atendimento', links: [('Instagram', onInstagram), ('WhatsApp', onWhatsApp)]),
                ],
              ),
              const SizedBox(height: 46),
              const Divider(color: Color(0x33F4EFE6)),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '© ${DateTime.now().year} Frathéli Cafés · Sítio Sombra da Mata${visits == null ? '' : ' · $visits visitas registradas'}',
                  style: const TextStyle(color: Color(0xFF9F9387), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
}

class _FooterLinks extends StatelessWidget {
  final String title;
  final List<(String, VoidCallback)> links;
  const _FooterLinks({required this.title, required this.links});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: FratheliColors.cream, fontWeight: FontWeight.w700)),
            const SizedBox(height: 13),
            ...links.map((link) => TextButton(
                  onPressed: link.$2,
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFC9BCAD), padding: const EdgeInsets.symmetric(vertical: 6)),
                  child: Align(alignment: Alignment.centerLeft, child: Text(link.$1)),
                )),
          ],
        ),
      );
}

class _PageWidth extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;
  const _PageWidth({required this.child, this.horizontalPadding = 24});
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1288),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: child,
          ),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  final String text;
  final bool light;
  const _Eyebrow(this.text, {this.light = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            color: light ? FratheliColors.gold2 : FratheliColors.cherry,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.libreCaslonDisplay(color: FratheliColors.ink, fontSize: 55, height: 1.02, letterSpacing: -1.5),
      );
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterButton({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? FratheliColors.espresso : Colors.transparent,
          foregroundColor: selected ? FratheliColors.paper : FratheliColors.ink,
          side: const BorderSide(color: FratheliColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
        child: Text(label),
      );
}

num _toNum(dynamic value) {
  if (value is num) return value;
  var text = (value ?? '0').toString().trim();
  if (text.contains(',') && text.contains('.')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else {
    text = text.replaceAll(',', '.');
  }
  return num.tryParse(text.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
}

const List<Product> _fallbackProducts = [
  Product(
    sku: 'BUGIA-250',
    name: 'Bugia',
    description: 'Microlote autoral com doçura profunda e perfil aromático.',
    imagePath: '',
    price: 39,
    tag: 'LOTE 01',
    tagAlt: false,
    meta: 'Chocolate · Damasco · Melaço',
    size: '250 g',
    grindOptions: ['Grão', 'Moído'],
  ),
  Product(
    sku: 'TIUBA-250',
    name: 'Tiúba',
    description: 'Edição de pequena escala com mel de abelha nativa.',
    imagePath: '',
    price: 39,
    tag: 'LOTE 02',
    tagAlt: false,
    meta: 'Chocolate · Frutas amarelas · Doçura',
    size: '250 g',
    grindOptions: ['Grão', 'Moído'],
  ),
  Product(
    sku: 'ARACARI-250',
    name: 'Araçari',
    description: 'Café especial das Montanhas Capixabas com processo natural.',
    imagePath: '',
    price: 37,
    tag: 'LOTE 03',
    tagAlt: false,
    meta: 'Caramelo · Castanhas · Corpo sedoso',
    size: '250 g',
    grindOptions: ['Grão', 'Moído'],
  ),
];
