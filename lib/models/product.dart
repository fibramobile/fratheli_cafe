class Product {
  final String sku;
  final String name;
  final String description;
  final String imagePath;

  /// Preço final usado no site
  final double price;

  /// Preço original (para mostrar risco “de R$ 30 por R$ 25”)
  final double? originalPrice;

  final String tag;
  final bool tagAlt;
  final String meta;
  final bool inStock;

  // Dados extras
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
    this.originalPrice,
    required this.tag,
    required this.tagAlt,
    required this.meta,
    this.inStock = true,
    this.weightKg = 0.25,
    this.heightCm = 8,
    this.widthCm = 14,
    this.lengthCm = 20,
  });

  // 🔥 CONSTRUTOR PARA LER DO JSON (app → site)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',

      // Preço — prioriza o valor calculado da precificação
      price: (json['price'] ?? json['fallbackPrice'] ?? 0).toDouble(),

      // originalPrice é opcional
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,

      tag: json['tag'] ?? '',
      tagAlt: json['tagAlt'] ?? false,
      meta: json['meta'] ?? '',

      inStock: json['inStock'] ?? true,

      // Medidas opcionais (mantém defaults)
      weightKg: (json['weightKg'] ?? 0.25).toDouble(),
      heightCm: (json['heightCm'] ?? 8).toDouble(),
      widthCm: (json['widthCm'] ?? 14).toDouble(),
      lengthCm: (json['lengthCm'] ?? 20).toDouble(),
    );
  }

  // 🔄 (Opcional, caso o site precise salvar JSON futuramente)
  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'price': price,
      'originalPrice': originalPrice,
      'tag': tag,
      'tagAlt': tagAlt,
      'meta': meta,
      'inStock': inStock,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'widthCm': widthCm,
      'lengthCm': lengthCm,
    };
  }
}
