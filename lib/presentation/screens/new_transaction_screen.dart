import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class NewTransactionScreen extends StatelessWidget {
  const NewTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova transação')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.add_circle,
            title: 'Nova transação',
            message: 'O formulário será implementado no próximo bloco.',
          ),
        ),
      ),
    );
  }
}
