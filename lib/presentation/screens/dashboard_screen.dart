import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
      children: const [
        _GreetingHeader(),
        SizedBox(height: 28),
        Text(
          'Visao geral',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 14),
        _BalanceCard(),
        SizedBox(height: 26),
        _MonthSummary(),
        SizedBox(height: 30),
        _CategorySection(),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Ola, DevBatista',
      style: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saldo total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.visibility_outlined, color: Colors.white, size: 24),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'R\$ 25.430,80',
            style: TextStyle(
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _BalanceBreakdown(
                  label: 'Contas',
                  value: 'R\$ 18.230,50',
                ),
              ),
              Expanded(
                child: _BalanceBreakdown(
                  label: 'Cartoes',
                  value: '-R\$ 7.200,30',
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
  const _MonthSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Resumo do mes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Maio/2024',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
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
          child: const Column(
            children: [
              _SummaryRow(
                label: 'Receitas',
                value: 'R\$ 15.600,00',
                valueColor: Color(0xFF43A047),
              ),
              _Divider(),
              _SummaryRow(
                label: 'Despesas',
                value: '-R\$ 9.850,20',
                valueColor: Color(0xFFE05252),
              ),
              _Divider(),
              _SummaryRow(
                label: 'Resultado',
                value: 'R\$ 5.749,80',
                valueColor: Color(0xFF43A047),
              ),
            ],
          ),
        ),
      ],
    );
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
  const _CategorySection();

  static const _items = [
    _CategoryItem('Mercado', '32%', 'R\$ 3.150,00', Color(0xFF3563D8)),
    _CategoryItem('Alimentacao', '21%', 'R\$ 2.070,00', Color(0xFFF27A3D)),
    _CategoryItem('Transporte', '15%', 'R\$ 1.400,00', Color(0xFF54BF57)),
    _CategoryItem('Saude', '9%', 'R\$ 800,00', Color(0xFF5B45B8)),
    _CategoryItem('Outros', '23%', 'R\$ 2.230,20', Color(0xFF9CA3AF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Gastos por categoria',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Text(
              'Ver todas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6D3FD9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 154,
              height: 154,
              child: _CategoryDonut(items: _items),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  for (final item in _items) _CategoryLegendRow(item: item),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({required this.item});

  final _CategoryItem item;

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
              color: item.color,
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
              item.percent,
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
            item.amount,
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

  final List<_CategoryItem> items;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CategoryDonutPainter(items));
  }
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter(this.items);

  final List<_CategoryItem> items;

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
      paint.color = item.color;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryDonutPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}

class _CategoryItem {
  const _CategoryItem(this.name, this.percent, this.amount, this.color);

  final String name;
  final String percent;
  final String amount;
  final Color color;

  double get fraction {
    return int.parse(percent.replaceAll('%', '')) / 100;
  }
}
