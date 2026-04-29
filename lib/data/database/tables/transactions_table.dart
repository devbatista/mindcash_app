import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/tables/accounts_table.dart';
import 'package:mindcash_app/data/database/tables/categories_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  TextColumn get type => text().withLength(min: 1, max: 24)();

  IntColumn get amountCents => integer()();

  TextColumn get description => text().withLength(min: 1, max: 140)();

  DateTimeColumn get date => dateTime()();

  @ReferenceName('sourceTransactions')
  IntColumn get sourceAccountId => integer().references(Accounts, #id)();

  @ReferenceName('destinationTransactions')
  IntColumn get destinationAccountId =>
      integer().nullable().references(Accounts, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  TextColumn get note => text().withLength(min: 1, max: 240).nullable()();

  TextColumn get syncStatus => text()
      .withLength(min: 1, max: 24)
      .withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();
}
