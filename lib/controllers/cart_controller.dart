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

// ✅ NOVO: modos de frete
enum FreightMode { calculated, free, combine, external }

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _cep;

  List<CartItem> get items => List.unmodifiable(_items);

  double get subtotal =>
      _items.fold(0.0, (t, item) => t + item.product.price * item.quantity);

  int get totalItems => _items.fold(0, (t, item) => t + item.quantity);

  String? get cep => _cep;

  // ✅ NOVO: modo de frete (default = calculado)
  FreightMode freightMode = FreightMode.calculated;

  // ✅ NOVO: Compra externa (título obrigatório)
  String? externalTitle;
  String? externalDescription;

  bool get isExternalOk =>
      freightMode != FreightMode.external ||
          (externalTitle != null && externalTitle!.trim().isNotEmpty);


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

  /// ✅ Mantém sua função, mas agora ela "trava" modo calculado
  void setFreight({
    required double value,
    required String service,
    required String prazo,
  }) {
    freightMode = FreightMode.calculated;
    freightValue = value;
    freightService = service;
    freightDeadline = prazo;
    notifyListeners();
  }

  /// ✅ NOVO: setar Frete Grátis
  void setFreeFreight() {
    freightMode = FreightMode.free;
    freightValue = 0.0;
    freightService = 'Frete grátis';
    freightDeadline = '';
    notifyListeners();
  }

  /// ✅ NOVO: setar "Frete a combinar"
  void setFreightToCombine() {
    freightMode = FreightMode.combine;
    freightValue = 0.0; // não cobra agora
    freightService = 'Frete a combinar';
    freightDeadline = '';
    notifyListeners();
  }

  /// ✅ NOVO: voltar para modo calculado (opcional)
  void setCalculatedMode() {
    freightMode = FreightMode.calculated;
    // você decide se limpa ou mantém o último frete:
    // freightValue = null;
    // freightService = null;
    // freightDeadline = null;
    notifyListeners();
  }

  void clearFreight() {
    freightValue = null;
    freightService = null;
    freightDeadline = null;
    // volta para calculado por padrão
    freightMode = FreightMode.calculated;
    notifyListeners();
  }

  /// ✅ NOVO: frete efetivo (o que soma no total)
  double get effectiveFreight {
    if (freightMode == FreightMode.free) return 0.0;
    if (freightMode == FreightMode.combine) return 0.0;
    if (freightMode == FreightMode.external) return 0.0;
    return freightValue ?? 0.0;
  }


  double get totalWithFreight => subtotal + effectiveFreight;

  ///------------------------
  ///      Pedido externo
  /// ----------------------
  void setExternalPurchase({
    required String title,
    String? description,
  }) {
    freightMode = FreightMode.external;

    externalTitle = title.trim();
    externalDescription =
    (description ?? '').trim().isEmpty ? null : description!.trim();

    // Para compra externa: não calcula frete agora
    freightValue = 0.0;
    freightService = 'Compra externa';
    freightDeadline = '';

    notifyListeners();
  }

  void clearExternalPurchase() {
    externalTitle = null;
    externalDescription = null;

    // Se quiser: volta pro modo calculado por padrão
    freightMode = FreightMode.calculated;

    notifyListeners();
  }


  /// -------- ADICIONAR PRODUTO (AGORA COM GRIND) --------
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
        '- ${item.quantity}x ${item.product.name} (${item.grind}) '
            '— ${brl(item.product.price * item.quantity)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('Subtotal: ${brl(subtotal)}');

    /// --------------------------
    /// ✅ Ajuste para os modos
    ///  ------------------------
    if (freightMode == FreightMode.free) {
      buffer.writeln('Frete: grátis');
      buffer.writeln('Total: ${brl(totalWithFreight)}');
    } else if (freightMode == FreightMode.combine) {
      buffer.writeln('Frete: a combinar');
      buffer.writeln('Total (sem frete): ${brl(totalWithFreight)}');
    } else if (freightMode == FreightMode.external) {
      buffer.writeln('Entrega/Compra: compra externa');
      buffer.writeln('Título: ${externalTitle ?? ''}');
      if (externalDescription != null && externalDescription!.isNotEmpty) {
        buffer.writeln('Descrição: $externalDescription');
      }
      buffer.writeln('Total (sem frete): ${brl(totalWithFreight)}');
    } else {
      // calculated
      if (freightValue != null) {
        buffer.writeln(
          'Frete: ${brl(freightValue!)} — ${freightService ?? ''}'
              '${(freightDeadline != null && freightDeadline!.isNotEmpty) ? ' ($freightDeadline)' : ''}',
        );
        buffer.writeln('Total com frete: ${brl(totalWithFreight)}');
      } else {
        buffer.writeln('Frete: a calcular');
      }
    }


    // CEP: só faz sentido quando for calculado, mas pode manter se quiser
    if (cep != null && cep!.isNotEmpty) {
      buffer.writeln('CEP de entrega: $cep');
    }

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
