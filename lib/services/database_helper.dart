import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Allow setting in-memory database for testing
  static void setMockDatabase(Database db) {
    _database = db;
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        code $textType,
        name $textType,
        category $textType,
        buy_price $realType,
        sell_price $realType,
        stock $intType,
        unit $textType,
        created_at $textType
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        invoice_number $textType,
        date $textType,
        total_amount $realType,
        discount_total $realType,
        paid_amount $realType,
        change_amount $realType,
        payment_method $textType,
        is_debt $intType,
        customer_name $textNullable,
        customer_phone $textNullable,
        note $textNullable
      )
    ''');

    // Transaction Items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transaction_id $textType,
        product_id $textType,
        product_name $textType,
        product_code $textType,
        buy_price $realType,
        sell_price $realType,
        quantity $intType,
        discount $realType,
        subtotal $realType,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    // Debts table
    await db.execute('''
      CREATE TABLE debts (
        id $idType,
        transaction_id $textType,
        customer_name $textType,
        customer_phone $textType,
        total_debt $realType,
        paid_amount $realType,
        created_at $textType,
        due_date $textNullable,
        status $textType,
        note $textNullable
      )
    ''');

    // Debt Payments table
    await db.execute('''
      CREATE TABLE debt_payments (
        id $idType,
        debt_id $textType,
        amount_paid $realType,
        payment_date $textType,
        note $textNullable,
        FOREIGN KEY (debt_id) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- PRODUCT CRUD ---

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> updateProductStock(String productId, int newStock) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- TRANSACTION OPERATIONS ---

  Future<int> insertTransaction(TransactionModel txn) async {
    final db = await instance.database;
    int result = 0;

    await db.transaction((txnDb) async {
      result = await txnDb.insert('transactions', txn.toMap());

      for (var item in txn.items) {
        final itemId = '${DateTime.now().microsecondsSinceEpoch}_${item.product.id}';
        await txnDb.insert('transaction_items', {
          'id': itemId,
          'transaction_id': txn.id,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'product_code': item.product.code,
          'buy_price': item.product.buyPrice,
          'sell_price': item.product.sellPrice,
          'quantity': item.quantity,
          'discount': item.discount,
          'subtotal': item.subtotal,
        });

        // Reduce product stock directly within transaction context
        final productRows = await txnDb.query('products', where: 'id = ?', whereArgs: [item.product.id]);
        if (productRows.isNotEmpty) {
          final currentStock = (productRows.first['stock'] as num).toInt();
          final updatedStock = currentStock - item.quantity;
          await txnDb.update(
            'products',
            {'stock': updatedStock < 0 ? 0 : updatedStock},
            where: 'id = ?',
            whereArgs: [item.product.id],
          );
        }
      }
    });

    return result;
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final txns = await db.query('transactions', orderBy: 'date DESC');

    List<TransactionModel> list = [];
    for (var t in txns) {
      final txnId = t['id'] as String;
      final itemRows = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [txnId],
      );

      List<CartItem> items = itemRows.map((map) {
        final product = Product(
          id: map['product_id'] as String,
          code: map['product_code'] as String? ?? '',
          name: map['product_name'] as String? ?? '',
          category: 'Umum',
          buyPrice: (map['buy_price'] as num).toDouble(),
          sellPrice: (map['sell_price'] as num).toDouble(),
          stock: 0,
          unit: 'pcs',
          createdAt: DateTime.now().toIso8601String(),
        );
        return CartItem.fromMap(map, product);
      }).toList();

      list.add(TransactionModel.fromMap(t, items));
    }

    return list;
  }

  // --- DEBT OPERATIONS ---

  Future<int> insertDebt(DebtModel debt) async {
    final db = await instance.database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<DebtModel>> getAllDebts() async {
    final db = await instance.database;
    final result = await db.query('debts', orderBy: 'created_at DESC');
    return result.map((map) => DebtModel.fromMap(map)).toList();
  }

  Future<int> addDebtPayment(DebtPaymentHistory payment) async {
    final db = await instance.database;
    int res = 0;

    await db.transaction((txnDb) async {
      res = await txnDb.insert('debt_payments', payment.toMap());

      // Get debt record inside transaction context
      final debtRows = await txnDb.query('debts', where: 'id = ?', whereArgs: [payment.debtId]);
      if (debtRows.isNotEmpty) {
        final currentDebt = DebtModel.fromMap(debtRows.first);
        final newPaid = currentDebt.paidAmount + payment.amountPaid;
        String newStatus = 'partially_paid';
        if (newPaid >= currentDebt.totalDebt) {
          newStatus = 'paid';
        }

        await txnDb.update(
          'debts',
          {
            'paid_amount': newPaid,
            'status': newStatus,
          },
          where: 'id = ?',
          whereArgs: [payment.debtId],
        );
      }
    });

    return res;
  }

  Future<List<DebtPaymentHistory>> getDebtPayments(String debtId) async {
    final db = await instance.database;
    final result = await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'payment_date DESC',
    );
    return result.map((map) => DebtPaymentHistory.fromMap(map)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
