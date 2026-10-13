import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions();
      }
    });
  }

  void _showReceiptDialog(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.receipt, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 8),
            const Text('Struk Pembayaran / Nota', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(txn.invoiceNumber, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text('Tanggal: ${dateFormatter.format(txn.date)}'),
                Text('Metode: ${txn.paymentMethod}${txn.isDebt ? " (Hutang)" : ""}'),
                if (txn.customerName != null && txn.customerName!.isNotEmpty) Text('Pelanggan: ${txn.customerName}'),
                const Divider(),
                const Text('Daftar Barang:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...txn.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} x${item.quantity}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            currencyFormatter.format(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormatter.format(txn.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bayar:'),
                    Text(currencyFormatter.format(txn.paidAmount)),
                  ],
                ),
                if (!txn.isDebt)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kembali:'),
                      Text(currencyFormatter.format(txn.changeAmount)),
                    ],
                  ),
                if (txn.note != null && txn.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Catatan: ${txn.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Cetak Struk'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perintah cetak struk terkirim ke printer.')),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Penjualan'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => txnProvider.loadTransactions(),
          ),
        ],
      ),
      body: txnProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : txnProvider.transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Belum ada riwayat transaksi'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: txnProvider.transactions.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (ctx, idx) {
                    final t = txnProvider.transactions[idx];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: t.isDebt ? Colors.orange.shade100 : Colors.green.shade100,
                          child: Icon(
                            t.isDebt ? Icons.receipt_long : Icons.check_circle_outline,
                            color: t.isDebt ? Colors.orange.shade800 : Colors.green.shade800,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.invoiceNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              currencyFormatter.format(t.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Tanggal: ${dateFormatter.format(t.date)}'),
                            Text('Metode: ${t.paymentMethod} ${t.isDebt ? "(Hutang - ${t.customerName})" : ""}'),
                            Text('Jumlah item: ${t.items.fold(0, (s, i) => s + i.quantity)} barang'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          tooltip: 'Lihat Struk',
                          onPressed: () => _showReceiptDialog(t),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
