import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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

  AppDatabase.defaults() : super(_openPersistentDatabase());

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(appSettings);
        }
        if (from < 3) {
          await m.addColumn(appSettings, appSettings.hasCompletedOnboarding);
        }
      },
    );
  }
}

QueryExecutor _openPersistentDatabase() {
  final baseDirectory = _persistentDatabaseDirectory();

  if (!baseDirectory.existsSync()) {
    baseDirectory.createSync(recursive: true);
  }

  return NativeDatabase.createInBackground(
    File('${baseDirectory.path}/mindcash.sqlite'),
  );
}

Directory _persistentDatabaseDirectory() {
  final environment = Platform.environment;
  final home = environment['HOME'] ?? environment['CFFIXED_USER_HOME'];

  if (home != null && home.isNotEmpty) {
    return Directory('$home/Library/Application Support/MindCash');
  }

  final temporaryDirectory = environment['TMPDIR'];
  if (temporaryDirectory != null && temporaryDirectory.isNotEmpty) {
    final sandboxRoot = Directory(temporaryDirectory).parent;

    return Directory(
      '${sandboxRoot.path}/Library/Application Support/MindCash',
    );
  }

  return Directory('${Directory.systemTemp.path}/MindCash');
}
