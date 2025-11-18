import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../utils/formatters.dart';

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  String _cep = '';

  List<CartItem> get items => List.unmodifiable(_items);
  String get cep => _cep;

  int get totalItems =>
      _items.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (total, item) => total + item.total);
/*
  void addProduct(Product product) {
    final index =
    _items.indexWhere((item) => item.product.sku == product.sku);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }
*/
  void addProduct(Product product, String grind) {
    // se já existir o MESMO produto com a MESMA moagem, só soma quantidade
    final index = _items.indexWhere(
          (item) => item.product.sku == product.sku && item.grind == grind,
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(
          product: product,
          grind: grind,
          quantity: 1,
        ),
      );
    }

    notifyListeners();
  }

  void changeQty(String sku, int delta) {
    final index =
    _items.indexWhere((item) => item.product.sku == sku);
    if (index < 0) return;

    final item = _items[index];
    item.quantity += delta;

    if (item.quantity <= 0) {
      _items.removeAt(index);
    }

    notifyListeners();
  }

  void removeItem(String sku) {
    _items.removeWhere((item) => item.product.sku == sku);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _cep = '';
    notifyListeners();
  }

  void setCep(String cep) {
    _cep = cep;
    notifyListeners();
  }

  String buildWhatsMessage() {
    if (_items.isEmpty) {
      return 'Meu carrinho está vazio, mas tenho interesse nos cafés Frathéli.';
    }

    final linhas = <String>[];
    linhas.add('🧺 *Pedido Frathéli Café*');
    linhas.add('');

    for (final item in _items) {
      linhas.add(
          '• ${item.product.name} (SKU ${item.product.sku}) × ${item.quantity} — ${brl(item.total)}');
    }

    linhas.add('');
    linhas.add('Subtotal (produtos): *${brl(subtotal)}*');
    linhas.add('Frete: *a calcular*');
    linhas.add('Total (sem frete): *${brl(subtotal)}*');

    if (_cep.isNotEmpty) {
      linhas.add('');
      linhas.add('CEP destino: $_cep');
    }

    linhas.add('');
    linhas.add(
        '_Poderia calcular o frete para o CEP $_cep e me enviar o orçamento._');

    return linhas.join('\n');
  }
}
