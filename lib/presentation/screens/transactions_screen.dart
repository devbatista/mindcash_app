import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: EmptyState(
        icon: Icons.receipt_long,
        title: 'Nenhuma transação cadastrada',
        message:
            'Use o botão de adicionar para registrar receitas, despesas e transferências.',
      ),
    );
  }
}
