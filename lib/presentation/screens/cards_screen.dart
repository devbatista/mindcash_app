import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: EmptyState(
        icon: Icons.credit_card,
        title: 'Cartões entram depois do MVP',
        message: 'Primeiro vamos consolidar contas, categorias e transações.',
      ),
    );
  }
}
