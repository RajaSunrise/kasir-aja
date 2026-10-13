import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/debt_provider.dart';

class DashboardReportScreen extends StatefulWidget {
  const DashboardReportScreen({super.key});

  @override
  State<DashboardReportScreen> createState() => _DashboardReportScreenState();
}

class _DashboardReportScreenState extends State<DashboardReportScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().loadProducts();
      context.read<TransactionProvider>().loadTransactions();
      context.read<DebtProvider>().loadDebts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final debtProvider = context.watch<DebtProvider>();
    final productProvider = context.watch<ProductProvider>();

    final totalProducts = productProvider.allProducts.length;
    final lowStockProducts = productProvider.allProducts.where((p) => p.stock <= 5).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard & Laporan Ringkas'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Penjualan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Penjualan Hari Ini',
                    value: currencyFormatter.format(txnProvider.todaySales),
                    subtitle: '${txnProvider.todayTransactions.length} Transaksi Hari Ini',
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Omset Penjualan',
                    value: currencyFormatter.format(txnProvider.totalSales),
                    subtitle: '${txnProvider.totalTransactionCount} Total Transaksi',
                    icon: Icons.monetization_on,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Piutang/Hutang',
                    value: currencyFormatter.format(debtProvider.totalUnpaidDebt),
                    subtitle: '${debtProvider.unpaidDebts.length} Pelanggan Belum Lunas',
                    icon: Icons.receipt_long,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Katalog & Stok Barang',
                    value: '$totalProducts Jenis',
                    subtitle: '$lowStockProducts Produk Stok Menipis (<=5)',
                    icon: Icons.inventory,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            txnProvider.transactions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Belum ada transaksi.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txnProvider.transactions.length > 5 ? 5 : txnProvider.transactions.length,
                    itemBuilder: (ctx, idx) {
                      final t = txnProvider.transactions[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t.isDebt ? Colors.orange.shade100 : Colors.green.shade100,
                          child: Icon(
                            t.isDebt ? Icons.receipt_long : Icons.check,
                            color: t.isDebt ? Colors.orange.shade800 : Colors.green.shade800,
                          ),
                        ),
                        title: Text(t.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(t.date)),
                        trailing: Text(
                          currencyFormatter.format(t.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.shade100,
                  child: Icon(icon, size: 20, color: color.shade800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.shade900),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
