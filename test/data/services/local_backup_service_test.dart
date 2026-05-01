import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/app_settings_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/credit_card_repository.dart';
import 'package:mindcash_app/data/repositories/recurrence_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/data/services/local_backup_service.dart';

void main() {
  late AppDatabase database;
  late LocalBackupService service;

  setUp(() {
    database = AppDatabase.memory();
    service = LocalBackupService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('exports valid JSON backup with local data', () async {
    final account = await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    final category = await CategoryRepository(
      database,
    ).createCategory(name: 'Mercado', type: 'expense');
    await TransactionRepository(database).createTransaction(
      type: 'expense',
      amountCents: 1250,
      description: 'Compra',
      date: DateTime(2024, 5, 10),
      sourceAccountId: account.id,
      categoryId: category.id,
    );
    await CreditCardRepository(database).createCreditCard(
      name: 'Nubank',
      limitCents: 500000,
      closingDay: 10,
      dueDay: 17,
    );

    final backup = await service.exportJson();
    final decoded = jsonDecode(backup) as Map<String, Object?>;
    final data = decoded['data']! as Map<String, Object?>;

    expect(service.validateJson(backup).isValid, isTrue);
    expect(data['accounts'], hasLength(1));
    expect(data['categories'], hasLength(1));
    expect(data['transactions'], hasLength(1));
    expect(data['creditCards'], hasLength(1));
  });

  test('exports and imports app settings', () async {
    await AppSettingsRepository(
      database,
    ).completeOnboarding(userName: 'Rafael', currencyCode: 'BRL');
    final backup = await service.exportJson();

    await service.resetAllData();
    await service.importJson(backup);

    final settings = await AppSettingsRepository(database).getSettings();

    expect(settings.userName, 'Rafael');
    expect(settings.currencyCode, 'BRL');
    expect(settings.hasCompletedOnboarding, isTrue);
  });

  test('imports JSON backup and creates safety backup first', () async {
    final account = await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    await RecurrenceRepository(database).createMonthlyRecurrence(
      type: 'expense',
      amountCents: 3990,
      description: 'Streaming',
      dayOfMonth: 15,
      nextDueDate: DateTime(2024, 5, 15),
      accountId: account.id,
    );
    final backup = await service.exportJson();

    await AccountRepository(
      database,
    ).createAccount(name: 'Banco', type: 'checking');

    final result = await service.importJson(backup);
    final accounts = await AccountRepository(database).listActiveAccounts();
    final recurrences = await RecurrenceRepository(
      database,
    ).listActiveRecurrences();

    expect(result.safetyBackupJson, contains('Banco'));
    expect(accounts, hasLength(1));
    expect(accounts.single.name, 'Carteira');
    expect(recurrences.single.description, 'Streaming');
  });

  test('rejects invalid JSON backup', () {
    final result = service.validateJson('{"data":{}}');

    expect(result.isValid, isFalse);
    expect(result.message, isNotEmpty);
  });

  test('exports transactions CSV', () async {
    final account = await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    final category = await CategoryRepository(
      database,
    ).createCategory(name: 'Mercado', type: 'expense');
    await TransactionRepository(database).createTransaction(
      type: 'expense',
      amountCents: 1250,
      description: 'Compra',
      date: DateTime(2024, 5, 10),
      sourceAccountId: account.id,
      categoryId: category.id,
      note: 'Sem cupom',
    );

    final csv = await service.exportCsv();

    expect(csv, contains('"descricao"'));
    expect(csv, contains('"Compra"'));
    expect(csv, contains('"Carteira"'));
    expect(csv, contains('"Mercado"'));
  });
}
