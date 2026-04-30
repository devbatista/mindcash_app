import 'package:drift/drift.dart';

class CreditCards extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  IntColumn get limitCents => integer().withDefault(const Constant(0))();

  IntColumn get closingDay => integer()();

  IntColumn get dueDay => integer()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get syncStatus => text()
      .withLength(min: 1, max: 24)
      .withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();
}
