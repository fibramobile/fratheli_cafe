class Product {
  final String sku;
  final String name;
  final String description;
  final String imagePath;

  final double price;
  final double? originalPrice;

  final String tag;
  final bool tagAlt;
  final String meta;
  final bool inStock;

  final String? pricingName;    // 🔥 novo campo mantido!
  final double weightKg;
  final double heightCm;
  final double widthCm;
  final double lengthCm;

  final String? size;
  final List<String> grindOptions;
  final String? defaultGrind;
  final String? stockKey;

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
    this.pricingName,     // 👈 novo
    this.weightKg = 0.25,
    this.heightCm = 8,
    this.widthCm = 14,
    this.lengthCm = 20,
    this.size,
    this.grindOptions = const [],
    this.defaultGrind,
    this.stockKey,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] ?? '';
    final pricingName = json['pricingName'] ?? '';

    final displayName = pricingName.isNotEmpty
        ? '$pricingName - $rawName'
        : rawName;

    final grindList = (json['grindOptions'] as List?)
        ?.whereType<String>()
        .toList() ??
        const [];

    return Product(
      sku: json['sku'] ?? '',
      name: displayName, // 🔥 título completo
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      price: (json['price'] ?? json['fallbackPrice'] ?? 0).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      tag: json['tag'] ?? '',
      tagAlt: json['tagAlt'] ?? false,
      meta: json['meta'] ?? '',
      inStock: json['inStock'] ?? true,
      pricingName: pricingName, // 🔥 armazenado!
      weightKg: (json['weightKg'] ?? 0.25).toDouble(),
      heightCm: (json['heightCm'] ?? 8).toDouble(),
      widthCm: (json['widthCm'] ?? 14).toDouble(),
      lengthCm: (json['lengthCm'] ?? 20).toDouble(),
      size: json['size'],
      grindOptions: grindList,
      defaultGrind: json['defaultGrind'],
      stockKey: json['stockKey'],
    );
  }
}
