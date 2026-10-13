import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kasir_app/providers/product_provider.dart';
import 'package:kasir_app/services/database_helper.dart';
import 'package:kasir_app/screens/products/product_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('ProductListScreen renders search and empty state', (WidgetTester tester) async {
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
            },
          ));
      DatabaseHelper.setMockDatabase(db);
    });

    final productProvider = ProductProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
        ],
        child: const MaterialApp(
          home: ProductListScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Manajemen Produk & Stok'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tambah Produk'), findsOneWidget);

    await tester.runAsync(() async {
      await db.close();
    });
  });
}
