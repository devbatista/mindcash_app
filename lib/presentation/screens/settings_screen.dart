import 'package:flutter/material.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/app_settings_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/seeders/default_account_seeder.dart';
import 'package:mindcash_app/data/seeders/default_category_seeder.dart';
import 'package:mindcash_app/data/services/local_backup_service.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _userNameController;
  String _currencyCode = 'BRL';
  var _isSavingSettings = false;
  var _isResetting = false;
  var _didLoadData = false;
  Future<_SettingsData>? _settingsData;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadData) {
      return;
    }

    _didLoadData = true;
    _settingsData = _loadData();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SettingsData>(
      future: _settingsData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Não foi possível carregar as configurações',
                message: snapshot.error.toString(),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _ProfileCard(
              userNameController: _userNameController,
              currencyCode: _currencyCode,
              isSaving: _isSavingSettings,
              onCurrencyChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _currencyCode = value);
              },
              onSave: _saveSettings,
            ),
            const SizedBox(height: 12),
            _CategoriesCard(
              categories: data.categories,
              onCreate: () => _openCategoryForm(),
              onEdit: _openCategoryForm,
              onDeactivate: _deactivateCategory,
            ),
            const SizedBox(height: 12),
            _LocalDataCard(
              counts: data.counts,
              isResetting: _isResetting,
              onExportBackup: _exportBackup,
              onReset: _resetAllData,
            ),
            const SizedBox(height: 12),
            const _AboutCard(),
          ],
        );
      },
    );
  }

  Future<_SettingsData> _loadData() async {
    final database = AppDependencies.databaseOf(context);
    final settings = await AppSettingsRepository(database).getSettings();
    final categories = await CategoryRepository(
      database,
    ).listActiveCategories();
    final counts = await _loadCounts(database);

    _userNameController.text = settings.userName;
    _currencyCode = settings.currencyCode;

    return _SettingsData(categories: categories, counts: counts);
  }

  Future<_LocalDataCounts> _loadCounts(AppDatabase database) async {
    final accounts = await database.select(database.accounts).get();
    final categories = await database.select(database.categories).get();
    final transactions = await database.select(database.transactions).get();
    final creditCards = await database.select(database.creditCards).get();
    final installments = await database.select(database.installments).get();
    final recurrences = await database.select(database.recurrences).get();

    return _LocalDataCounts(
      accounts: accounts.length,
      categories: categories.length,
      transactions: transactions.length,
      creditCards: creditCards.length,
      installments: installments.length,
      recurrences: recurrences.length,
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);

    await AppSettingsRepository(
      AppDependencies.databaseOf(context),
    ).updateSettings(
      userName: _userNameController.text,
      currencyCode: _currencyCode,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSavingSettings = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configurações salvas.')));
  }

  Future<void> _openCategoryForm([Category? category]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CategoryFormSheet(category: category),
    );

    if (saved ?? false) {
      _reload();
    }
  }

  Future<void> _deactivateCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inativar categoria?'),
        content: Text('Deseja inativar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    final database = AppDependencies.databaseOf(context);
    await CategoryRepository(database).deactivateCategory(category.id);

    if (mounted) {
      _reload();
    }
  }

  Future<void> _exportBackup() async {
    final content = await LocalBackupService(
      AppDependencies.databaseOf(context),
    ).exportJson();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup JSON'),
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

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ResetConfirmationDialog(),
    );

    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() => _isResetting = true);

    final database = AppDependencies.databaseOf(context);
    await LocalBackupService(database).resetAllData();
    await DefaultAccountSeeder(AccountRepository(database)).seed();
    await DefaultCategorySeeder(CategoryRepository(database)).seed();
    await AppSettingsRepository(database).getSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _isResetting = false;
      _settingsData = _loadData();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dados locais resetados.')));
  }

  void _reload() {
    setState(() => _settingsData = _loadData());
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.userNameController,
    required this.currencyCode,
    required this.isSaving,
    required this.onCurrencyChanged,
    required this.onSave,
  });

  final TextEditingController userNameController;
  final String currencyCode;
  final bool isSaving;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferências',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: userNameController,
              label: 'Nome do usuário',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: currencyCode,
              decoration: const InputDecoration(labelText: 'Moeda padrão'),
              items: const [DropdownMenuItem(value: 'BRL', child: Text('BRL'))],
              onChanged: onCurrencyChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: const Icon(Icons.save),
                label: Text(isSaving ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({
    required this.categories,
    required this.onCreate,
    required this.onEdit,
    required this.onDeactivate,
  });

  final List<Category> categories;
  final VoidCallback onCreate;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Categorias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  tooltip: 'Criar categoria',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (categories.isEmpty)
              const EmptyState(
                icon: Icons.category,
                title: 'Nenhuma categoria ativa',
                message:
                    'Crie categorias para classificar receitas e despesas.',
              )
            else
              for (final category in categories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _categoryColor(
                      category,
                    ).withValues(alpha: 0.12),
                    foregroundColor: _categoryColor(category),
                    child: Icon(_categoryIcon(category)),
                  ),
                  title: Text(category.name),
                  subtitle: Text(
                    category.type == 'income' ? 'Receita' : 'Despesa',
                  ),
                  trailing: PopupMenuButton<_CategoryAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _CategoryAction.edit:
                          onEdit(category);
                        case _CategoryAction.deactivate:
                          onDeactivate(category);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _CategoryAction.edit,
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: _CategoryAction.deactivate,
                        child: Text('Inativar'),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(Category category) {
    return Color(category.colorValue ?? 0xFF3563D8);
  }

  IconData _categoryIcon(Category category) {
    return switch (category.iconName) {
      'payments' => Icons.payments,
      'add_card' => Icons.add_card,
      'shopping_cart' => Icons.shopping_cart,
      'restaurant' => Icons.restaurant,
      'directions_car' => Icons.directions_car,
      'medical_services' => Icons.medical_services,
      'home' => Icons.home,
      _ => Icons.more_horiz,
    };
  }
}

class _LocalDataCard extends StatelessWidget {
  const _LocalDataCard({
    required this.counts,
    required this.isResetting,
    required this.onExportBackup,
    required this.onReset,
  });

  final _LocalDataCounts counts;
  final bool isResetting;
  final VoidCallback onExportBackup;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados locais',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountChip(label: 'Contas', value: counts.accounts),
                _CountChip(label: 'Categorias', value: counts.categories),
                _CountChip(label: 'Transações', value: counts.transactions),
                _CountChip(label: 'Cartões', value: counts.creditCards),
                _CountChip(label: 'Parcelas', value: counts.installments),
                _CountChip(label: 'Recorrências', value: counts.recurrences),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onExportBackup,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar backup'),
                ),
                OutlinedButton.icon(
                  onPressed: isResetting ? null : onReset,
                  icon: const Icon(Icons.delete_forever),
                  label: Text(isResetting ? 'Resetando...' : 'Resetar dados'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('Sobre o app'),
        subtitle: Text('MindCash 1.0.0+1 • financeiro pessoal offline-first'),
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final Category? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _type;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name);
    _type = category?.type ?? 'expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.category == null ? 'Nova categoria' : 'Editar categoria',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: 'Nome',
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Informe o nome.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Despesa')),
                ButtonSegment(value: 'income', label: Text('Receita')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() => _type = selection.single);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_isSaving ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final repository = CategoryRepository(AppDependencies.databaseOf(context));
    final category = widget.category;
    if (category == null) {
      await repository.createCategory(
        name: _nameController.text,
        type: _type,
        colorValue: _type == 'income' ? 0xFF43A047 : 0xFF3563D8,
        iconName: _type == 'income' ? 'payments' : 'more_horiz',
      );
    } else {
      await repository.updateCategory(
        category.copyWith(
          name: _nameController.text,
          type: _type,
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _ResetConfirmationDialog extends StatefulWidget {
  const _ResetConfirmationDialog();

  @override
  State<_ResetConfirmationDialog> createState() =>
      _ResetConfirmationDialogState();
}

class _ResetConfirmationDialogState extends State<_ResetConfirmationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canReset = _controller.text.trim().toUpperCase() == 'RESETAR';

    return AlertDialog(
      title: const Text('Resetar dados locais?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Esta ação apaga contas, categorias, transações, cartões, parcelas, recorrências e preferências.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Digite RESETAR'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canReset ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Resetar'),
        ),
      ],
    );
  }
}

class _SettingsData {
  const _SettingsData({required this.categories, required this.counts});

  final List<Category> categories;
  final _LocalDataCounts counts;
}

class _LocalDataCounts {
  const _LocalDataCounts({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.creditCards,
    required this.installments,
    required this.recurrences,
  });

  final int accounts;
  final int categories;
  final int transactions;
  final int creditCards;
  final int installments;
  final int recurrences;
}

enum _CategoryAction { edit, deactivate }
