import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mindcash_app/core/utils/money_formatter.dart';
import 'package:mindcash_app/domain/models/dashboard_summary.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';
import 'package:mindcash_app/presentation/widgets/transaction_list_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.summary,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onShowAllTransactions,
    super.key,
  });

  final DashboardSummary summary;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onShowAllTransactions;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
      children: [
        _GreetingHeader(userName: widget.summary.userName),
        const SizedBox(height: 28),
        const Text(
          'Visão geral',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        _BalanceCard(
          summary: widget.summary,
          isVisible: _isBalanceVisible,
          onVisibilityChanged: () {
            setState(() => _isBalanceVisible = !_isBalanceVisible);
          },
        ),
        const SizedBox(height: 26),
        _MonthSummary(
          summary: widget.summary,
          selectedMonth: widget.selectedMonth,
          onMonthChanged: widget.onMonthChanged,
          isBalanceVisible: _isBalanceVisible,
        ),
        const SizedBox(height: 30),
        _AccountsSection(
          accounts: widget.summary.accountCards,
          isBalanceVisible: _isBalanceVisible,
        ),
        const SizedBox(height: 30),
        _CategorySection(
          items: widget.summary.categoryExpenses,
          onShowAllTransactions: widget.onShowAllTransactions,
        ),
        const SizedBox(height: 30),
        _RecentTransactionsSection(
          transactions: widget.summary.recentTransactions,
          isBalanceVisible: _isBalanceVisible,
        ),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Olá, $userName',
      style: const TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.summary,
    required this.isVisible,
    required this.onVisibilityChanged,
  });

  final DashboardSummary summary;
  final bool isVisible;
  final VoidCallback onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF6D3FD9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336D3FD9),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saldo total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: onVisibilityChanged,
                tooltip: isVisible ? 'Ocultar valores' : 'Mostrar valores',
                color: Colors.white,
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatMoney(summary.totalBalanceCents, isVisible),
            style: const TextStyle(
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _BalanceBreakdown(
                  label: 'Contas',
                  value: _formatMoney(summary.accountsBalanceCents, isVisible),
                ),
              ),
              Expanded(
                child: _BalanceBreakdown(
                  label: 'Cartões',
                  value: _formatMoney(summary.cardsBalanceCents, isVisible),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceBreakdown extends StatelessWidget {
  const _BalanceBreakdown({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD8CBFF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.summary,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.isBalanceVisible,
  });

  final DashboardSummary summary;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final bool isBalanceVisible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Resumo do mês',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showMonthSelector(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.monthLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F111827),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Receitas',
                value: _formatMoney(
                  summary.monthlyIncomeCents,
                  isBalanceVisible,
                ),
                valueColor: const Color(0xFF43A047),
              ),
              const _Divider(),
              _SummaryRow(
                label: 'Despesas',
                value: _formatMoney(
                  summary.monthlyExpenseCents,
                  isBalanceVisible,
                ),
                valueColor: const Color(0xFFE05252),
              ),
              const _Divider(),
              _SummaryRow(
                label: 'Resultado',
                value: _formatMoney(
                  summary.monthlyResultCents,
                  isBalanceVisible,
                ),
                valueColor: const Color(0xFF43A047),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showMonthSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _MonthSelectorSheet(selectedMonth: selectedMonth);
      },
    );

    if (selected != null) {
      onMonthChanged(selected);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFE5E7EB));
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.items,
    required this.onShowAllTransactions,
  });

  final List<DashboardCategorySummary> items;
  final VoidCallback onShowAllTransactions;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _CompactEmptySection(
        title: 'Gastos por categoria',
        icon: Icons.donut_large,
        message: 'As despesas categorizadas aparecerão aqui.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Gastos por categoria',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            TextButton(
              onPressed: onShowAllTransactions,
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6D3FD9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: _CategoryDonut(items: items),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  for (final item in items) _CategoryLegendRow(item: item),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({
    required this.accounts,
    required this.isBalanceVisible,
  });

  final List<DashboardAccountSummary> accounts;
  final bool isBalanceVisible;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const _CompactEmptySection(
        title: 'Contas',
        icon: Icons.account_balance_wallet,
        message: 'Cadastre uma conta para acompanhar saldos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final account = accounts[index];

              return _AccountCard(
                account: account,
                isBalanceVisible: isBalanceVisible,
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemCount: accounts.length,
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.isBalanceVisible});

  final DashboardAccountSummary account;
  final bool isBalanceVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const Spacer(),
          Text(
            _formatMoney(account.balanceCents, isBalanceVisible),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6D3FD9),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.transactions,
    required this.isBalanceVisible,
  });

  final List<DashboardTransactionSummary> transactions;
  final bool isBalanceVisible;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _CompactEmptySection(
        title: 'Últimas transações',
        icon: Icons.receipt_long,
        message: 'As transações recentes aparecerão aqui.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas transações',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (final transaction in transactions)
                TransactionListItem(
                  description: transaction.description,
                  categoryName: transaction.categoryName,
                  amountCents: isBalanceVisible ? transaction.amountCents : 0,
                  type: transaction.type,
                  hiddenAmountLabel: isBalanceVisible ? null : '••••',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthSelectorSheet extends StatelessWidget {
  const _MonthSelectorSheet({required this.selectedMonth});

  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = DateTime(selectedMonth.year, index + 1);
          final isSelected = month.month == selectedMonth.month;

          return ListTile(
            title: Text(_monthLabel(month)),
            trailing: isSelected ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(month),
          );
        },
      ),
    );
  }

  String _monthLabel(DateTime date) {
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

String _formatMoney(int cents, bool isVisible) {
  if (!isVisible) {
    return '••••';
  }

  return MoneyFormatter.brl(cents);
}

class _CompactEmptySection extends StatelessWidget {
  const _CompactEmptySection({
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: EmptyState(
            icon: icon,
            title: 'Nada por enquanto',
            message: message,
          ),
        ),
      ],
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({required this.item});

  final DashboardCategorySummary item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: Color(item.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text(
              '${item.percent}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            MoneyFormatter.brl(item.amountCents),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({required this.items});

  final List<DashboardCategorySummary> items;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CategoryDonutPainter(items));
  }
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter(this.items);

  final List<DashboardCategorySummary> items;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;

    for (final item in items) {
      final sweep = item.fraction * math.pi * 2;
      paint.color = Color(item.colorValue);
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryDonutPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}
