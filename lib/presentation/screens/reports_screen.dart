import 'package:flutter/material.dart';
import 'package:mindcash_app/core/utils/money_formatter.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/domain/models/report_summary.dart';
import 'package:mindcash_app/domain/services/report_service.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime.now();
  int? _accountId;
  int? _categoryId;

  @override
  Widget build(BuildContext context) {
    final database = AppDependencies.databaseOf(context);

    return FutureBuilder<_ReportScreenData>(
      future: _loadData(database),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _ReportFilters(
              selectedMonth: _selectedMonth,
              accounts: data.accounts,
              categories: data.categories,
              accountId: _accountId,
              categoryId: _categoryId,
              onMonthChanged: (month) {
                setState(() => _selectedMonth = month);
              },
              onAccountChanged: (accountId) {
                setState(() => _accountId = accountId);
              },
              onCategoryChanged: (categoryId) {
                setState(() => _categoryId = categoryId);
              },
            ),
            const SizedBox(height: 16),
            _MonthlySummaryCard(summary: data.summary),
            const SizedBox(height: 16),
            _MonthComparisonCard(summary: data.summary),
            const SizedBox(height: 16),
            _CategoryExpensesSection(items: data.summary.categoryExpenses),
            const SizedBox(height: 16),
            _BalanceEvolutionSection(points: data.summary.balanceEvolution),
          ],
        );
      },
    );
  }

  Future<_ReportScreenData> _loadData(AppDatabase database) async {
    final accounts = await AccountRepository(database).listActiveAccounts();
    final categories = await CategoryRepository(
      database,
    ).listActiveCategories(type: 'expense');
    final summary = await ReportService(database).getSummary(
      month: _selectedMonth,
      accountId: _accountId,
      categoryId: _categoryId,
    );

    return _ReportScreenData(
      accounts: accounts,
      categories: categories,
      summary: summary,
    );
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.selectedMonth,
    required this.accounts,
    required this.categories,
    required this.accountId,
    required this.categoryId,
    required this.onMonthChanged,
    required this.onAccountChanged,
    required this.onCategoryChanged,
  });

  final DateTime selectedMonth;
  final List<Account> accounts;
  final List<Category> categories;
  final int? accountId;
  final int? categoryId;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<int?> onAccountChanged;
  final ValueChanged<int?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showMonthSelector(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Mês',
              border: OutlineInputBorder(),
            ),
            child: Row(
              children: [
                Expanded(child: Text(_formatMonth(selectedMonth))),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: accountId,
          decoration: const InputDecoration(
            labelText: 'Conta',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas as contas'),
            ),
            for (final account in accounts)
              DropdownMenuItem<int?>(
                value: account.id,
                child: Text(account.name),
              ),
          ],
          onChanged: onAccountChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: categoryId,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas as categorias'),
            ),
            for (final category in categories)
              DropdownMenuItem<int?>(
                value: category.id,
                child: Text(category.name),
              ),
          ],
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }

  Future<void> _showMonthSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final year = DateTime.now().year;
        final months = List<DateTime>.generate(
          12,
          (index) => DateTime(year, index + 1),
        );

        return ListView(
          shrinkWrap: true,
          children: [
            for (final month in months)
              ListTile(
                selected:
                    month.year == selectedMonth.year &&
                    month.month == selectedMonth.month,
                title: Text(_formatMonth(month)),
                onTap: () => Navigator.of(context).pop(month),
              ),
          ],
        );
      },
    );

    if (selected != null) {
      onMonthChanged(selected);
    }
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo mensal',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _ReportValueRow(
              label: 'Receitas',
              valueCents: summary.incomeCents,
              color: Colors.green,
            ),
            const Divider(),
            _ReportValueRow(
              label: 'Despesas',
              valueCents: summary.expenseCents,
              color: Colors.red,
            ),
            const Divider(),
            _ReportValueRow(
              label: 'Resultado',
              valueCents: summary.resultCents,
              color: summary.resultCents >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthComparisonCard extends StatelessWidget {
  const _MonthComparisonCard({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparativo entre meses',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _ComparisonRow(
              label: 'Receitas',
              diffCents: summary.incomeDiffCents,
            ),
            const Divider(),
            _ComparisonRow(
              label: 'Despesas',
              diffCents: summary.expenseDiffCents,
            ),
            const Divider(),
            _ComparisonRow(
              label: 'Resultado',
              diffCents: summary.resultDiffCents,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryExpensesSection extends StatelessWidget {
  const _CategoryExpensesSection({required this.items});

  final List<ReportCategoryExpense> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.pie_chart_outline,
        title: 'Sem gastos por categoria',
        message: 'As despesas do mês aparecerão aqui quando existirem.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por categoria',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final item in items) ...[
              _CategoryExpenseRow(item: item),
              if (item != items.last) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceEvolutionSection extends StatelessWidget {
  const _BalanceEvolutionSection({required this.points});

  final List<ReportBalancePoint> points;

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.fold<int>(
      1,
      (max, point) =>
          point.resultCents.abs() > max ? point.resultCents.abs() : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução do saldo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final point in points)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor:
                                      (point.resultCents.abs() / maxAmount)
                                          .clamp(0.08, 1),
                                  child: Container(
                                    width: 22,
                                    decoration: BoxDecoration(
                                      color: point.resultCents >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(point.label),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportValueRow extends StatelessWidget {
  const _ReportValueRow({
    required this.label,
    required this.valueCents,
    required this.color,
  });

  final String label;
  final int valueCents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          MoneyFormatter.brl(valueCents),
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.diffCents});

  final String label;
  final int diffCents;

  @override
  Widget build(BuildContext context) {
    final isPositive = diffCents >= 0;

    return Row(
      children: [
        Expanded(child: Text(label)),
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          MoneyFormatter.brl(diffCents),
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CategoryExpenseRow extends StatelessWidget {
  const _CategoryExpenseRow({required this.item});

  final ReportCategoryExpense item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(item.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
            Text('${item.percent}%'),
            const SizedBox(width: 12),
            Text(
              MoneyFormatter.brl(item.amountCents),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: item.percent / 100,
          color: Color(item.colorValue),
          backgroundColor: const Color(0xFFE5E7EB),
        ),
      ],
    );
  }
}

class _ReportScreenData {
  const _ReportScreenData({
    required this.accounts,
    required this.categories,
    required this.summary,
  });

  final List<Account> accounts;
  final List<Category> categories;
  final ReportSummary summary;
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
