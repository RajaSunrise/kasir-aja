import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/debt_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/debt_model.dart';
import 'payment_dialog.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
      }
    });
  }

  void _openPaymentModal() async {
    final cartProvider = context.read<CartProvider>();
    if (cartProvider.items.isEmpty) return;

    final total = cartProvider.totalAmount;

    await showDialog(
      context: context,
      builder: (ctx) => PaymentDialog(
        totalAmount: total,
        onConfirm: (method, paidAmount, changeAmount, isDebt, name, phone, dueDate, note) async {
          final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
          final txnId = const Uuid().v4();

          final transaction = TransactionModel(
            id: txnId,
            invoiceNumber: invoiceNo,
            date: DateTime.now(),
            items: cartProvider.cartList,
            totalAmount: total,
            paidAmount: paidAmount,
            changeAmount: changeAmount,
            paymentMethod: method,
            isDebt: isDebt,
            customerName: name,
            customerPhone: phone,
            note: note,
          );

          if (!mounted) return;
          await context.read<TransactionProvider>().addTransaction(transaction);

          if (isDebt && name != null) {
            final debt = DebtModel(
              id: const Uuid().v4(),
              transactionId: txnId,
              customerName: name,
              customerPhone: phone ?? '',
              totalDebt: total,
              paidAmount: paidAmount,
              createdAt: DateTime.now(),
              dueDate: dueDate,
              status: paidAmount >= total ? 'paid' : (paidAmount > 0 ? 'partially_paid' : 'unpaid'),
              note: note,
            );
            if (!mounted) return;
            await context.read<DebtProvider>().addDebt(debt);
          }

          // Reload products to refresh stock UI
          if (mounted) {
            await context.read<ProductProvider>().loadProducts();
            cartProvider.clearCart();

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transaksi $invoiceNo Berhasil Disimpan!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir / Point of Sale'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => productProvider.loadProducts(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Product Selection Grid
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Search and Category
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari produk / barcode...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (val) => productProvider.setSearchQuery(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: productProvider.selectedCategory,
                        items: productProvider.categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) productProvider.setSelectedCategory(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Products Grid
                  Expanded(
                    child: productProvider.products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('Produk tidak ditemukan'),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: productProvider.products.length,
                            itemBuilder: (ctx, idx) {
                              final p = productProvider.products[idx];
                              final isOutOfStock = p.stock <= 0;

                              return InkWell(
                                onTap: isOutOfStock ? null : () => cartProvider.addToCart(p),
                                borderRadius: BorderRadius.circular(12),
                                child: Card(
                                  elevation: isOutOfStock ? 0 : 2,
                                  color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isOutOfStock ? Colors.grey.shade300 : Colors.blue.shade100,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                p.category,
                                                style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                                              ),
                                            ),
                                            Text(
                                              'Stok: ${p.stock}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isOutOfStock ? Colors.red : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          p.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isOutOfStock ? Colors.grey : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter.format(p.sellPrice),
                                          style: TextStyle(
                                            color: isOutOfStock ? Colors.grey : Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Cart & Summary Side Panel
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(left: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue.shade800,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Keranjang',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (cartProvider.items.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => cartProvider.clearCart(),
                            icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 18),
                            label: const Text('Kosongkan', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),

                  // Cart Item List
                  Expanded(
                    child: cartProvider.items.isEmpty
                        ? Center(
                            child: Text(
                              'Keranjang belanja kosong',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.separated(
                            itemCount: cartProvider.cartList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final item = cartProvider.cartList[idx];
                              return ListTile(
                                dense: true,
                                title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${currencyFormatter.format(item.product.sellPrice)} x ${item.quantity}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currencyFormatter.format(item.subtotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                                      onPressed: () =>
                                          cartProvider.updateQuantity(item.product.id, item.quantity - 1),
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                                      onPressed: () =>
                                          cartProvider.updateQuantity(item.product.id, item.quantity + 1),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Cart Total Footer & Pay Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              currencyFormatter.format(cartProvider.totalAmount),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: cartProvider.items.isEmpty ? null : _openPaymentModal,
                            child: const Text(
                              'Bayar / Proses Transaksi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
