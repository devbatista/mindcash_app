import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: EmptyState(
        icon: Icons.more,
        title: 'Configurações e backup',
        message:
            'Aqui ficarão categorias, exportação local e preferências do app.',
      ),
    );
  }
}
