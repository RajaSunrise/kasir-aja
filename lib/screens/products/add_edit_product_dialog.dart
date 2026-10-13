import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';

class AddEditProductDialog extends StatefulWidget {
  final Product? product;

  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;

  final List<String> _presetCategories = ['Makanan', 'Minuman', 'Sembako', 'Snack', 'Umum'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _codeController = TextEditingController(text: p?.code ?? _generateCode());
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'Umum');
    _buyPriceController = TextEditingController(text: p != null ? p.buyPrice.toStringAsFixed(0) : '');
    _sellPriceController = TextEditingController(text: p != null ? p.sellPrice.toStringAsFixed(0) : '');
    _stockController = TextEditingController(text: p != null ? p.stock.toString() : '0');
    _unitController = TextEditingController(text: p?.unit ?? 'pcs');
  }

  String _generateCode() {
    return 'BRG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.product != null;
      final newProduct = Product(
        id: isEdit ? widget.product!.id : const Uuid().v4(),
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? 'Umum' : _categoryController.text.trim(),
        buyPrice: double.tryParse(_buyPriceController.text) ?? 0.0,
        sellPrice: double.tryParse(_sellPriceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        unit: _unitController.text.trim().isEmpty ? 'pcs' : _unitController.text.trim(),
        createdAt: isEdit ? widget.product!.createdAt : DateTime.now().toIso8601String(),
      );

      Navigator.of(context).pop(newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit_note : Icons.add_circle_outline,
            color: Colors.blueAccent,
          ),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode / Barcode Barang',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Kode wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Nama produk wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _presetCategories.contains(_categoryController.text)
                            ? _categoryController.text
                            : 'Umum',
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: _presetCategories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _categoryController.text = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli (Modal)',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Isi harga' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Isi harga' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Isi stok' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan (pcs, kg, dll)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _save,
          child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
        ),
      ],
    );
  }
}
