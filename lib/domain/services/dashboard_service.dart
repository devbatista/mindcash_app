import 'package:mindcash_app/domain/models/dashboard_summary.dart';

class DashboardService {
  const DashboardService();

  Future<DashboardSummary> getSummary() async {
    return const DashboardSummary(
      userName: 'DevBatista',
      monthLabel: 'Maio/2024',
      totalBalanceCents: 2543080,
      accountsBalanceCents: 1823050,
      cardsBalanceCents: -720030,
      monthlyIncomeCents: 1560000,
      monthlyExpenseCents: -985020,
      monthlyResultCents: 574980,
      categoryExpenses: [
        DashboardCategorySummary(
          name: 'Mercado',
          percent: 32,
          amountCents: 315000,
          colorValue: 0xFF3563D8,
        ),
        DashboardCategorySummary(
          name: 'Alimentação',
          percent: 21,
          amountCents: 207000,
          colorValue: 0xFFF27A3D,
        ),
        DashboardCategorySummary(
          name: 'Transporte',
          percent: 15,
          amountCents: 140000,
          colorValue: 0xFF54BF57,
        ),
        DashboardCategorySummary(
          name: 'Saúde',
          percent: 9,
          amountCents: 80000,
          colorValue: 0xFF5B45B8,
        ),
        DashboardCategorySummary(
          name: 'Outros',
          percent: 23,
          amountCents: 223020,
          colorValue: 0xFF9CA3AF,
        ),
      ],
    );
  }
}
