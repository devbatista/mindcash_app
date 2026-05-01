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

  test('filters transactions by date, type and description', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );

    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 1200,
      description: 'Café',
      date: DateTime(2026, 4, 29, 9),
      sourceAccountId: account.id,
    );
    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 10000,
      description: 'Freelance',
      date: DateTime(2026, 4, 30, 14),
      sourceAccountId: account.id,
    );

    final byDate = await transactionRepository.listTransactionsByDate(
      DateTime(2026, 4, 29),
    );
    final byType = await transactionRepository.listTransactions(type: 'income');
    final byDescription = await transactionRepository.listTransactions(
      search: 'café',
    );

    expect(byDate.map((transaction) => transaction.description), ['Café']);
    expect(byType.map((transaction) => transaction.description), ['Freelance']);
    expect(byDescription.map((transaction) => transaction.description), [
      'Café',
    ]);
  });

  test('calculates account balance and total balance', () async {
    final wallet = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
      initialBalanceCents: 5000,
    );
    final checking = await accountRepository.createAccount(
      name: 'Conta corrente',
      type: 'checking',
      initialBalanceCents: 10000,
    );

    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 20000,
      description: 'Salário',
      date: DateTime(2026, 4, 1),
      sourceAccountId: checking.id,
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 3500,
      description: 'Mercado',
      date: DateTime(2026, 4, 2),
      sourceAccountId: checking.id,
    );
    await transactionRepository.createTransfer(
      amountCents: 2500,
      description: 'Saque',
      date: DateTime(2026, 4, 3),
      sourceAccountId: checking.id,
      destinationAccountId: wallet.id,
    );

    final walletBalance = await transactionRepository.calculateAccountBalance(
      wallet.id,
    );
    final checkingBalance = await transactionRepository.calculateAccountBalance(
      checking.id,
    );
    final totalBalance = await transactionRepository.calculateTotalBalance();

    expect(walletBalance, 7500);
    expect(checkingBalance, 24000);
    expect(totalBalance, 31500);
  });

  test('calculates monthly income, expense and result', () async {
    final account = await accountRepository.createAccount(
      name: 'Conta corrente',
      type: 'checking',
    );

    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 100000,
      description: 'Salário',
      date: DateTime(2026, 4, 5),
      sourceAccountId: account.id,
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 25000,
      description: 'Aluguel',
      date: DateTime(2026, 4, 6),
      sourceAccountId: account.id,
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 10000,
      description: 'Mercado',
      date: DateTime(2026, 5, 1),
      sourceAccountId: account.id,
    );

    final income = await transactionRepository.calculateMonthlyIncome(
      DateTime(2026, 4),
    );
    final expense = await transactionRepository.calculateMonthlyExpense(
      DateTime(2026, 4),
    );
    final result = await transactionRepository.calculateMonthlyResult(
      DateTime(2026, 4),
    );

    expect(income, 100000);
    expect(expense, 25000);
    expect(result, 75000);
  });

  test('creates transfer between accounts and updates both balances', () async {
    final checking = await accountRepository.createAccount(
      name: 'Conta corrente',
      type: 'checking',
      initialBalanceCents: 100000,
    );
    final wallet = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
      initialBalanceCents: 10000,
    );

    final transfer = await transactionRepository.createTransfer(
      amountCents: 25000,
      description: 'Saque',
      date: DateTime(2026, 4, 20),
      sourceAccountId: checking.id,
      destinationAccountId: wallet.id,
    );

    final checkingBalance = await transactionRepository.calculateAccountBalance(
      checking.id,
    );
    final walletBalance = await transactionRepository.calculateAccountBalance(
      wallet.id,
    );
    final totalBalance = await transactionRepository.calculateTotalBalance();

    expect(transfer.type, 'transfer');
    expect(transfer.sourceAccountId, checking.id);
    expect(transfer.destinationAccountId, wallet.id);
    expect(checkingBalance, 75000);
    expect(walletBalance, 35000);
    expect(totalBalance, 110000);
  });

  test('requires destination account for transfers', () async {
    final account = await accountRepository.createAccount(
      name: 'Conta corrente',
      type: 'checking',
    );

    expect(
      () => transactionRepository.createTransaction(
        type: 'transfer',
        amountCents: 1000,
        description: 'Transferência',
        date: DateTime(2026, 4, 29),
        sourceAccountId: account.id,
      ),
      throwsArgumentError,
    );
  });
}
