final class ReportSummary {
  const ReportSummary({
    required this.monthLabel,
    required this.incomeCents,
    required this.expenseCents,
    required this.resultCents,
    required this.previousIncomeCents,
    required this.previousExpenseCents,
    required this.previousResultCents,
    required this.categoryExpenses,
    required this.balanceEvolution,
  });

  final String monthLabel;
  final int incomeCents;
  final int expenseCents;
  final int resultCents;
  final int previousIncomeCents;
  final int previousExpenseCents;
  final int previousResultCents;
  final List<ReportCategoryExpense> categoryExpenses;
  final List<ReportBalancePoint> balanceEvolution;

  int get incomeDiffCents => incomeCents - previousIncomeCents;

  int get expenseDiffCents => expenseCents - previousExpenseCents;

  int get resultDiffCents => resultCents - previousResultCents;
}

final class ReportCategoryExpense {
  const ReportCategoryExpense({
    required this.name,
    required this.amountCents,
    required this.percent,
    required this.colorValue,
  });

  final String name;
  final int amountCents;
  final int percent;
  final int colorValue;
}

final class ReportBalancePoint {
  const ReportBalancePoint({required this.label, required this.resultCents});

  final String label;
  final int resultCents;
}
