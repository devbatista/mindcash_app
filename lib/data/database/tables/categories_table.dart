import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  TextColumn get type => text().withLength(min: 1, max: 24)();

  IntColumn get colorValue => integer().nullable()();

  TextColumn get iconName => text().withLength(min: 1, max: 48).nullable()();

  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get syncStatus => text()
      .withLength(min: 1, max: 24)
      .withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();
}
