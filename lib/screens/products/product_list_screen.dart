import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import 'add_edit_product_dialog.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _openAddEditDialog([Product? product]) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (ctx) => AddEditProductDialog(product: product),
    );

    if (result != null && mounted) {
      final provider = context.read<ProductProvider>();
      if (product == null) {
        await provider.addProduct(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk "${result.name}" berhasil ditambahkan!')),
        );
      } else {
        await provider.updateProduct(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk "${result.name}" berhasil diperbarui!')),
        );
      }
    }
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<ProductProvider>().deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Produk "${product.name}" telah dihapus.')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk & Stok'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => productProvider.loadProducts(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Category Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari produk atau kode barcode...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) => productProvider.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: productProvider.selectedCategory,
                  items: productProvider.categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      productProvider.setSelectedCategory(val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Product List
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productProvider.products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada produk yang ditemukan',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: productProvider.products.length,
                          itemBuilder: (ctx, index) {
                            final p = productProvider.products[index];
                            final isLowStock = p.stock <= 5;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isLowStock ? Colors.orange.shade100 : Colors.blue.shade100,
                                  child: Icon(
                                    isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2,
                                    color: isLowStock ? Colors.orange.shade800 : Colors.blue.shade800,
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kode: ${p.code} | Kategori: ${p.category}'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('Beli: ${currencyFormatter.format(p.buyPrice)}',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Text('Jual: ${currencyFormatter.format(p.sellPrice)}',
                                            style: const TextStyle(
                                                color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    )
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isLowStock ? Colors.red.shade300 : Colors.green.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        'Stok: ${p.stock} ${p.unit}',
                                        style: TextStyle(
                                          color: isLowStock ? Colors.red.shade700 : Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _openAddEditDialog(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(p),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}
