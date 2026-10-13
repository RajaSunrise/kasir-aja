import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kasir_app/providers/debt_provider.dart';
import 'package:kasir_app/services/database_helper.dart';
import 'package:kasir_app/screens/debt/debt_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('DebtListScreen renders title and total summary', (WidgetTester tester) async {
    late Database db;
    await tester.runAsync(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DebtProvider()),
        ],
        child: const MaterialApp(
          home: DebtListScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Manajemen Hutang Pelanggan'), findsOneWidget);
    expect(find.text('Total Piutang / Hutang Belum Lunas'), findsOneWidget);

    await tester.runAsync(() async {
      await db.close();
    });
  });
}
