import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:mindcash_app/core/utils/money_formatter.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/recurrence_repository.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/screens/backup_screen.dart';
import 'package:mindcash_app/presentation/screens/reports_screen.dart';
import 'package:mindcash_app/presentation/screens/settings_screen.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';
import 'package:mindcash_app/presentation/widgets/date_picker_field.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';
import 'package:mindcash_app/presentation/widgets/error_state.dart';
import 'package:mindcash_app/presentation/widgets/loading_state.dart';
import 'package:mindcash_app/presentation/widgets/money_field.dart';
import 'package:mindcash_app/presentation/widgets/primary_button.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Configurações'),
              Tab(text: 'Recorrências'),
              Tab(text: 'Relatórios'),
              Tab(text: 'Backup'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SettingsScreen(),
                _RecurrencesTab(),
                ReportsScreen(),
                BackupScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurrencesTab extends StatefulWidget {
  const _RecurrencesTab();

  @override
  State<_RecurrencesTab> createState() => _RecurrencesTabState();
}

class _RecurrencesTabState extends State<_RecurrencesTab> {
  @override
  Widget build(BuildContext context) {
    final repository = RecurrenceRepository(
      AppDependencies.databaseOf(context),
    );

    return FutureBuilder<List<Recurrence>>(
      future: repository.listActiveRecurrences(),
      builder: (context, snapshot) {
        final recurrences = snapshot.data ?? [];

        if (snapshot.hasError) {
          return ErrorState(
            title: 'Não foi possível carregar as recorrências',
            message: 'Confira os dados locais e tente novamente.',
            onRetry: () => setState(() {}),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Carregando recorrências...');
        }

        if (recurrences.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyState(
              icon: Icons.repeat,
              title: 'Nenhuma recorrência cadastrada',
              message:
                  'Crie receitas e despesas mensais para que o app lance tudo automaticamente.',
              action: FilledButton.icon(
                onPressed: () => _openRecurrenceForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Criar recorrência'),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _openRecurrenceForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Criar recorrência'),
              ),
            ),
            const SizedBox(height: 12),
            for (final recurrence in recurrences)
              _RecurrenceListItem(
                recurrence: recurrence,
                onEdit: () =>
                    _openRecurrenceForm(context, recurrence: recurrence),
                onDeactivate: () =>
                    _deactivateRecurrence(context, repository, recurrence),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openRecurrenceForm(
    BuildContext context, {
    Recurrence? recurrence,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RecurrenceFormSheet(recurrence: recurrence),
    );

    if (saved ?? false) {
      setState(() {});
    }
  }

  Future<void> _deactivateRecurrence(
    BuildContext context,
    RecurrenceRepository repository,
    Recurrence recurrence,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar recorrência?'),
        content: Text('Deseja desativar "${recurrence.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await repository.deactivateRecurrence(recurrence.id);

      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _RecurrenceListItem extends StatelessWidget {
  const _RecurrenceListItem({
    required this.recurrence,
    required this.onEdit,
    required this.onDeactivate,
  });

  final Recurrence recurrence;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final isIncome = recurrence.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward),
        ),
        title: Text(
          recurrence.description,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Todo dia ${recurrence.dayOfMonth} • próxima em ${_formatDate(recurrence.nextDueDate)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MoneyFormatter.brl(recurrence.amountCents),
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
            PopupMenuButton<_RecurrenceAction>(
              onSelected: (action) {
                switch (action) {
                  case _RecurrenceAction.edit:
                    onEdit();
                  case _RecurrenceAction.deactivate:
                    onDeactivate();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _RecurrenceAction.edit,
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: _RecurrenceAction.deactivate,
                  child: Text('Desativar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrenceFormSheet extends StatefulWidget {
  const _RecurrenceFormSheet({this.recurrence});

  final Recurrence? recurrence;

  @override
  State<_RecurrenceFormSheet> createState() => _RecurrenceFormSheetState();
}

class _RecurrenceFormSheetState extends State<_RecurrenceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dayController;
  late final TextEditingController _noteController;
  Future<_RecurrenceFormData>? _formData;
  late String _type;
  late DateTime _nextDueDate;
  int? _accountId;
  int? _categoryId;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final recurrence = widget.recurrence;
    _type = recurrence?.type ?? 'expense';
    _nextDueDate = recurrence?.nextDueDate ?? DateTime.now();
    _accountId = recurrence?.accountId;
    _categoryId = recurrence?.categoryId;
    _amountController = TextEditingController(
      text: recurrence == null ? '' : recurrence.amountCents.toString(),
    );
    _descriptionController = TextEditingController(
      text: recurrence?.description,
    );
    _dayController = TextEditingController(
      text: recurrence?.dayOfMonth.toString() ?? DateTime.now().day.toString(),
    );
    _noteController = TextEditingController(text: recurrence?.note);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData ??= _loadFormData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dayController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RecurrenceFormData>(
      future: _formData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(
            title: 'Não foi possível carregar a recorrência',
            message: 'Confira contas e categorias locais e tente novamente.',
            onRetry: () => setState(() => _formData = _loadFormData()),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: LoadingState(message: 'Carregando recorrência...'),
          );
        }

        final data = snapshot.data!;
        _ensureDefaults(data);

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recurrence == null
                        ? 'Criar recorrência'
                        : 'Editar recorrência',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Despesa'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text('Receita'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() {
                        _type = value.single;
                        _categoryId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  MoneyField(controller: _amountController),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Descrição',
                    controller: _descriptionController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe uma descrição.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _accountId,
                    decoration: const InputDecoration(
                      labelText: 'Conta',
                      border: OutlineInputBorder(),
                    ),
                    items: data.accounts
                        .map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _accountId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma conta.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: data
                        .categoriesForType(_type)
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _categoryId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma categoria.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Dia do mês',
                    controller: _dayController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final day = int.tryParse(value?.trim() ?? '');

                      if (day == null || day < 1 || day > 31) {
                        return 'Informe um dia entre 1 e 31.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DatePickerField(
                    label: 'Próxima data',
                    value: _nextDueDate,
                    onChanged: (value) {
                      setState(() => _nextDueDate = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Observação',
                    controller: _noteController,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _isSaving ? 'Salvando...' : 'Salvar',
                    icon: Icons.check,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_RecurrenceFormData> _loadFormData() async {
    final database = AppDependencies.databaseOf(context);
    final accounts = await AccountRepository(database).listActiveAccounts();
    final categories = await CategoryRepository(
      database,
    ).listActiveCategories();

    return _RecurrenceFormData(accounts: accounts, categories: categories);
  }

  void _ensureDefaults(_RecurrenceFormData data) {
    _accountId ??= data.accounts.isEmpty ? null : data.accounts.first.id;
    final categories = data.categoriesForType(_type);
    _categoryId ??= categories.isEmpty ? null : categories.first.id;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountCents = MoneyField.parseCents(_amountController.text);
    if (amountCents <= 0) {
      _showMessage('Informe um valor maior que zero.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = RecurrenceRepository(
        AppDependencies.databaseOf(context),
      );
      final recurrence = widget.recurrence;
      final dayOfMonth = int.parse(_dayController.text);

      if (recurrence == null) {
        await repository.createMonthlyRecurrence(
          type: _type,
          amountCents: amountCents,
          description: _descriptionController.text,
          dayOfMonth: dayOfMonth,
          nextDueDate: _nextDueDate,
          accountId: _accountId!,
          categoryId: _categoryId,
          note: _noteController.text,
        );
      } else {
        await repository.updateRecurrence(
          recurrence.copyWith(
            type: _type,
            amountCents: amountCents,
            description: _descriptionController.text,
            dayOfMonth: dayOfMonth,
            nextDueDate: _nextDueDate,
            accountId: _accountId!,
            categoryId: Value(_categoryId),
            note: Value(_noteController.text),
            updatedAt: DateTime.now(),
            deletedAt: const Value.absent(),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showMessage('Não foi possível salvar a recorrência.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecurrenceFormData {
  const _RecurrenceFormData({required this.accounts, required this.categories});

  final List<Account> accounts;
  final List<Category> categories;

  List<Category> categoriesForType(String type) {
    return categories.where((category) => category.type == type).toList();
  }
}

enum _RecurrenceAction { edit, deactivate }

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
