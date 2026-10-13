import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  List<CartItem> get cartList => _items.values.toList();

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get totalProfit {
    return _items.values.fold(0.0, (sum, item) => sum + item.profit);
  }

  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      final current = _items[product.id]!;
      if (current.quantity < product.stock) {
        current.quantity += 1;
      }
    } else {
      if (product.stock > 0) {
        _items[product.id] = CartItem(product: product, quantity: 1);
      }
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        final item = _items[productId]!;
        if (quantity <= item.product.stock) {
          item.quantity = quantity;
        }
      }
      notifyListeners();
    }
  }

  void setDiscount(String productId, double discount) {
    if (_items.containsKey(productId)) {
      _items[productId]!.discount = discount < 0 ? 0 : discount;
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
