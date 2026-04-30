import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/tables/accounts_table.dart';
import 'package:mindcash_app/data/database/tables/categories_table.dart';
import 'package:mindcash_app/data/database/tables/credit_cards_table.dart';
import 'package:mindcash_app/data/database/tables/transactions_table.dart';

class Installments extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  TextColumn get purchaseUuid => text().withLength(min: 1, max: 80)();

  TextColumn get description => text().withLength(min: 1, max: 140)();

  IntColumn get totalCents => integer()();

  IntColumn get amountCents => integer()();

  IntColumn get installmentNumber => integer()();

  IntColumn get installmentCount => integer()();

  DateTimeColumn get purchaseDate => dateTime()();

  DateTimeColumn get dueDate => dateTime()();

  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  IntColumn get creditCardId =>
      integer().nullable().references(CreditCards, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  IntColumn get transactionId =>
      integer().nullable().references(Transactions, #id)();

  BoolColumn get isCanceled => boolean().withDefault(const Constant(false))();

  DateTimeColumn get canceledAt => dateTime().nullable()();

  TextColumn get syncStatus => text()
      .withLength(min: 1, max: 24)
      .withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();
}
