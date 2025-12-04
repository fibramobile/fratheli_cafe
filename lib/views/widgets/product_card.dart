import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';

const String kProductImageBaseUrl =
    'https://smapps.16mb.com/fratheli/app/'; // 👈 base correta

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

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.white38,
        ),
      ),
    );
  }

  /// Resolve o caminho da imagem:
  /// - http/https -> usa direto
  /// - assets/... -> Image.asset
  /// - qualquer outra coisa (ex: "images/prod_...jpg") -> base do servidor
  Widget _buildProductImage(Product product, {BoxFit fit = BoxFit.cover}) {
    final path = product.imagePath;

    if (path.isEmpty) {
      return _buildPlaceholder();
    }

    // Já veio com http(s)
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Asset antigo
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Caminho relativo salvo pelo app: "images/xxx.jpg"
    final url = '$kProductImageBaseUrl$path'; // 👈 sem /products no meio

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // DESCONTO
    final bool hasDiscount =
        product.originalPrice != null && product.originalPrice! > product.price;

    int? discountPercent;
    if (hasDiscount) {
      discountPercent = (
          ((product.originalPrice! - product.price) / product.originalPrice!) * 100
      ).round();
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
                  child: _buildProductImage(product),
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
                  brl(product.originalPrice!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8D98),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
              // Esconde "Grão" para produtos só moído
              if (product.sku != "ROCA-250" &&
                  product.sku != "FLOR-250" &&
                  product.sku != "PURE-250")
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Grão')),
                    selected: _selectedGrind == 'Grão',
                    labelStyle: const TextStyle(fontSize: 13),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedGrind = 'Grão');
                    },
                  ),
                ),
              if (product.sku != "ROCA-250" &&
                  product.sku != "FLOR-250" &&
                  product.sku != "PURE-250")
                const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Moído')),
                  selected: _selectedGrind == 'Moído',
                  labelStyle: const TextStyle(fontSize: 13),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedGrind = 'Moído');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // BOTÃO
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () {
                final sku = product.sku;
                final precisaEscolher =
                    sku != "ROCA-250" &&
                        sku != "FLOR-250" &&
                        sku != "PURE-250";

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

void showGrindRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 380,
            minWidth: 280,
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

void showProductImageDialog(BuildContext context, Product product) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      Widget _buildDialogImage() {
        final path = product.imagePath;

        if (path.isEmpty) {
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white38,
            ),
          );
        }

        if (path.startsWith('http')) {
          return Image.network(
            path,
            fit: BoxFit.contain,
          );
        }

        if (path.startsWith('assets/')) {
          return Image.asset(
            path,
            fit: BoxFit.contain,
          );
        }

        final url = '$kProductImageBaseUrl$path';

        return Image.network(
          url,
          fit: BoxFit.contain,
        );
      }

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
                  child: _buildDialogImage(),
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
