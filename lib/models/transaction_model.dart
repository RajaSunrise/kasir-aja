import 'cart_item.dart';

class TransactionModel {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final List<CartItem> items;
  final double totalAmount;
  final double discountTotal;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod; // Cash, Debt, QRIS, Transfer
  final bool isDebt;
  final String? customerName;
  final String? customerPhone;
  final String? note;

  TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.discountTotal = 0.0,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.isDebt = false,
    this.customerName,
    this.customerPhone,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'discount_total': discountTotal,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'is_debt': isDebt ? 1 : 0,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, List<CartItem> items) {
    return TransactionModel(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      date: DateTime.parse(map['date'] as String),
      items: items,
      totalAmount: (map['total_amount'] as num).toDouble(),
      discountTotal: (map['discount_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'Cash',
      isDebt: (map['is_debt'] as int?) == 1,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      note: map['note'] as String?,
    );
  }
}
