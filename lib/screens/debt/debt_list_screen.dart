import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_provider.dart';
import '../../models/debt_model.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<DebtProvider>().loadDebts();
      }
    });
  }

  void _showPayModal(DebtModel debt) {
    final amountController = TextEditingController(text: debt.remainingDebt.toStringAsFixed(0));
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payments, color: Colors.green),
            const SizedBox(width: 8),
            Text('Pelunasan Hutang - ${debt.customerName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Sisa Hutang: ${currencyFormatter.format(debt.remainingDebt)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Pembayaran / Cicilan',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan Pembayaran (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              final paidAmt = double.tryParse(amountController.text) ?? 0.0;
              if (paidAmt > 0) {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                await context.read<DebtProvider>().payDebt(
                      debt.id,
                      paidAmt,
                      note: noteController.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pembayaran hutang ${debt.customerName} berhasil dicatat!')),
                  );
                }
              }
            },
            child: const Text('Simpan Pembayaran'),
          ),
        ],
      ),
    );
  }

  void _showHistoryModal(DebtModel debt) async {
    final history = await context.read<DebtProvider>().getPaymentHistory(debt.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Pembayaran - ${debt.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('Belum ada riwayat cicilan/pembayaran.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (c, i) {
                    final p = history[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.greenAccent,
                        child: Icon(Icons.check, color: Colors.black),
                      ),
                      title: Text(currencyFormatter.format(p.amountPaid),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${dateFormatter.format(p.paymentDate)}${p.note != null && p.note!.isNotEmpty ? " - ${p.note}" : ""}',
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Hutang Pelanggan'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => debtProvider.loadDebts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Unpaid Debt Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Piutang / Hutang Belum Lunas', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Sisa Piutang Keseluruhan', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                Text(
                  currencyFormatter.format(debtProvider.totalUnpaidDebt),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Debtors List
          Expanded(
            child: debtProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : debtProvider.debts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Tidak ada catatan hutang / kasbon'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: debtProvider.debts.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (ctx, idx) {
                          final debt = debtProvider.debts[idx];
                          final isPaid = debt.status == 'paid';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(
                                  isPaid ? Icons.check_circle : Icons.receipt_long,
                                  color: isPaid ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    debt.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.green.shade100
                                          : (debt.status == 'partially_paid'
                                              ? Colors.orange.shade100
                                              : Colors.red.shade100),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPaid
                                          ? 'LUNAS'
                                          : (debt.status == 'partially_paid' ? 'DICICIL' : 'BELUM BAYAR'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isPaid
                                            ? Colors.green.shade900
                                            : (debt.status == 'partially_paid'
                                                ? Colors.orange.shade900
                                                : Colors.red.shade900),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (debt.customerPhone.isNotEmpty) Text('HP: ${debt.customerPhone}'),
                                    Text('Tanggal Buat: ${dateFormatter.format(debt.createdAt)}'),
                                    if (debt.dueDate != null)
                                      Text(
                                        'Jatuh Tempo: ${dateFormatter.format(debt.dueDate!)}',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total: ${currencyFormatter.format(debt.totalDebt)}'),
                                        Text(
                                          'Sisa: ${currencyFormatter.format(debt.remainingDebt)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.history, color: Colors.blue),
                                    tooltip: 'Riwayat Pembayaran',
                                    onPressed: () => _showHistoryModal(debt),
                                  ),
                                  if (!isPaid)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      onPressed: () => _showPayModal(debt),
                                      child: const Text('Bayar'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
