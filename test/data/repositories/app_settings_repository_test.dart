import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/app_settings_repository.dart';

void main() {
  late AppDatabase database;
  late AppSettingsRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = AppSettingsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates default settings when none exist', () async {
    final settings = await repository.getSettings();

    expect(settings.userName, isEmpty);
    expect(settings.currencyCode, 'BRL');
  });

  test('updates user name and currency', () async {
    await repository.updateSettings(userName: 'Rafael', currencyCode: 'BRL');

    final settings = await repository.getSettings();

    expect(settings.userName, 'Rafael');
    expect(settings.currencyCode, 'BRL');
  });
}
