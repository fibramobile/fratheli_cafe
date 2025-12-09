import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final void Function(String grind) onAdd; // "Grão" ou "Moído"

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String? _selectedGrind; // agora pode ser null, iniciamos no initState

  @override
  void initState() {
    super.initState();

    final options = widget.product.grindOptions;

    if (options.isNotEmpty) {
      // Se tiver defaultGrind e ele estiver na lista, usa.
      if (widget.product.defaultGrind != null &&
          options.contains(widget.product.defaultGrind)) {
        _selectedGrind = widget.product.defaultGrind;
      } else {
        // Senão usa a primeira opção (ex.: ["Moído"])
        _selectedGrind = options.first;
      }
    } else {
      // Produto antigo/sem configuração de moagem -> comportamento antigo
      _selectedGrind = 'Grão';
    }
  }
/*
  Widget _buildProductImage(Product product, {BoxFit fit = BoxFit.cover}) {
    final path = product.imagePath;

    // placeholder padrão
    Widget placeholder = Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white38),
      ),
    );

    if (path.isEmpty) return placeholder;

    // Já é URL completa
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    // Asset local
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    // --- CORREÇÃO URL server ---
    String relative = path;

    if (!relative.startsWith('images/')) {
      relative = "images/$relative";
    }

    const base = "https://smapps.16mb.com/fratheli/app/products/";
    final url = "$base$relative";

    debugPrint('🖼️ ProductCard -> path="$path" url="$url"');

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
*/
  Widget _buildProductImage(Product product, {BoxFit fit = BoxFit.cover}) {
    final path = product.imagePath;

    // placeholder padrão
    Widget placeholder = Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white38),
      ),
    );

    if (path.isEmpty) return placeholder;

    // Já é URL completa
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    // Asset local
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    // ⚠️ AGORA: mesmo comportamento do painel
    const base = "https://smapps.16mb.com/fratheli/app/products/";
    final url = "$base$path";

    debugPrint('🖼️ ProductCard -> path="$path" url="$url"');

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }


  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final options = product.grindOptions;

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
              onTap: () =>
                  showProductImageDialog(context, product, _buildProductImage),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: _buildProductImage(product),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // TAG
          if (product.tag.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: product.tagAlt
                    ? const Color(0xFFD4AF37)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                product.tag,
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
          if (product.meta.isNotEmpty)
            Text(
              product.meta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9FA3B3),
              ),
            ),

          const SizedBox(height: 8),

          // PREÇO ANTIGO + %
          if (hasDiscount) ...[
            Row(
              children: [
                Text(
                  brl(product.originalPrice!),
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

          // 🔥 SELETOR / INFO DE MOAGEM
          Builder(
            builder: (context) {
              // 1) Sem configuração de moagem → comportamento antigo (dois chips)
              if (options.isEmpty) {
                return Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Grão'),
                      selected: _selectedGrind == 'Grão',
                      onSelected: (_) {
                        setState(() => _selectedGrind = 'Grão');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Moído'),
                      selected: _selectedGrind == 'Moído',
                      onSelected: (_) {
                        setState(() => _selectedGrind = 'Moído');
                      },
                    ),
                  ],
                );
              }

              // 2) Apenas uma opção (ex.: ["Moído"])
              if (options.length == 1) {
                return  ChoiceChip(
                  label: const Text('Moído'),
                  selected: _selectedGrind == 'Moído',
                  onSelected: (_) {
                    setState(() => _selectedGrind = 'Moído');
                  },
                );
/*
                  Text(
                  options.first,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF9FA3B3),
                  ),
                );*/
              }

              // 3) Duas ou mais opções → chips dinâmicos (ex.: ["Grão", "Moído"])
              return Row(
                children: options.map((opt) {
                  final selected = _selectedGrind == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedGrind = opt);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 10),

          // BOTÃO
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () {
                final grindToSend = _selectedGrind ??
                    (options.isNotEmpty ? options.first : 'Grão');
                widget.onAdd(grindToSend);
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: product.inStock
                    ? const Color(0xFFD4AF37)
                    : Colors.grey[800],
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

/// Dialog de zoom da imagem
void showProductImageDialog(
    BuildContext context,
    Product product,
    Widget Function(Product, {BoxFit fit}) builder,
    ) {
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
                  child: builder(
                    product,
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
