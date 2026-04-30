import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/recurrence_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase database;
  late RecurrenceRepository repository;
  late AccountRepository accountRepository;
  late CategoryRepository categoryRepository;

  setUp(() {
    database = AppDatabase.memory();
    repository = RecurrenceRepository(database);
    accountRepository = AccountRepository(database);
    categoryRepository = CategoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and lists monthly recurrence', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    final category = await categoryRepository.createCategory(
      name: 'Assinaturas',
      type: 'expense',
    );

    await repository.createMonthlyRecurrence(
      type: 'expense',
      amountCents: 3990,
      description: 'Streaming',
      dayOfMonth: 15,
      nextDueDate: DateTime(2024, 5, 1),
      accountId: account.id,
      categoryId: category.id,
    );

    final recurrences = await repository.listActiveRecurrences();

    expect(recurrences, hasLength(1));
    expect(recurrences.single.description, 'Streaming');
    expect(recurrences.single.nextDueDate, DateTime(2024, 5, 15));
  });

  test('executes pending recurrences and advances next due date', () async {
    final account = await accountRepository.createAccount(
      name: 'Conta',
      type: 'checking',
    );
    final category = await categoryRepository.createCategory(
      name: 'Salário',
      type: 'income',
    );
    final recurrence = await repository.createMonthlyRecurrence(
      type: 'income',
      amountCents: 500000,
      description: 'Salário',
      dayOfMonth: 5,
      nextDueDate: DateTime(2024, 5, 5),
      accountId: account.id,
      categoryId: category.id,
    );

    final generated = await repository.executePendingRecurrences(
      today: DateTime(2024, 5, 5),
    );
    final updated = await repository.getById(recurrence.id);

    expect(generated, hasLength(1));
    expect(generated.single.description, 'Salário');
    expect(updated.nextDueDate, DateTime(2024, 6, 5));
  });

  test('does not duplicate recurrence executions', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    await repository.createMonthlyRecurrence(
      type: 'expense',
      amountCents: 1200,
      description: 'Seguro',
      dayOfMonth: 10,
      nextDueDate: DateTime(2024, 5, 10),
      accountId: account.id,
    );

    await repository.executePendingRecurrences(today: DateTime(2024, 5, 10));
    await repository.executePendingRecurrences(today: DateTime(2024, 5, 10));

    final transactions = await TransactionRepository(
      database,
    ).listActiveTransactions();

    expect(transactions, hasLength(1));
  });

  test('catches up pending monthly recurrences', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    await repository.createMonthlyRecurrence(
      type: 'expense',
      amountCents: 1000,
      description: 'Academia',
      dayOfMonth: 31,
      nextDueDate: DateTime(2024, 1, 31),
      accountId: account.id,
    );

    final generated = await repository.executePendingRecurrences(
      today: DateTime(2024, 3, 31),
    );

    expect(generated, hasLength(3));
    expect(generated[1].date, DateTime(2024, 2, 29));
    expect(generated[2].date, DateTime(2024, 3, 31));
  });

  test('updates and deactivates recurrence', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    final recurrence = await repository.createMonthlyRecurrence(
      type: 'expense',
      amountCents: 2000,
      description: 'Internet',
      dayOfMonth: 12,
      nextDueDate: DateTime(2024, 5, 12),
      accountId: account.id,
    );

    await repository.updateRecurrence(
      recurrence.copyWith(
        amountCents: 2500,
        description: 'Internet residencial',
      ),
    );
    await repository.deactivateRecurrence(recurrence.id);

    final active = await repository.listActiveRecurrences();
    final stored = await repository.getById(recurrence.id);

    expect(active, isEmpty);
    expect(stored.description, 'Internet residencial');
    expect(stored.amountCents, 2500);
    expect(stored.isActive, isFalse);
  });
}
