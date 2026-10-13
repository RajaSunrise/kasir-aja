class DebtModel {
  final String id;
  final String transactionId;
  final String customerName;
  final String customerPhone;
  final double totalDebt;
  final double paidAmount;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String status; // 'unpaid', 'partially_paid', 'paid'
  final String? note;

  DebtModel({
    required this.id,
    required this.transactionId,
    required this.customerName,
    required this.customerPhone,
    required this.totalDebt,
    this.paidAmount = 0.0,
    required this.createdAt,
    this.dueDate,
    this.status = 'unpaid',
    this.note,
  });

  double get remainingDebt => totalDebt - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_debt': totalDebt,
      'paid_amount': paidAmount,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'note': note,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String? ?? '',
      totalDebt: (map['total_debt'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      status: map['status'] as String? ?? 'unpaid',
      note: map['note'] as String?,
    );
  }

  DebtModel copyWith({
    String? id,
    String? transactionId,
    String? customerName,
    String? customerPhone,
    double? totalDebt,
    double? paidAmount,
    DateTime? createdAt,
    DateTime? dueDate,
    String? status,
    String? note,
  }) {
    return DebtModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalDebt: totalDebt ?? this.totalDebt,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}

class DebtPaymentHistory {
  final String id;
  final String debtId;
  final double amountPaid;
  final DateTime paymentDate;
  final String? note;

  DebtPaymentHistory({
    required this.id,
    required this.debtId,
    required this.amountPaid,
    required this.paymentDate,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'note': note,
    };
  }

  factory DebtPaymentHistory.fromMap(Map<String, dynamic> map) {
    return DebtPaymentHistory(
      id: map['id'] as String,
      debtId: map['debt_id'] as String,
      amountPaid: (map['amount_paid'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      note: map['note'] as String?,
    );
  }
}
