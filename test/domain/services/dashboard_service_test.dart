import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/domain/services/dashboard_service.dart';

void main() {
  late AppDatabase database;
  late AccountRepository accountRepository;
  late CategoryRepository categoryRepository;
  late TransactionRepository transactionRepository;
  late DashboardService dashboardService;

  setUp(() {
    database = AppDatabase.memory();
    accountRepository = AccountRepository(database);
    categoryRepository = CategoryRepository(database);
    transactionRepository = TransactionRepository(database);
    dashboardService = DashboardService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('builds dashboard summary from local data', () async {
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
      initialBalanceCents: 10000,
    );
    final category = await categoryRepository.createCategory(
      name: 'Mercado',
      type: 'expense',
      colorValue: 0xFF3563D8,
    );

    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 50000,
      description: 'Salário',
      date: DateTime(2026, 4, 5),
      sourceAccountId: account.id,
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 12000,
      description: 'Compra do mês',
      date: DateTime(2026, 4, 6),
      sourceAccountId: account.id,
      categoryId: category.id,
    );

    final summary = await dashboardService.getSummary(month: DateTime(2026, 4));

    expect(summary.totalBalanceCents, 48000);
    expect(summary.accountCards.single.name, 'Carteira');
    expect(summary.accountCards.single.balanceCents, 48000);
    expect(summary.monthlyIncomeCents, 50000);
    expect(summary.monthlyExpenseCents, -12000);
    expect(summary.monthlyResultCents, 38000);
    expect(summary.categoryExpenses.single.name, 'Mercado');
    expect(summary.recentTransactions.first.description, 'Compra do mês');
  });
}
