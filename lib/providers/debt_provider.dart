import 'package:flutter/foundation.dart';
import '../models/debt_model.dart';
import '../services/database_helper.dart';

class DebtProvider with ChangeNotifier {
  List<DebtModel> _debts = [];
  bool _isLoading = false;

  List<DebtModel> get debts => _debts;
  bool get isLoading => _isLoading;

  List<DebtModel> get unpaidDebts {
    return _debts.where((d) => d.status != 'paid').toList();
  }

  double get totalUnpaidDebt {
    return unpaidDebts.fold(0.0, (sum, d) => sum + d.remainingDebt);
  }

  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _debts = await DatabaseHelper.instance.getAllDebts();
    } catch (e) {
      debugPrint('Error loading debts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDebt(DebtModel debt) async {
    try {
      await DatabaseHelper.instance.insertDebt(debt);
      await loadDebts();
      return true;
    } catch (e) {
      debugPrint('Error adding debt: $e');
      return false;
    }
  }

  Future<bool> payDebt(String debtId, double amountPaid, {String? note}) async {
    try {
      final payment = DebtPaymentHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        debtId: debtId,
        amountPaid: amountPaid,
        paymentDate: DateTime.now(),
        note: note,
      );
      await DatabaseHelper.instance.addDebtPayment(payment);
      await loadDebts();
      return true;
    } catch (e) {
      debugPrint('Error adding debt payment: $e');
      return false;
    }
  }

  Future<List<DebtPaymentHistory>> getPaymentHistory(String debtId) async {
    return await DatabaseHelper.instance.getDebtPayments(debtId);
  }
}
