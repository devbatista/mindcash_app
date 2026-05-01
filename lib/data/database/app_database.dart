import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mindcash_app/data/database/tables/accounts_table.dart';
import 'package:mindcash_app/data/database/tables/app_settings_table.dart';
import 'package:mindcash_app/data/database/tables/categories_table.dart';
import 'package:mindcash_app/data/database/tables/credit_cards_table.dart';
import 'package:mindcash_app/data/database/tables/invoices_table.dart';
import 'package:mindcash_app/data/database/tables/installments_table.dart';
import 'package:mindcash_app/data/database/tables/recurrences_table.dart';
import 'package:mindcash_app/data/database/tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    CreditCards,
    Invoices,
    Installments,
    Recurrences,
    AppSettings,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'mindcash'));

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(appSettings);
        }
      },
    );
  }
}
