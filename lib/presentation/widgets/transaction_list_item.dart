import 'package:flutter/material.dart';
import 'package:mindcash_app/core/theme/app_colors.dart';
import 'package:mindcash_app/core/utils/money_formatter.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    required this.description,
    required this.categoryName,
    required this.amountCents,
    required this.type,
    super.key,
  });

  final String description;
  final String categoryName;
  final int amountCents;
  final String type;

  @override
  Widget build(BuildContext context) {
    final amountColor = switch (type) {
      'income' => AppColors.income,
      'expense' => AppColors.expense,
      'transfer' => AppColors.transfer,
      _ => AppColors.textPrimary,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(categoryName),
      trailing: Text(
        MoneyFormatter.brl(type == 'expense' ? -amountCents : amountCents),
        style: TextStyle(color: amountColor, fontWeight: FontWeight.w800),
      ),
    );
  }
}
