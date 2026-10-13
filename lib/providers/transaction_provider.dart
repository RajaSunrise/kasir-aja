import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalSales => _transactions.fold(0.0, (sum, t) => sum + t.totalAmount);

  int get totalTransactionCount => _transactions.length;

  List<TransactionModel> get todayTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day;
    }).toList();
  }

  double get todaySales {
    return todayTransactions.fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await DatabaseHelper.instance.getAllTransactions();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(TransactionModel txn) async {
    try {
      await DatabaseHelper.instance.insertTransaction(txn);
      await loadTransactions();
      return true;
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      return false;
    }
  }
}
