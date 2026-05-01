import 'package:flutter/material.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/app_settings_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/seeders/default_category_seeder.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';
import 'package:mindcash_app/presentation/widgets/money_field.dart';
import 'package:mindcash_app/presentation/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _accountNameController = TextEditingController(text: 'Carteira');
  final _initialBalanceController = TextEditingController();
  String _accountType = 'wallet';
  var _isSaving = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _accountNameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Text(
                'MindCash',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure seu perfil e a primeira conta para começar com os saldos certos.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Perfil',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Nome do usuário',
                controller: _userNameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe seu nome.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: 'BRL',
                decoration: const InputDecoration(
                  labelText: 'Moeda padrão',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'BRL', child: Text('BRL')),
                ],
                onChanged: null,
              ),
              const SizedBox(height: 28),
              Text(
                'Conta inicial',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Nome da conta',
                controller: _accountNameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe o nome da conta.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Tipo da conta',
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
                  if (value == null) {
                    return;
                  }

                  setState(() => _accountType = value);
                },
              ),
              const SizedBox(height: 12),
              MoneyField(
                controller: _initialBalanceController,
                label: 'Saldo inicial',
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: _isSaving ? 'Salvando...' : 'Começar',
                icon: Icons.check,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final database = AppDependencies.databaseOf(context);

      await database.transaction(() async {
        final accountRepository = AccountRepository(database);
        final accounts = await accountRepository.listActiveAccounts();

        if (accounts.isEmpty) {
          await accountRepository.createAccount(
            name: _accountNameController.text,
            type: _accountType,
            initialBalanceCents: MoneyField.parseCents(
              _initialBalanceController.text,
            ),
          );
        }

        await DefaultCategorySeeder(CategoryRepository(database)).seed();
        await AppSettingsRepository(database).completeOnboarding(
          userName: _userNameController.text,
          currencyCode: 'BRL',
        );
      });

      if (mounted) {
        widget.onCompleted();
      }
    } catch (error, stackTrace) {
      debugPrint('Onboarding failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível concluir o cadastro inicial.'),
          ),
        );
      }
    }
  }
}
