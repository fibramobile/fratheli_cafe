import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product.dart';
import '../../theme/fratheli_colors.dart';
import '../../utils/formatters.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final void Function(String grind) onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late String _selectedGrind;

  List<String> get _options => widget.product.grindOptions.isEmpty
      ? const ['Grão', 'Moído']
      : widget.product.grindOptions;

  String get _name {
    final raw = widget.product.name.trim();
    if (raw.contains(' - ')) return raw.split(' - ').last.trim();
    return raw.replaceAll(RegExp(r'\s*-?\s*250\s*g', caseSensitive: false), '').trim();
  }

  @override
  void initState() {
    super.initState();
    final preferred = widget.product.defaultGrind;
    _selectedGrind = preferred != null && _options.contains(preferred)
        ? preferred
        : _options.first;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_options.contains(_selectedGrind)) _selectedGrind = _options.first;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasDiscount = product.originalPrice != null &&
        product.originalPrice! > product.price;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FratheliColors.paper,
        border: Border.all(color: FratheliColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LotArtwork(product: product, title: _name),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _kicker(product),
                  style: GoogleFonts.dmSans(
                    color: FratheliColors.cherry,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.libreCaslonDisplay(
                    color: FratheliColors.ink,
                    fontSize: 35,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.meta.isNotEmpty ? product.meta : product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: FratheliColors.text2,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _process(product),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: FratheliColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'COMO PREFERE?',
                  style: GoogleFonts.dmSans(
                    color: FratheliColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  value: _selectedGrind,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    fillColor: Colors.white,
                  ),
                  items: _options
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              option.toLowerCase().contains('grão')
                                  ? 'Em grãos'
                                  : option,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedGrind = value);
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              brl(product.originalPrice!),
                              style: const TextStyle(
                                color: FratheliColors.muted,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            )
                          else
                            Text(
                              'a partir de',
                              style: GoogleFonts.dmSans(
                                color: FratheliColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          Text(
                            brl(product.price),
                            style: GoogleFonts.libreCaslonDisplay(
                              color: FratheliColors.ink,
                              fontSize: 25,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: product.inStock
                            ? () => widget.onAdd(_selectedGrind)
                            : null,
                        child: Text(product.inStock ? 'Adicionar' : 'Esgotado'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => _showDetails(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Text('Ver detalhes do lote  ↗'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        contentPadding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
        titlePadding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
        title: Text(
          _name,
          style: GoogleFonts.libreCaslonDisplay(fontSize: 40),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.description.isEmpty
                    ? 'Microlote de café especial produzido em pequena escala nas Montanhas Capixabas.'
                    : widget.product.description,
                style: const TextStyle(color: FratheliColors.text2, height: 1.55),
              ),
              const SizedBox(height: 18),
              _fact('Origem', 'Alfredo Chaves · ES'),
              _fact('Altitude', '700 m'),
              _fact('Processo', _process(widget.product)),
              _fact('Perfil', widget.product.meta.isEmpty ? 'Café especial' : widget.product.meta),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: widget.product.inStock
                ? () {
                    widget.onAdd(_selectedGrind);
                    Navigator.pop(dialogContext);
                  }
                : null,
            child: const Text('Adicionar à sacola'),
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Expanded(child: Text(value, style: const TextStyle(color: FratheliColors.text2))),
          ],
        ),
      );

  String _kicker(Product product) {
    final size = product.size?.trim();
    return 'CAFÉ ESPECIAL · ${size == null || size.isEmpty ? '250 G' : size.toUpperCase()}';
  }

  String _process(Product product) {
    final haystack = '${product.name} ${product.description} ${product.meta}'.toLowerCase();
    if (haystack.contains('bugia')) return 'Pós-colheita com mel de Uruçu Amarela';
    if (haystack.contains('tiúba') || haystack.contains('tiuba')) {
      return 'Pós-colheita com mel de Uruçu Cinzenta';
    }
    if (haystack.contains('mel')) return 'Pós-colheita com mel de abelha nativa';
    return 'Processo natural · Montanhas Capixabas';
  }
}

class _LotArtwork extends StatelessWidget {
  final Product product;
  final String title;

  const _LotArtwork({required this.product, required this.title});

  @override
  Widget build(BuildContext context) {
    final lower = title.toLowerCase();
    final isNatural = lower.contains('araçari') || lower.contains('aracari');
    final background = isNatural
        ? const Color(0xFF9B6A43)
        : lower.contains('tiúba') || lower.contains('tiuba')
            ? const Color(0xFF734437)
            : const Color(0xFF3D5038);
    final score = isNatural ? '84' : '86';
    final lot = isNatural
        ? 'LOTE 03'
        : lower.contains('tiúba') || lower.contains('tiuba')
            ? 'LOTE 02'
            : 'LOTE 01';

    return SizedBox(
      height: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: background),
          CustomPaint(painter: _LotLinesPainter()),
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              lot,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFE8D9B8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.libreCaslonDisplay(
                    color: const Color(0xFFF7EAD1),
                    fontSize: 64,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 16,
            child: Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x99F7EAD1)),
              ),
              child: Text.rich(
                TextSpan(
                  text: '$score\n',
                  style: GoogleFonts.libreCaslonDisplay(
                    color: const Color(0xFFF7EAD1),
                    fontSize: 24,
                    height: .8,
                  ),
                  children: [
                    TextSpan(
                      text: 'pontos',
                      style: GoogleFonts.dmSans(fontSize: 8, letterSpacing: 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LotLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x20FFF2D5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = -3; i < 12; i++) {
      final y = i * 34.0;
      final path = Path();
      path.moveTo(-20, y);
      path.quadraticBezierTo(size.width * .45, y + 75, size.width + 20, y + 12);
      canvas.drawPath(path, paint);
    }
    final beanPaint = Paint()
      ..color = const Color(0x18FFF2D5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.translate(size.width * .18, size.height * .72);
    canvas.rotate(-math.pi / 5);
    canvas.drawOval(const Rect.fromLTWH(-35, -18, 70, 36), beanPaint);
    canvas.drawLine(const Offset(-28, 0), const Offset(28, 0), beanPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
