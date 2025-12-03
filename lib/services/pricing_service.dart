import 'package:http/http.dart' as http;
import '../models/pricing_models.dart';

class PricingService {
  static const String _url =
      'https://smapps.16mb.com/fratheli/app/pricings_data.json';

  Future<List<PricingProduct>> fetchPricingProducts() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar precificação: ${response.statusCode}');
    }

    return parsePricingProducts(response.body);
  }

  /// Retorna um mapa: productName -> PricingProduct
  Future<Map<String, PricingProduct>> fetchPricingMap() async {
    final list = await fetchPricingProducts();
    return {
      for (final p in list) p.productName.trim(): p,
    };
  }
}
