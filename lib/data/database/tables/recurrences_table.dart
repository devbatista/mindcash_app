import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/tables/accounts_table.dart';
import 'package:mindcash_app/data/database/tables/categories_table.dart';

class Recurrences extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  TextColumn get type => text().withLength(min: 1, max: 24)();

  IntColumn get amountCents => integer()();

  TextColumn get description => text().withLength(min: 1, max: 140)();

  IntColumn get dayOfMonth => integer()();

  DateTimeColumn get nextDueDate => dateTime()();

  IntColumn get accountId => integer().references(Accounts, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  TextColumn get note => text().withLength(min: 1, max: 240).nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get syncStatus => text()
      .withLength(min: 1, max: 24)
      .withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();
}
