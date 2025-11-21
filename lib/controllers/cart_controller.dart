import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../utils/formatters.dart';

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
  double get subtotal => _items.fold(0.0, (t, item) => t + item.product.price * item.quantity);
  int get totalItems => _items.fold(0, (t, item) => t + item.quantity);
  String? get cep => _cep;
  double? freightValue;
  String? freightService;
  String? freightDeadline;
  String? customerName;
  String? customerPhone;
  String? customerCpf;
  String? customerAddress;

  void setCustomerData({
    required String name,
    required String phone,
    required String cpf,
    required String address,
  }) {
    customerName = name;
    customerPhone = phone;
    customerCpf = cpf;
    customerAddress = address;
    notifyListeners();
  }


  void setFreight({
    required double value,
    required String service,
    required String prazo,
  }) {
    freightValue = value;
    freightService = service;
    freightDeadline = prazo;
    notifyListeners();
  }

  void clearFreight() {
    freightValue = null;
    freightService = null;
    freightDeadline = null;
    notifyListeners();
  }

  double get totalWithFreight => subtotal + (freightValue ?? 0);

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
    clearFreight();
    // se tiver cep salvo e quiser manter, não mexe nele
    notifyListeners();
  }


  void setCep(String cep) {
    _cep = cep;
    notifyListeners();
  }

  // -------- MENSAGEM PARA O WHATSAPP --------


  String buildWhatsMessage() {
    final buffer = StringBuffer();

    buffer.writeln('Novo pedido Frathéli Café:');
    buffer.writeln('');

    for (final item in items) {
      buffer.writeln(
        '- ${item.quantity}x ${item.product.name} (${item.grind ?? 'Grão/Moído'}) '
            '— ${brl(item.product.price * item.quantity)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('Subtotal: ${brl(subtotal)}');

    if (freightValue != null) {
      buffer.writeln(
        'Frete: ${brl(freightValue!)} — $freightService ($freightDeadline)',
      );
      buffer.writeln('Total com frete: ${brl(totalWithFreight)}');
    } else {
      buffer.writeln('Frete: a calcular');
    }

    if (cep != null && cep!.isNotEmpty) {
      buffer.writeln('CEP de entrega: $cep');
    }

    // 🔻 DADOS DO CLIENTE
    if (customerName != null &&
        customerPhone != null &&
        customerCpf != null &&
        customerAddress != null &&
        customerName!.isNotEmpty &&
        customerPhone!.isNotEmpty &&
        customerCpf!.isNotEmpty &&
        customerAddress!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📦 Dados para envio:');
      buffer.writeln('Nome: $customerName');
      buffer.writeln('CPF: $customerCpf');
      buffer.writeln('Telefone: $customerPhone');
      buffer.writeln('Endereço:');
      buffer.writeln(customerAddress);
    }

    return buffer.toString();
  }



}
