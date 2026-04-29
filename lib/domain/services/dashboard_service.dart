import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/domain/models/dashboard_summary.dart';

class DashboardService {
  const DashboardService(this._database);

  final AppDatabase _database;

  Future<DashboardSummary> getSummary({DateTime? month}) async {
    final selectedMonth = month ?? DateTime.now();
    final accountRepository = AccountRepository(_database);
    final transactionRepository = TransactionRepository(_database);

    final accounts = await accountRepository.listActiveAccounts();
    final transactions = await transactionRepository.listTransactions();
    final monthTransactions = await transactionRepository.listTransactions(
      startDate: DateTime(selectedMonth.year, selectedMonth.month),
      endDate: DateTime(selectedMonth.year, selectedMonth.month + 1),
    );
    final categories = await _database.select(_database.categories).get();

    final accountCards = <DashboardAccountSummary>[];
    for (final account in accounts) {
      accountCards.add(
        DashboardAccountSummary(
          name: account.name,
          type: account.type,
          balanceCents: await transactionRepository.calculateAccountBalance(
            account.id,
          ),
        ),
      );
    }

    final categoryExpenses = _buildCategoryExpenses(
      transactions: monthTransactions,
      categories: categories,
    );

    return DashboardSummary(
      userName: 'DevBatista',
      monthLabel: _formatMonth(selectedMonth),
      totalBalanceCents: await transactionRepository.calculateTotalBalance(),
      accountsBalanceCents: accountCards.fold<int>(
        0,
        (total, account) => total + account.balanceCents,
      ),
      cardsBalanceCents: 0,
      monthlyIncomeCents: await transactionRepository.calculateMonthlyIncome(
        selectedMonth,
      ),
      monthlyExpenseCents: -await transactionRepository.calculateMonthlyExpense(
        selectedMonth,
      ),
      monthlyResultCents: await transactionRepository.calculateMonthlyResult(
        selectedMonth,
      ),
      accountCards: accountCards,
      categoryExpenses: categoryExpenses,
      recentTransactions: transactions.take(5).map((transaction) {
        final category = categories
            .where((category) => category.id == transaction.categoryId)
            .firstOrNull;

        return DashboardTransactionSummary(
          description: transaction.description,
          categoryName: category?.name ?? 'Sem categoria',
          amountCents: transaction.amountCents,
          type: transaction.type,
        );
      }).toList(),
    );
  }

  List<DashboardCategorySummary> _buildCategoryExpenses({
    required List<Transaction> transactions,
    required List<Category> categories,
  }) {
    final totalsByCategoryId = <int?, int>{};

    for (final transaction in transactions) {
      if (transaction.type != 'expense') {
        continue;
      }

      totalsByCategoryId.update(
        transaction.categoryId,
        (value) => value + transaction.amountCents,
        ifAbsent: () => transaction.amountCents,
      );
    }

    final totalExpense = totalsByCategoryId.values.fold<int>(
      0,
      (total, amount) => total + amount,
    );

    if (totalExpense == 0) {
      return [];
    }

    final items = totalsByCategoryId.entries.map((entry) {
      final category = categories
          .where((category) => category.id == entry.key)
          .firstOrNull;

      return DashboardCategorySummary(
        name: category?.name ?? 'Sem categoria',
        percent: ((entry.value / totalExpense) * 100).round(),
        amountCents: entry.value,
        colorValue: category?.colorValue ?? 0xFF9CA3AF,
      );
    }).toList()..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    return items;
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[date.month - 1]}/${date.year}';
  }
}
