import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
  });

  double get subtotal => (product.sellPrice * quantity) - discount;

  double get totalBuyPrice => product.buyPrice * quantity;

  double get profit => subtotal - totalBuyPrice;

  Map<String, dynamic> toMap() {
    return {
      'product_id': product.id,
      'product_name': product.name,
      'product_code': product.code,
      'buy_price': product.buyPrice,
      'sell_price': product.sellPrice,
      'quantity': quantity,
      'discount': discount,
      'subtotal': subtotal,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, Product product) {
    return CartItem(
      product: product,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
