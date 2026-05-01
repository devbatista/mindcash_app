import 'package:flutter/material.dart';
import 'package:mindcash_app/data/services/local_backup_service.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _importController = TextEditingController();
  String? _validationMessage;
  bool _isValidBackup = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        _BackupActionCard(
          title: 'Exportar JSON',
          message:
              'Gera um backup completo com contas, categorias, transações, cartões, parcelas e recorrências.',
          icon: Icons.data_object,
          onPressed: _isBusy ? null : _exportJson,
        ),
        const SizedBox(height: 12),
        _BackupActionCard(
          title: 'Exportar CSV',
          message: 'Gera uma planilha simples com as transações cadastradas.',
          icon: Icons.table_chart,
          onPressed: _isBusy ? null : _exportCsv,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importar JSON',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cole aqui um backup JSON do MindCash. Antes de importar, o app cria um backup de segurança do estado atual.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _importController,
                  minLines: 5,
                  maxLines: 9,
                  decoration: const InputDecoration(
                    labelText: 'Backup JSON',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (_validationMessage != null)
                  Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: _isValidBackup ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _validateImport,
                      icon: const Icon(Icons.verified),
                      label: const Text('Validar arquivo'),
                    ),
                    FilledButton.icon(
                      onPressed: _isBusy || !_isValidBackup
                          ? null
                          : _importJson,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_isBusy ? 'Importando...' : 'Importar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportJson() async {
    setState(() => _isBusy = true);
    final backup = await LocalBackupService(
      AppDependencies.databaseOf(context),
    ).exportJson();

    if (mounted) {
      setState(() => _isBusy = false);
      _showContentDialog(title: 'Backup JSON', content: backup);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isBusy = true);
    final csv = await LocalBackupService(
      AppDependencies.databaseOf(context),
    ).exportCsv();

    if (mounted) {
      setState(() => _isBusy = false);
      _showContentDialog(title: 'Backup CSV', content: csv);
    }
  }

  void _validateImport() {
    final result = LocalBackupService(
      AppDependencies.databaseOf(context),
    ).validateJson(_importController.text);

    setState(() {
      _isValidBackup = result.isValid;
      _validationMessage = result.message;
    });
  }

  Future<void> _importJson() async {
    setState(() => _isBusy = true);

    try {
      final result = await LocalBackupService(
        AppDependencies.databaseOf(context),
      ).importJson(_importController.text);

      if (mounted) {
        setState(() => _isBusy = false);
        _showContentDialog(
          title: 'Backup de segurança',
          content: result.safetyBackupJson,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup importado com sucesso.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível importar o backup.')),
        );
      }
    }
  }

  Future<void> _showContentDialog({
    required String title,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(content)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _BackupActionCard extends StatelessWidget {
  const _BackupActionCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(message),
        trailing: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.download),
          label: const Text('Gerar'),
        ),
      ),
    );
  }
}
