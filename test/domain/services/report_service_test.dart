import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/domain/services/report_service.dart';

void main() {
  late AppDatabase database;
  late AccountRepository accountRepository;
  late CategoryRepository categoryRepository;
  late TransactionRepository transactionRepository;
  late ReportService service;

  setUp(() {
    database = AppDatabase.memory();
    accountRepository = AccountRepository(database);
    categoryRepository = CategoryRepository(database);
    transactionRepository = TransactionRepository(database);
    service = ReportService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('calculates monthly summary and category expenses', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    final market = await categoryRepository.createCategory(
      name: 'Mercado',
      type: 'expense',
      colorValue: 0xFF3366FF,
    );
    final food = await categoryRepository.createCategory(
      name: 'Alimentação',
      type: 'expense',
      colorValue: 0xFFFF6633,
    );

    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 500000,
      description: 'Salário',
      date: DateTime(2024, 5, 5),
      sourceAccountId: account.id,
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 100000,
      description: 'Compra',
      date: DateTime(2024, 5, 10),
      sourceAccountId: account.id,
      categoryId: market.id,
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 50000,
      description: 'Restaurante',
      date: DateTime(2024, 5, 12),
      sourceAccountId: account.id,
      categoryId: food.id,
    );

    final summary = await service.getSummary(month: DateTime(2024, 5));

    expect(summary.incomeCents, 500000);
    expect(summary.expenseCents, 150000);
    expect(summary.resultCents, 350000);
    expect(summary.categoryExpenses, hasLength(2));
    expect(summary.categoryExpenses.first.name, 'Mercado');
    expect(summary.categoryExpenses.first.percent, 67);
  });

  test('filters report by account and category', () async {
    final wallet = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    final bank = await accountRepository.createAccount(
      name: 'Banco',
      type: 'checking',
    );
    final market = await categoryRepository.createCategory(
      name: 'Mercado',
      type: 'expense',
    );
    final transport = await categoryRepository.createCategory(
      name: 'Transporte',
      type: 'expense',
    );

    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 10000,
      description: 'Compra',
      date: DateTime(2024, 5, 10),
      sourceAccountId: wallet.id,
      categoryId: market.id,
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 20000,
      description: 'Ônibus',
      date: DateTime(2024, 5, 11),
      sourceAccountId: bank.id,
      categoryId: transport.id,
    );

    final summary = await service.getSummary(
      month: DateTime(2024, 5),
      accountId: wallet.id,
      categoryId: market.id,
    );

    expect(summary.expenseCents, 10000);
    expect(summary.categoryExpenses.single.name, 'Mercado');
  });

  test('compares current month with previous month', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );

    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 300000,
      description: 'Abril',
      date: DateTime(2024, 4, 5),
      sourceAccountId: account.id,
    );
    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 500000,
      description: 'Maio',
      date: DateTime(2024, 5, 5),
      sourceAccountId: account.id,
    );

    final summary = await service.getSummary(month: DateTime(2024, 5));

    expect(summary.previousIncomeCents, 300000);
    expect(summary.incomeDiffCents, 200000);
    expect(summary.balanceEvolution, hasLength(6));
  });
}
