import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';

void main() {
  late AppDatabase database;
  late AccountRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = AccountRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and lists active accounts', () async {
    await repository.createAccount(
      name: 'Carteira',
      type: 'wallet',
      initialBalanceCents: 25000,
    );

    final accounts = await repository.listActiveAccounts();

    expect(accounts, hasLength(1));
    expect(accounts.single.name, 'Carteira');
    expect(accounts.single.type, 'wallet');
    expect(accounts.single.initialBalanceCents, 25000);
    expect(accounts.single.isActive, isTrue);
  });

  test('deactivates account without hard delete', () async {
    final account = await repository.createAccount(
      name: 'Conta corrente',
      type: 'checking',
    );

    await repository.deactivateAccount(account.id);

    final activeAccounts = await repository.listActiveAccounts();
    final storedAccount = await repository.getById(account.id);

    expect(activeAccounts, isEmpty);
    expect(storedAccount.isActive, isFalse);
    expect(storedAccount.deletedAt, isNotNull);
  });
}
