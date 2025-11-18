import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final void Function(String grind) onAdd; // recebe "Grão" ou "Moído"

  const ProductCard({
    required this.product,
    required this.onAdd,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String _selectedGrind = 'Grão'; // valor padrão

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
            //  onTap: () => showProductImageDialog(context, product),
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
          ),

          const SizedBox(height: 10),

          // BOTÃO
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
        ],
      ),
    );
  }
}