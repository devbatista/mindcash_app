import 'package:drift/drift.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userName => text().withLength(min: 0, max: 80)();

  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('BRL'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
