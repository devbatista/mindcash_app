import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mindcash_app/data/database/tables/accounts_table.dart';
import 'package:mindcash_app/data/database/tables/categories_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories])
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'mindcash'));

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
