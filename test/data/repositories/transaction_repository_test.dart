import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase database;
  late AccountRepository accountRepository;
  late CategoryRepository categoryRepository;
  late TransactionRepository transactionRepository;

  setUp(() {
    database = AppDatabase.memory();
    accountRepository = AccountRepository(database);
    categoryRepository = CategoryRepository(database);
    transactionRepository = TransactionRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and lists active transactions', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    final category = await categoryRepository.createCategory(
      name: 'Mercado',
      type: 'expense',
    );

    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 8790,
      description: 'Compra do mês',
      date: DateTime(2026, 4, 29),
      sourceAccountId: account.id,
      categoryId: category.id,
    );

    final transactions = await transactionRepository.listActiveTransactions();

    expect(transactions, hasLength(1));
    expect(transactions.single.type, 'expense');
    expect(transactions.single.amountCents, 8790);
    expect(transactions.single.description, 'Compra do mês');
    expect(transactions.single.sourceAccountId, account.id);
    expect(transactions.single.categoryId, category.id);
  });

  test('deactivates transaction without hard delete', () async {
    final account = await accountRepository.createAccount(
      name: 'Conta corrente',
      type: 'checking',
    );
    final transaction = await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 500000,
      description: 'Salário',
      date: DateTime(2026, 4, 29),
      sourceAccountId: account.id,
    );

    await transactionRepository.deactivateTransaction(transaction.id);

    final activeTransactions = await transactionRepository
        .listActiveTransactions();
    final storedTransaction = await transactionRepository.getById(
      transaction.id,
    );

    expect(activeTransactions, isEmpty);
    expect(storedTransaction.deletedAt, isNotNull);
  });
}
