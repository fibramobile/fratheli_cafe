import 'product.dart';

class CartItem {
  final Product product;
  final String grind; // "Grão" ou "Moído"
  int quantity;

  CartItem({
    required this.product,
    required this.grind,
    this.quantity = 1,
  });

  double get total => product.price * quantity;
}
