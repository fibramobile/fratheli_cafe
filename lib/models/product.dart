class Product {
  final String sku;
  final String name;
  final String description;
  final String imagePath;
  final double price;          // preço atual (com desconto)
  final double? originalPrice; // preço antigo (sem desconto)
  final String tag;
  final bool tagAlt;
  final String meta;
  final bool inStock;

  // Campos extras para futuro frete
  final double weightKg;
  final double heightCm;
  final double widthCm;
  final double lengthCm;

  const Product({
    required this.sku,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.price,
    this.originalPrice,    // 👈 novo
    required this.tag,
    required this.tagAlt,
    required this.meta,
    this.inStock = true, // 👈 padrão é com estoque
    this.weightKg = 0.25,
    this.heightCm = 8,
    this.widthCm = 14,
    this.lengthCm = 20,
  });
}
