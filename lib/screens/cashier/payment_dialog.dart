import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(
    String paymentMethod,
    double paidAmount,
    double changeAmount,
    bool isDebt,
    String? customerName,
    String? customerPhone,
    DateTime? dueDate,
    String? note,
  ) onConfirm;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String _selectedMethod = 'Cash'; // Cash, Debt, QRIS, Transfer
  late TextEditingController _paidController;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _paidController = TextEditingController(text: widget.totalAmount.toStringAsFixed(0));
    _dueDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _paidController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setQuickCash(double amount) {
    setState(() {
      _paidController.text = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double paid = double.tryParse(_paidController.text) ?? 0.0;
    final bool isDebt = _selectedMethod == 'Debt';
    final double change = isDebt ? 0.0 : (paid - widget.totalAmount);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          const Icon(Icons.payments, size: 40, color: Colors.green),
          const SizedBox(height: 8),
          const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(widget.totalAmount),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Cash', label: Text('Tunai'), icon: Icon(Icons.money)),
                  ButtonSegment(value: 'Debt', label: Text('Hutang'), icon: Icon(Icons.receipt_long)),
                  ButtonSegment(value: 'QRIS', label: Text('QRIS'), icon: Icon(Icons.qr_code_2)),
                ],
                selected: {_selectedMethod},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedMethod = set.first;
                    if (_selectedMethod == 'QRIS') {
                      _paidController.text = widget.totalAmount.toStringAsFixed(0);
                    } else if (_selectedMethod == 'Debt') {
                      _paidController.text = '0';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_selectedMethod == 'Cash') ...[
                TextFormField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Uang Diterima',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    widget.totalAmount,
                    50000.0,
                    100000.0,
                  ].map((amt) {
                    return ActionChip(
                      label: Text(currencyFormatter.format(amt)),
                      onPressed: () => _setQuickCash(amt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: change >= 0 ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        change >= 0 ? 'Kembalian:' : 'Uang Kurang:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: change >= 0 ? Colors.green.shade900 : Colors.red.shade900),
                      ),
                      Text(
                        currencyFormatter.format(change.abs()),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: change >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_selectedMethod == 'Debt') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pencatatan Hutang / Kasbon Pelanggan',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pelanggan / Pemutang *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'No. WhatsApp / Telepon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Uang Muka / Uang DP (opsional)',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month, color: Colors.blue),
                  title: Text(
                    _dueDate == null
                        ? 'Pilih Tanggal Jatuh Tempo'
                        : 'Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(_dueDate!)}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _dueDate = picked;
                        });
                      }
                    },
                    child: const Text('Ubah'),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Transaksi (opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: isDebt
              ? (_customerNameController.text.trim().isEmpty
                  ? null
                  : () {
                      widget.onConfirm(
                        _selectedMethod,
                        paid,
                        0.0,
                        true,
                        _customerNameController.text.trim(),
                        _customerPhoneController.text.trim(),
                        _dueDate,
                        _noteController.text.trim(),
                      );
                      Navigator.of(context).pop(true);
                    })
              : (paid < widget.totalAmount
                  ? null
                  : () {
                      widget.onConfirm(
                        _selectedMethod,
                        paid,
                        change,
                        false,
                        null,
                        null,
                        null,
                        _noteController.text.trim(),
                      );
                      Navigator.of(context).pop(true);
                    }),
          child: const Text('Selesaikan Transaksi'),
        ),
      ],
    );
  }
}
