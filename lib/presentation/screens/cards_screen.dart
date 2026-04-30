import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:mindcash_app/core/utils/money_formatter.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/credit_card_repository.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';
import 'package:mindcash_app/presentation/widgets/money_field.dart';
import 'package:mindcash_app/presentation/widgets/primary_button.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = CreditCardRepository(
      AppDependencies.databaseOf(context),
    );

    return FutureBuilder<List<CreditCard>>(
      future: repository.listActiveCreditCards(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cards.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyState(
              icon: Icons.credit_card,
              title: 'Nenhum cartão cadastrado',
              message:
                  'Cadastre seus cartões para acompanhar limite, fechamento, vencimento e fatura atual.',
              action: FilledButton.icon(
                onPressed: () => _openCreditCardForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Criar cartão'),
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
                onPressed: () => _openCreditCardForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Criar cartão'),
              ),
            ),
            const SizedBox(height: 12),
            for (final card in cards)
              _CreditCardListItem(
                card: card,
                summaryFuture: repository.calculateCurrentInvoice(card),
                onTap: () => _openInvoiceDetails(context, card),
                onEdit: () => _openCreditCardForm(context, creditCard: card),
                onDeactivate: () =>
                    _deactivateCreditCard(context, repository, card),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openCreditCardForm(
    BuildContext context, {
    CreditCard? creditCard,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CreditCardFormSheet(creditCard: creditCard),
    );

    if (saved ?? false) {
      setState(() {});
    }
  }

  Future<void> _openInvoiceDetails(
    BuildContext context,
    CreditCard creditCard,
  ) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _InvoiceDetailsSheet(creditCard: creditCard),
    );

    if (changed ?? false) {
      setState(() {});
    }
  }

  Future<void> _deactivateCreditCard(
    BuildContext context,
    CreditCardRepository repository,
    CreditCard creditCard,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inativar cartão?'),
        content: Text('Deseja inativar "${creditCard.name}"?'),
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

    if (confirmed ?? false) {
      await repository.deactivateCreditCard(creditCard.id);

      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _CreditCardListItem extends StatelessWidget {
  const _CreditCardListItem({
    required this.card,
    required this.summaryFuture,
    required this.onTap,
    required this.onEdit,
    required this.onDeactivate,
  });

  final CreditCard card;
  final Future<CreditCardInvoiceSummary> summaryFuture;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Limite ${MoneyFormatter.brl(card.limitCents)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_CreditCardAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _CreditCardAction.edit:
                          onEdit();
                        case _CreditCardAction.deactivate:
                          onDeactivate();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _CreditCardAction.edit,
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: _CreditCardAction.deactivate,
                        child: Text('Inativar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<CreditCardInvoiceSummary>(
                future: summaryFuture,
                builder: (context, snapshot) {
                  final summary = snapshot.data;
                  final invoiceValue = summary == null
                      ? MoneyFormatter.brl(0)
                      : MoneyFormatter.brl(summary.totalCents);
                  final status = summary?.isPaid ?? false ? 'Paga' : 'Aberta';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _CardMetric(
                              label: 'Fatura atual',
                              value: invoiceValue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CardMetric(label: 'Status', value: status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Fecha dia ${card.closingDay} • vence dia ${card.dueDay}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _CreditCardFormSheet extends StatefulWidget {
  const _CreditCardFormSheet({this.creditCard});

  final CreditCard? creditCard;

  @override
  State<_CreditCardFormSheet> createState() => _CreditCardFormSheetState();
}

class _CreditCardFormSheetState extends State<_CreditCardFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late final TextEditingController _closingDayController;
  late final TextEditingController _dueDayController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final creditCard = widget.creditCard;
    _nameController = TextEditingController(text: creditCard?.name);
    _limitController = TextEditingController(
      text: creditCard == null ? '' : creditCard.limitCents.toString(),
    );
    _closingDayController = TextEditingController(
      text: creditCard?.closingDay.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: creditCard?.dueDay.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.creditCard == null ? 'Criar cartão' : 'Editar cartão',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nome',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do cartão.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              MoneyField(controller: _limitController, label: 'Limite'),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Dia de fechamento',
                controller: _closingDayController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateDay,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Dia de vencimento',
                controller: _dueDayController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: _validateDay,
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
  }

  String? _validateDay(String? value) {
    final day = int.tryParse(value?.trim() ?? '');

    if (day == null || day < 1 || day > 31) {
      return 'Informe um dia entre 1 e 31.';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final repository = CreditCardRepository(
      AppDependencies.databaseOf(context),
    );
    final creditCard = widget.creditCard;
    final limitCents = MoneyField.parseCents(_limitController.text);
    final closingDay = int.parse(_closingDayController.text);
    final dueDay = int.parse(_dueDayController.text);

    if (creditCard == null) {
      await repository.createCreditCard(
        name: _nameController.text,
        limitCents: limitCents,
        closingDay: closingDay,
        dueDay: dueDay,
      );
    } else {
      await repository.updateCreditCard(
        creditCard.copyWith(
          name: _nameController.text,
          limitCents: limitCents,
          closingDay: closingDay,
          dueDay: dueDay,
          updatedAt: DateTime.now(),
          deletedAt: const Value.absent(),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _InvoiceDetailsSheet extends StatefulWidget {
  const _InvoiceDetailsSheet({required this.creditCard});

  final CreditCard creditCard;

  @override
  State<_InvoiceDetailsSheet> createState() => _InvoiceDetailsSheetState();
}

class _InvoiceDetailsSheetState extends State<_InvoiceDetailsSheet> {
  var _isPaying = false;

  @override
  Widget build(BuildContext context) {
    final repository = CreditCardRepository(
      AppDependencies.databaseOf(context),
    );

    return FutureBuilder<CreditCardInvoiceSummary>(
      future: repository.calculateCurrentInvoice(widget.creditCard),
      builder: (context, snapshot) {
        final summary = snapshot.data;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fatura atual',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.creditCard.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (summary == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _InvoiceSummaryHeader(summary: summary),
                  const SizedBox(height: 16),
                  Text(
                    'Lançamentos da fatura',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: summary.launches.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long,
                            title: 'Nenhum lançamento',
                            message:
                                'As despesas no período da fatura aparecerão aqui.',
                          )
                        : ListView.separated(
                            itemCount: summary.launches.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final launch = summary.launches[index];

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(launch.description),
                                subtitle: Text(_formatDate(launch.date)),
                                trailing: Text(
                                  MoneyFormatter.brl(launch.amountCents),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: summary.isPaid
                        ? 'Fatura paga'
                        : _isPaying
                        ? 'Registrando...'
                        : 'Registrar pagamento',
                    icon: summary.isPaid ? Icons.check_circle : Icons.payments,
                    onPressed: summary.isPaid || _isPaying
                        ? null
                        : () => _registerPayment(repository),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _registerPayment(CreditCardRepository repository) async {
    setState(() => _isPaying = true);

    await repository.registerInvoicePayment(widget.creditCard);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento da fatura registrado.')),
      );
    }
  }
}

class _InvoiceSummaryHeader extends StatelessWidget {
  const _InvoiceSummaryHeader({required this.summary});

  final CreditCardInvoiceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MoneyFormatter.brl(summary.totalCents),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Período: ${_formatDate(summary.startDate)} a ${_formatDate(summary.closingDate)}',
          ),
          Text('Vencimento: ${_formatDate(summary.dueDate)}'),
          Text(summary.isPaid ? 'Status: paga' : 'Status: aberta'),
        ],
      ),
    );
  }
}

enum _CreditCardAction { edit, deactivate }

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
