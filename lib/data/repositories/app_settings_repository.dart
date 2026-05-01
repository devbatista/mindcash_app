import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';

class AppSettingsRepository {
  const AppSettingsRepository(this._database);

  final AppDatabase _database;

  Future<AppSetting> getSettings() async {
    final existing = await (_database.select(
      _database.appSettings,
    )..limit(1)).getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final id = await _database
        .into(_database.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            userName: '',
            currencyCode: const Value('BRL'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return (_database.select(
      _database.appSettings,
    )..where((row) => row.id.equals(id))).getSingle();
  }

  Future<void> updateSettings({
    required String userName,
    required String currencyCode,
  }) async {
    final settings = await getSettings();

    await (_database.update(
      _database.appSettings,
    )..where((row) => row.id.equals(settings.id))).write(
      AppSettingsCompanion(
        userName: Value(userName.trim()),
        currencyCode: Value(currencyCode),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
