import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kasir_app/main.dart';
import 'package:kasir_app/services/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('KasirApp smoke test', (WidgetTester tester) async {
    late Database db;
    await tester.runAsync(() async {
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

    await tester.pumpWidget(const KasirApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Kasir / Point of Sale'), findsOneWidget);

    await tester.runAsync(() async {
      await db.close();
    });
  });
}
