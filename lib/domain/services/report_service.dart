import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/domain/models/report_summary.dart';

class ReportService {
  const ReportService(this._database);

  final AppDatabase _database;

  Future<ReportSummary> getSummary({
    DateTime? month,
    int? accountId,
    int? categoryId,
  }) async {
    final selectedMonth = month ?? DateTime.now();
    final currentTransactions = await _listFilteredMonthTransactions(
      selectedMonth,
      accountId: accountId,
      categoryId: categoryId,
    );
    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final previousTransactions = await _listFilteredMonthTransactions(
      previousMonth,
      accountId: accountId,
      categoryId: categoryId,
    );
    final categories = await _database.select(_database.categories).get();
    final evolution = <ReportBalancePoint>[];

    for (var offset = 5; offset >= 0; offset--) {
      final evolutionMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - offset,
      );
      final transactions = await _listFilteredMonthTransactions(
        evolutionMonth,
        accountId: accountId,
        categoryId: categoryId,
      );
      evolution.add(
        ReportBalancePoint(
          label: _formatShortMonth(evolutionMonth),
          resultCents: _resultCents(transactions),
        ),
      );
    }

    return ReportSummary(
      monthLabel: _formatMonth(selectedMonth),
      incomeCents: _incomeCents(currentTransactions),
      expenseCents: _expenseCents(currentTransactions),
      resultCents: _resultCents(currentTransactions),
      previousIncomeCents: _incomeCents(previousTransactions),
      previousExpenseCents: _expenseCents(previousTransactions),
      previousResultCents: _resultCents(previousTransactions),
      categoryExpenses: _buildCategoryExpenses(
        transactions: currentTransactions,
        categories: categories,
      ),
      balanceEvolution: evolution,
    );
  }

  Future<List<Transaction>> _listFilteredMonthTransactions(
    DateTime month, {
    int? accountId,
    int? categoryId,
  }) async {
    final transactions = await TransactionRepository(_database)
        .listTransactions(
          startDate: DateTime(month.year, month.month),
          endDate: DateTime(month.year, month.month + 1),
        );

    return transactions.where((transaction) {
      final matchesAccount =
          accountId == null ||
          transaction.sourceAccountId == accountId ||
          transaction.destinationAccountId == accountId;
      final matchesCategory =
          categoryId == null || transaction.categoryId == categoryId;

      return matchesAccount && matchesCategory;
    }).toList();
  }

  List<ReportCategoryExpense> _buildCategoryExpenses({
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

      return ReportCategoryExpense(
        name: category?.name ?? 'Sem categoria',
        amountCents: entry.value,
        percent: ((entry.value / totalExpense) * 100).round(),
        colorValue: category?.colorValue ?? 0xFF9CA3AF,
      );
    }).toList()..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    return items;
  }

  int _incomeCents(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.type == 'income')
        .fold<int>(0, (total, transaction) => total + transaction.amountCents);
  }

  int _expenseCents(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.type == 'expense')
        .fold<int>(0, (total, transaction) => total + transaction.amountCents);
  }

  int _resultCents(List<Transaction> transactions) {
    return _incomeCents(transactions) - _expenseCents(transactions);
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

  String _formatShortMonth(DateTime date) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return months[date.month - 1];
  }
}
