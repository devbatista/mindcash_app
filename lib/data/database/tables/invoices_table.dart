import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/tables/credit_cards_table.dart';

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  IntColumn get creditCardId => integer().references(CreditCards, #id)();

  DateTimeColumn get referenceMonth => dateTime()();

  DateTimeColumn get closingDate => dateTime()();

  DateTimeColumn get dueDate => dateTime()();

  IntColumn get totalCents => integer().withDefault(const Constant(0))();

  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();

  DateTimeColumn get paidAt => dateTime().nullable()();

  TextColumn get syncStatus => text()
      .withLength(min: 1, max: 24)
      .withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();
}
