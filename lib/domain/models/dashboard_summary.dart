final class DashboardSummary {
  const DashboardSummary({
    required this.userName,
    required this.monthLabel,
    required this.totalBalanceCents,
    required this.accountsBalanceCents,
    required this.cardsBalanceCents,
    required this.monthlyIncomeCents,
    required this.monthlyExpenseCents,
    required this.monthlyResultCents,
    required this.accountCards,
    required this.categoryExpenses,
    required this.recentTransactions,
  });

  final String userName;
  final String monthLabel;
  final int totalBalanceCents;
  final int accountsBalanceCents;
  final int cardsBalanceCents;
  final int monthlyIncomeCents;
  final int monthlyExpenseCents;
  final int monthlyResultCents;
  final List<DashboardAccountSummary> accountCards;
  final List<DashboardCategorySummary> categoryExpenses;
  final List<DashboardTransactionSummary> recentTransactions;

  bool get hasData {
    return accountCards.isNotEmpty || recentTransactions.isNotEmpty;
  }
}

final class DashboardAccountSummary {
  const DashboardAccountSummary({
    required this.name,
    required this.type,
    required this.balanceCents,
  });

  final String name;
  final String type;
  final int balanceCents;
}

final class DashboardCategorySummary {
  const DashboardCategorySummary({
    required this.name,
    required this.percent,
    required this.amountCents,
    required this.colorValue,
  });

  final String name;
  final int percent;
  final int amountCents;
  final int colorValue;

  double get fraction => percent / 100;
}

final class DashboardTransactionSummary {
  const DashboardTransactionSummary({
    required this.description,
    required this.categoryName,
    required this.amountCents,
    required this.type,
  });

  final String description;
  final String categoryName;
  final int amountCents;
  final String type;
}
