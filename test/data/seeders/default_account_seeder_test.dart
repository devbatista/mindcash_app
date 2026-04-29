import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/seeders/default_account_seeder.dart';

void main() {
  late AppDatabase database;
  late AccountRepository accountRepository;
  late DefaultAccountSeeder seeder;

  setUp(() {
    database = AppDatabase.memory();
    accountRepository = AccountRepository(database);
    seeder = DefaultAccountSeeder(accountRepository);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates default wallet account', () async {
    await seeder.seed();

    final accounts = await accountRepository.listActiveAccounts();

    expect(accounts, hasLength(1));
    expect(accounts.single.name, 'Carteira');
    expect(accounts.single.type, 'wallet');
    expect(accounts.single.initialBalanceCents, 0);
  });

  test('does not duplicate account when seeded twice', () async {
    await seeder.seed();
    await seeder.seed();

    final accounts = await accountRepository.listActiveAccounts();

    expect(accounts, hasLength(1));
  });
}
