import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  List<Product> get products {
    return _products.where((p) {
      final matchesQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<Product> get allProducts => _products;

  List<String> get categories {
    final list = _products.map((p) => p.category).toSet().toList();
    list.sort();
    return ['Semua', ...list];
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await DatabaseHelper.instance.getAllProducts();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> addProduct(Product product) async {
    try {
      await DatabaseHelper.instance.insertProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await DatabaseHelper.instance.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await DatabaseHelper.instance.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  Product? getById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
