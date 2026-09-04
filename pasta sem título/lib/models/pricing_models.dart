import 'dart:convert';

class PricingItem {
  final String name;
  final String description;
  final double costPerKg;

  PricingItem({
    required this.name,
    required this.description,
    required this.costPerKg,
  });

  factory PricingItem.fromMap(Map<String, dynamic> map) {
    return PricingItem(
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      costPerKg: (map['costPerKg'] as num).toDouble(),
    );
  }
}

class PricingProduct {
  final String productName;
  final double markupPercent;
  final List<PricingItem> items;

  PricingProduct({
    required this.productName,
    required this.markupPercent,
    required this.items,
  });

  factory PricingProduct.fromMap(Map<String, dynamic> map) {
    return PricingProduct(
      productName: map['productName'] as String,
      markupPercent: (map['markupPercent'] as num).toDouble(),
      items: (map['items'] as List<dynamic>)
          .map((e) => PricingItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Soma dos custos por kg
  double get totalCostPerKg =>
      items.fold(0.0, (sum, item) => sum + item.costPerKg);

  /// Preço de venda por kg (custo * (1 + markup/100))
  double get salePricePerKg =>
      totalCostPerKg * (1 + markupPercent / 100);

  /// Preço para um determinado peso em kg (ex: 0.25 para 250g)
  double unitPriceKg(double weightKg) {
    return salePricePerKg * weightKg;
  }

  /// Helper: preço 250g
  double get price250g {
    final value = unitPriceKg(0.25);
    // Arredonda com 2 casas
    return double.parse(value.toStringAsFixed(2));
  }
}

/// Parse de uma lista
List<PricingProduct> parsePricingProducts(String jsonStr) {
  final data = json.decode(jsonStr) as List<dynamic>;
  return data
      .map((e) => PricingProduct.fromMap(e as Map<String, dynamic>))
      .toList();
}
