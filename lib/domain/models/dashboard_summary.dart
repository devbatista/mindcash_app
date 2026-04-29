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
    required this.categoryExpenses,
  });

  final String userName;
  final String monthLabel;
  final int totalBalanceCents;
  final int accountsBalanceCents;
  final int cardsBalanceCents;
  final int monthlyIncomeCents;
  final int monthlyExpenseCents;
  final int monthlyResultCents;
  final List<DashboardCategorySummary> categoryExpenses;
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
