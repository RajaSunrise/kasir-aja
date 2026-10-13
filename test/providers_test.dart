import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kasir_app/models/product.dart';
import 'package:kasir_app/providers/product_provider.dart';
import 'package:kasir_app/providers/cart_provider.dart';
import 'package:kasir_app/providers/debt_provider.dart';
import 'package:kasir_app/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Providers Tests', () {
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

    test('CartProvider state operations and calculations', () {
      final cart = CartProvider();
      final p1 = Product(
        id: 'p1',
        code: '001',
        name: 'Minyak Goreng',
        category: 'Sembako',
        buyPrice: 10000,
        sellPrice: 15000,
        stock: 10,
        unit: 'liter',
        createdAt: DateTime.now().toIso8601String(),
      );

      cart.addToCart(p1);
      expect(cart.itemCount, equals(1));
      expect(cart.totalAmount, equals(15000));
      expect(cart.totalProfit, equals(5000));

      cart.updateQuantity('p1', 3);
      expect(cart.itemCount, equals(3));
      expect(cart.totalAmount, equals(45000));
      expect(cart.totalProfit, equals(15000));

      cart.setDiscount('p1', 3000);
      expect(cart.totalAmount, equals(42000));

      cart.clearCart();
      expect(cart.itemCount, equals(0));
    });

    test('ProductProvider search and filtering', () async {
      final productProvider = ProductProvider();
      final p1 = Product(
        id: 'p1',
        code: '001',
        name: 'Teh Botol',
        category: 'Minuman',
        buyPrice: 2000,
        sellPrice: 4000,
        stock: 20,
        unit: 'botol',
        createdAt: DateTime.now().toIso8601String(),
      );
      final p2 = Product(
        id: 'p2',
        code: '002',
        name: 'Roti Tawar',
        category: 'Makanan',
        buyPrice: 8000,
        sellPrice: 12000,
        stock: 15,
        unit: 'bungkus',
        createdAt: DateTime.now().toIso8601String(),
      );

      await productProvider.addProduct(p1);
      await productProvider.addProduct(p2);

      expect(productProvider.allProducts.length, equals(2));

      productProvider.setSearchQuery('Teh');
      expect(productProvider.products.length, equals(1));
      expect(productProvider.products.first.name, equals('Teh Botol'));

      productProvider.setSearchQuery('');
      productProvider.setSelectedCategory('Makanan');
      expect(productProvider.products.length, equals(1));
      expect(productProvider.products.first.name, equals('Roti Tawar'));
    });
  });
}
