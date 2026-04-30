import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:mindcash_app/core/utils/money_formatter.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';
import 'package:mindcash_app/presentation/widgets/money_field.dart';
import 'package:mindcash_app/presentation/widgets/primary_button.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final database = AppDependencies.databaseOf(context);
    final accountRepository = AccountRepository(database);
    final transactionRepository = TransactionRepository(database);

    return FutureBuilder<List<Account>>(
      future: accountRepository.listActiveAccounts(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (accounts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyState(
              icon: Icons.account_balance_wallet,
              title: 'Nenhuma conta cadastrada',
              message:
                  'Suas contas locais serão a base para calcular saldos offline.',
              action: FilledButton.icon(
                onPressed: () => _openAccountForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Criar conta'),
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
                onPressed: () => _openAccountForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Criar conta'),
              ),
            ),
            const SizedBox(height: 12),
            for (final account in accounts)
              _AccountListItem(
                account: account,
                balanceFuture: transactionRepository.calculateAccountBalance(
                  account.id,
                ),
                onEdit: () => _openAccountForm(context, account: account),
                onDeactivate: () =>
                    _deactivateAccount(context, accountRepository, account),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openAccountForm(
    BuildContext context, {
    Account? account,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AccountFormSheet(account: account),
    );

    if (saved ?? false) {
      setState(() {});
    }
  }

  Future<void> _deactivateAccount(
    BuildContext context,
    AccountRepository repository,
    Account account,
  ) async {
    final hasTransactions = await repository.hasTransactions(account.id);

    if (!context.mounted) {
      return;
    }

    if (hasTransactions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta com transações não pode ser inativada.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inativar conta?'),
        content: Text('Deseja inativar "${account.name}"?'),
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
      await repository.deactivateAccount(account.id);

      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _AccountListItem extends StatelessWidget {
  const _AccountListItem({
    required this.account,
    required this.balanceFuture,
    required this.onEdit,
    required this.onDeactivate,
  });

  final Account account;
  final Future<int> balanceFuture;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(_accountTypeLabel(account.type)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<int>(
              future: balanceFuture,
              builder: (context, snapshot) {
                return Text(
                  MoneyFormatter.brl(snapshot.data ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                );
              },
            ),
            PopupMenuButton<_AccountAction>(
              onSelected: (action) {
                switch (action) {
                  case _AccountAction.edit:
                    onEdit();
                  case _AccountAction.deactivate:
                    onDeactivate();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _AccountAction.edit,
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: _AccountAction.deactivate,
                  child: Text('Inativar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet({this.account});

  final Account? account;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _initialBalanceController;
  late String _type;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name);
    _initialBalanceController = TextEditingController(
      text: account == null ? '' : account.initialBalanceCents.toString(),
    );
    _type = account?.type ?? 'wallet';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
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
          children: [
            Text(
              widget.account == null ? 'Criar conta' : 'Editar conta',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nome',
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome da conta.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'checking', child: Text('Corrente')),
                DropdownMenuItem(value: 'wallet', child: Text('Carteira')),
                DropdownMenuItem(value: 'savings', child: Text('Poupança')),
                DropdownMenuItem(
                  value: 'investment',
                  child: Text('Investimento'),
                ),
                DropdownMenuItem(value: 'business', child: Text('PJ')),
                DropdownMenuItem(value: 'other', child: Text('Outro')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            if (widget.account == null)
              MoneyField(
                controller: _initialBalanceController,
                label: 'Saldo inicial',
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
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final repository = AccountRepository(AppDependencies.databaseOf(context));
    final account = widget.account;

    if (account == null) {
      await repository.createAccount(
        name: _nameController.text,
        type: _type,
        initialBalanceCents: MoneyField.parseCents(
          _initialBalanceController.text,
        ),
      );
    } else {
      await repository.updateAccount(
        account.copyWith(
          name: _nameController.text,
          type: _type,
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

enum _AccountAction { edit, deactivate }

String _accountTypeLabel(String type) {
  return switch (type) {
    'checking' => 'Corrente',
    'wallet' => 'Carteira',
    'savings' => 'Poupança',
    'investment' => 'Investimento',
    'business' => 'PJ',
    _ => 'Outro',
  };
}
