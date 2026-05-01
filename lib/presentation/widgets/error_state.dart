import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: EmptyState(
        icon: Icons.error_outline,
        title: title,
        message: message,
        action: onRetry == null
            ? null
            : FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
      ),
    );
  }
}
