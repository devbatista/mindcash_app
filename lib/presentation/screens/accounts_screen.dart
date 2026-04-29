import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: EmptyState(
        icon: Icons.account_balance_wallet,
        title: 'Nenhuma conta cadastrada',
        message:
            'Suas contas locais serão a base para calcular saldos offline.',
      ),
    );
  }
}
