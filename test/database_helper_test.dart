import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kasir_app/models/product.dart';
import 'package:kasir_app/models/cart_item.dart';
import 'package:kasir_app/models/transaction_model.dart';
import 'package:kasir_app/models/debt_model.dart';
import 'package:kasir_app/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper CRUD Tests', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE products (
                  id TEXT PRIMARY KEY,
                  code TEXT NOT NULL,
                  name TEXT NOT NULL,
                  category TEXT NOT NULL,
                  buy_price REAL NOT NULL,
                  sell_price REAL NOT NULL,
                  stock INTEGER NOT NULL,
                  unit TEXT NOT NULL,
                  created_at TEXT NOT NULL
                )
              ''');

              await db.execute('''
                CREATE TABLE transactions (
                  id TEXT PRIMARY KEY,
                  invoice_number TEXT NOT NULL,
                  date TEXT NOT NULL,
                  total_amount REAL NOT NULL,
                  discount_total REAL NOT NULL,
                  paid_amount REAL NOT NULL,
                  change_amount REAL NOT NULL,
                  payment_method TEXT NOT NULL,
                  is_debt INTEGER NOT NULL,
                  customer_name TEXT,
                  customer_phone TEXT,
                  note TEXT
                )
              ''');

              await db.execute('''
                CREATE TABLE transaction_items (
                  id TEXT PRIMARY KEY,
                  transaction_id TEXT NOT NULL,
                  product_id TEXT NOT NULL,
                  product_name TEXT NOT NULL,
                  product_code TEXT NOT NULL,
                  buy_price REAL NOT NULL,
                  sell_price REAL NOT NULL,
                  quantity INTEGER NOT NULL,
                  discount REAL NOT NULL,
                  subtotal REAL NOT NULL
                )
              ''');

              await db.execute('''
                CREATE TABLE debts (
                  id TEXT PRIMARY KEY,
                  transaction_id TEXT NOT NULL,
                  customer_name TEXT NOT NULL,
                  customer_phone TEXT NOT NULL,
                  total_debt REAL NOT NULL,
                  paid_amount REAL NOT NULL,
                  created_at TEXT NOT NULL,
                  due_date TEXT,
                  status TEXT NOT NULL,
                  note TEXT
                )
              ''');

              await db.execute('''
                CREATE TABLE debt_payments (
                  id TEXT PRIMARY KEY,
                  debt_id TEXT NOT NULL,
                  amount_paid REAL NOT NULL,
                  payment_date TEXT NOT NULL,
                  note TEXT
                )
              ''');
            },
          ));

      DatabaseHelper.setMockDatabase(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Insert and Retrieve Product', () async {
      final product = Product(
        id: 'p1',
        code: 'BRG001',
        name: 'Kopi Susu',
        category: 'Minuman',
        buyPrice: 5000,
        sellPrice: 12000,
        stock: 50,
        unit: 'cangkir',
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.insertProduct(product);
      final products = await DatabaseHelper.instance.getAllProducts();

      expect(products.length, equals(1));
      expect(products.first.name, equals('Kopi Susu'));
      expect(products.first.sellPrice, equals(12000));
    });

    test('Update and Delete Product', () async {
      final product = Product(
        id: 'p1',
        code: 'BRG001',
        name: 'Kopi Susu',
        category: 'Minuman',
        buyPrice: 5000,
        sellPrice: 12000,
        stock: 50,
        unit: 'cangkir',
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.insertProduct(product);

      final updated = product.copyWith(name: 'Kopi Susu Gula Aren', stock: 45);
      await DatabaseHelper.instance.updateProduct(updated);

      final fetched = await DatabaseHelper.instance.getProductById('p1');
      expect(fetched?.name, equals('Kopi Susu Gula Aren'));
      expect(fetched?.stock, equals(45));

      await DatabaseHelper.instance.deleteProduct('p1');
      final listAfterDelete = await DatabaseHelper.instance.getAllProducts();
      expect(listAfterDelete.isEmpty, isTrue);
    });

    test('Insert Transaction and verify stock update', () async {
      final product = Product(
        id: 'p1',
        code: 'BRG001',
        name: 'Indomie Goreng',
        category: 'Makanan',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 20,
        unit: 'pcs',
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.insertProduct(product);

      final cartItem = CartItem(product: product, quantity: 5);
      final transaction = TransactionModel(
        id: 't1',
        invoiceNumber: 'INV-001',
        date: DateTime.now(),
        items: [cartItem],
        totalAmount: 17500,
        paidAmount: 20000,
        changeAmount: 2500,
        paymentMethod: 'Cash',
      );

      await DatabaseHelper.instance.insertTransaction(transaction);

      final txns = await DatabaseHelper.instance.getAllTransactions();
      expect(txns.length, equals(1));
      expect(txns.first.items.length, equals(1));
      expect(txns.first.items.first.product.name, equals('Indomie Goreng'));

      // Check stock reduced from 20 to 15
      final pUpdated = await DatabaseHelper.instance.getProductById('p1');
      expect(pUpdated?.stock, equals(15));
    });

    test('Debt Creation and Payment Tracking', () async {
      final debt = DebtModel(
        id: 'd1',
        transactionId: 't1',
        customerName: 'Budi',
        customerPhone: '08123456789',
        totalDebt: 50000,
        paidAmount: 0,
        createdAt: DateTime.now(),
        status: 'unpaid',
      );

      await DatabaseHelper.instance.insertDebt(debt);

      var debts = await DatabaseHelper.instance.getAllDebts();
      expect(debts.first.remainingDebt, equals(50000));
      expect(debts.first.status, equals('unpaid'));

      // Pay partial debt
      final payment = DebtPaymentHistory(
        id: 'pay1',
        debtId: 'd1',
        amountPaid: 20000,
        paymentDate: DateTime.now(),
      );
      await DatabaseHelper.instance.addDebtPayment(payment);

      debts = await DatabaseHelper.instance.getAllDebts();
      expect(debts.first.paidAmount, equals(20000));
      expect(debts.first.remainingDebt, equals(30000));
      expect(debts.first.status, equals('partially_paid'));

      // Pay rest of debt
      final payment2 = DebtPaymentHistory(
        id: 'pay2',
        debtId: 'd1',
        amountPaid: 30000,
        paymentDate: DateTime.now(),
      );
      await DatabaseHelper.instance.addDebtPayment(payment2);

      debts = await DatabaseHelper.instance.getAllDebts();
      expect(debts.first.paidAmount, equals(50000));
      expect(debts.first.remainingDebt, equals(0));
      expect(debts.first.status, equals('paid'));
    });
  });
}
