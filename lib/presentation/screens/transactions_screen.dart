import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:mindcash_app/core/utils/money_formatter.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';
import 'package:mindcash_app/presentation/widgets/primary_button.dart';
import 'package:mindcash_app/presentation/widgets/transaction_list_item.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final repository = TransactionRepository(
      AppDependencies.databaseOf(context),
    );

    return FutureBuilder<List<Transaction>>(
      future: repository.listTransactions(
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedType,
        search: _search,
      ),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];

        return Column(
          children: [
            _TransactionFilters(
              selectedType: _selectedType,
              search: _search,
              startDate: _startDate,
              endDate: _endDate,
              onTypeChanged: (type) {
                setState(() => _selectedType = type);
              },
              onSearchChanged: (search) {
                setState(() => _search = search);
              },
              onPeriodChanged: (start, end) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                });
              },
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : _TransactionList(
                      transactions: transactions,
                      repository: repository,
                      onChanged: () => setState(() {}),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionFilters extends StatelessWidget {
  const _TransactionFilters({
    required this.selectedType,
    required this.search,
    required this.startDate,
    required this.endDate,
    required this.onTypeChanged,
    required this.onSearchChanged,
    required this.onPeriodChanged,
  });

  final String? selectedType;
  final String search;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String> onSearchChanged;
  final void Function(DateTime? start, DateTime? end) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por descrição',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'Todas',
                  selected: selectedType == null,
                  onSelected: () => onTypeChanged(null),
                ),
                _FilterChipButton(
                  label: 'Receitas',
                  selected: selectedType == 'income',
                  onSelected: () => onTypeChanged('income'),
                ),
                _FilterChipButton(
                  label: 'Despesas',
                  selected: selectedType == 'expense',
                  onSelected: () => onTypeChanged('expense'),
                ),
                _FilterChipButton(
                  label: 'Transferências',
                  selected: selectedType == 'transfer',
                  onSelected: () => onTypeChanged('transfer'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(_periodLabel),
                  onPressed: () => _pickPeriod(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _periodLabel {
    if (startDate == null || endDate == null) {
      return 'Período';
    }

    return '${_formatDate(startDate!)} - ${_formatDate(endDate!.subtract(const Duration(days: 1)))}';
  }

  Future<void> _pickPeriod(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(
              start: startDate!,
              end: endDate!.subtract(const Duration(days: 1)),
            )
          : null,
    );

    if (picked != null) {
      onPeriodChanged(
        DateTime(picked.start.year, picked.start.month, picked.start.day),
        DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
        ).add(const Duration(days: 1)),
      );
    }
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.transactions,
    required this.repository,
    required this.onChanged,
  });

  final List<Transaction> transactions;
  final TransactionRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyState(
          icon: Icons.receipt_long,
          title: 'Nenhuma transação encontrada',
          message: 'Ajuste os filtros ou registre uma nova transação.',
        ),
      );
    }

    final grouped = _groupByDate(transactions);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                _formatDate(group.date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (final transaction in group.transactions)
                    Dismissible(
                      key: ValueKey(transaction.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) =>
                          _confirmDelete(context, transaction),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 18),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: InkWell(
                        onTap: () => _openDetails(context, transaction),
                        child: TransactionListItem(
                          description: transaction.description,
                          categoryName: _typeLabel(transaction.type),
                          amountCents: transaction.amountCents,
                          type: transaction.type,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    Transaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar transação?'),
        content: Text('Deseja deletar "${transaction.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await repository.deleteTransaction(transaction.id);
      onChanged();
      return true;
    }

    return false;
  }

  Future<void> _openDetails(
    BuildContext context,
    Transaction transaction,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TransactionDetailsSheet(
        transaction: transaction,
        repository: repository,
        onChanged: onChanged,
      ),
    );
  }
}

class _TransactionDetailsSheet extends StatefulWidget {
  const _TransactionDetailsSheet({
    required this.transaction,
    required this.repository,
    required this.onChanged,
  });

  final Transaction transaction;
  final TransactionRepository repository;
  final VoidCallback onChanged;

  @override
  State<_TransactionDetailsSheet> createState() =>
      _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<_TransactionDetailsSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _noteController = TextEditingController(text: widget.transaction.note);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _typeLabel(widget.transaction.type),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            MoneyFormatter.brl(
              widget.transaction.type == 'expense'
                  ? -widget.transaction.amountCents
                  : widget.transaction.amountCents,
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Descrição',
            controller: _descriptionController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Observação',
            controller: _noteController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Salvar', icon: Icons.check, onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.updateTransaction(
      widget.transaction.copyWith(
        description: _descriptionController.text,
        note: Value(_noteController.text),
      ),
    );
    widget.onChanged();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

List<_TransactionGroup> _groupByDate(List<Transaction> transactions) {
  final groups = <DateTime, List<Transaction>>{};

  for (final transaction in transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    groups.putIfAbsent(date, () => []).add(transaction);
  }

  return groups.entries
      .map((entry) => _TransactionGroup(entry.key, entry.value))
      .toList();
}

class _TransactionGroup {
  const _TransactionGroup(this.date, this.transactions);

  final DateTime date;
  final List<Transaction> transactions;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _typeLabel(String type) {
  return switch (type) {
    'income' => 'Receita',
    'expense' => 'Despesa',
    'transfer' => 'Transferência',
    _ => 'Transação',
  };
}
