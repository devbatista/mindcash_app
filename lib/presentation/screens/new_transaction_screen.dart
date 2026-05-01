import 'package:flutter/material.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';
import 'package:mindcash_app/presentation/widgets/date_picker_field.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';
import 'package:mindcash_app/presentation/widgets/error_state.dart';
import 'package:mindcash_app/presentation/widgets/loading_state.dart';
import 'package:mindcash_app/presentation/widgets/money_field.dart';
import 'package:mindcash_app/presentation/widgets/primary_button.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({this.initialType = 'expense', super.key});

  final String initialType;

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  Future<_TransactionFormData>? _formData;

  late String _type;
  int? _categoryId;
  int? _sourceAccountId;
  int? _destinationAccountId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData ??= _loadFormData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova transação')),
      body: SafeArea(
        child: FutureBuilder<_TransactionFormData>(
          future: _formData,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(
                title: 'Não foi possível carregar o formulário',
                message:
                    'Confira contas e categorias locais e tente novamente.',
                onRetry: () => setState(() => _formData = _loadFormData()),
              );
            }

            if (!snapshot.hasData) {
              return const LoadingState(message: 'Carregando formulário...');
            }

            final data = snapshot.data!;

            if (data.accounts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.account_balance_wallet,
                  title: 'Cadastre uma conta primeiro',
                  message:
                      'Uma transação precisa de uma conta de origem para ser salva.',
                ),
              );
            }

            _ensureDefaults(data);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
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
                      ButtonSegment(
                        value: 'transfer',
                        label: Text('Transferência'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() {
                        _type = value.single;
                        _categoryId = null;
                        _destinationAccountId = null;
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
                  if (_type != 'transfer') ...[
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
                  ],
                  DropdownButtonFormField<int>(
                    initialValue: _sourceAccountId,
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
                      setState(() => _sourceAccountId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma conta.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_type == 'transfer') ...[
                    DropdownButtonFormField<int>(
                      initialValue: _destinationAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Conta de destino',
                        border: OutlineInputBorder(),
                      ),
                      items: data.accounts
                          .where((account) => account.id != _sourceAccountId)
                          .map(
                            (account) => DropdownMenuItem(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _destinationAccountId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione uma conta de destino.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  DatePickerField(
                    label: 'Data',
                    value: _date,
                    onChanged: (value) {
                      setState(() => _date = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Observação',
                    controller: _noteController,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: _isSaving ? 'Salvando...' : 'Salvar',
                    icon: Icons.check,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<_TransactionFormData> _loadFormData() async {
    final database = AppDependencies.databaseOf(context);
    final accountRepository = AccountRepository(database);
    final categoryRepository = CategoryRepository(database);

    final accounts = await accountRepository.listActiveAccounts();
    final categories = await categoryRepository.listActiveCategories();

    return _TransactionFormData(accounts: accounts, categories: categories);
  }

  void _ensureDefaults(_TransactionFormData data) {
    _sourceAccountId ??= data.accounts.first.id;

    if (_type != 'transfer') {
      final categories = data.categoriesForType(_type);
      if (_categoryId == null && categories.isNotEmpty) {
        _categoryId = categories.first.id;
      }
    }

    if (_type == 'transfer' && _destinationAccountId == null) {
      final destinationAccounts = data.accounts
          .where((account) => account.id != _sourceAccountId)
          .toList();

      if (destinationAccounts.isNotEmpty) {
        _destinationAccountId = destinationAccounts.first.id;
      }
    }
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
      final repository = TransactionRepository(
        AppDependencies.databaseOf(context),
      );

      if (_type == 'transfer') {
        await repository.createTransfer(
          amountCents: amountCents,
          description: _descriptionController.text,
          date: _date,
          sourceAccountId: _sourceAccountId!,
          destinationAccountId: _destinationAccountId!,
          note: _noteController.text,
        );
      } else {
        await repository.createTransaction(
          type: _type,
          amountCents: amountCents,
          description: _descriptionController.text,
          date: _date,
          sourceAccountId: _sourceAccountId!,
          categoryId: _categoryId,
          note: _noteController.text,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transação salva.')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível salvar a transação.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TransactionFormData {
  const _TransactionFormData({
    required this.accounts,
    required this.categories,
  });

  final List<Account> accounts;
  final List<Category> categories;

  List<Category> categoriesForType(String type) {
    return categories.where((category) => category.type == type).toList();
  }
}
