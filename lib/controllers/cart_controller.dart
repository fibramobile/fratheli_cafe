import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  final String grind; // "Grão" ou "Moído"
  int quantity;

  CartItem({
    required this.product,
    required this.grind,
    required this.quantity,
  });
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _cep;

  List<CartItem> get items => List.unmodifiable(_items);

  double get subtotal =>
      _items.fold(0.0, (t, item) => t + item.product.price * item.quantity);

  int get totalItems =>
      _items.fold(0, (t, item) => t + item.quantity);

  String? get cep => _cep;

  // -------- ADICIONAR PRODUTO (AGORA COM GRIND) --------
  void addProduct(Product product, String grind) {
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

  // -------- ALTERAR QUANTIDADE (CONSIDERANDO GRIND) --------
  void changeQty(String sku, String grind, int delta) {
    final index = _items.indexWhere(
          (item) => item.product.sku == sku && item.grind == grind,
    );
    if (index == -1) return;

    _items[index].quantity += delta;
    if (_items[index].quantity <= 0) {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void setCep(String cep) {
    _cep = cep;
    notifyListeners();
  }

  // -------- MENSAGEM PARA O WHATSAPP --------
  String buildWhatsMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Olá! Segue o resumo do meu pedido Frathéli Café:');
    buffer.writeln('');

    for (final item in _items) {
      buffer.writeln(
        '${item.quantity}x ${item.product.name} (${item.grind}) '
            '- R\$ ${item.product.price.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('');
    buffer.writeln(
      'Subtotal (sem frete): R\$ ${subtotal.toStringAsFixed(2)}',
    );

    if (_cep != null && _cep!.isNotEmpty) {
      buffer.writeln('CEP para cálculo de frete: $_cep');
    }

    buffer.writeln('');
    buffer.writeln('Obrigado! ☕🐝');

    return buffer.toString();
  }
}
