import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/app_settings_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/credit_card_repository.dart';
import 'package:mindcash_app/data/repositories/recurrence_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/data/services/local_backup_service.dart';
import 'package:mindcash_app/presentation/app/mindcash_app.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.memory();
    await AppSettingsRepository(
      database,
    ).completeOnboarding(userName: 'DevBatista', currencyCode: 'BRL');
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpMindCashApp(
    WidgetTester tester, {
    AppDatabase? appDatabase,
  }) async {
    await tester.pumpWidget(MindCashApp(database: appDatabase ?? database));
    await tester.pumpAndSettle();
  }

  Future<void> openNewTransaction(
    WidgetTester tester, {
    String type = 'Despesa',
  }) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Novo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(type));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the MindCash app shell', (tester) async {
    await pumpMindCashApp(tester);

    expect(find.text('Olá, DevBatista'), findsOneWidget);
    expect(find.text('Saldo total'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsWidgets);
    expect(find.text('Novo'), findsOneWidget);
  });

  testWidgets('completes initial onboarding', (tester) async {
    await LocalBackupService(database).resetAllData();

    await pumpMindCashApp(tester);

    expect(find.text('MindCash'), findsOneWidget);
    expect(find.text('Nome do usuário'), findsOneWidget);
    expect(find.text('Conta inicial'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Rafael');
    await tester.enterText(find.byType(TextFormField).at(1), 'Banco');
    await tester.enterText(find.byType(TextFormField).at(2), '4500');
    await tester.ensureVisible(find.text('Começar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    final settings = await AppSettingsRepository(database).getSettings();
    final accounts = await AccountRepository(database).listActiveAccounts();
    final categories = await CategoryRepository(
      database,
    ).listActiveCategories();

    expect(settings.hasCompletedOnboarding, isTrue);
    expect(settings.userName, 'Rafael');
    expect(accounts, hasLength(1));
    expect(accounts.single.name, 'Banco');
    expect(accounts.single.initialBalanceCents, 4500);
    expect(categories, isNotEmpty);
  });

  testWidgets('navigates between main sections', (tester) async {
    await pumpMindCashApp(tester);

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
  });

  testWidgets('opens new transaction route from create menu', (tester) async {
    await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    await CategoryRepository(
      database,
    ).createCategory(name: 'Mercado', type: 'expense');

    await pumpMindCashApp(tester);

    await openNewTransaction(tester);

    expect(find.text('Nova transação'), findsWidgets);
    expect(find.text('Valor'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
  });

  testWidgets('creates transaction from new transaction form', (tester) async {
    await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    await CategoryRepository(
      database,
    ).createCategory(name: 'Mercado', type: 'expense');

    await pumpMindCashApp(tester);

    await openNewTransaction(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '12345');
    await tester.enterText(find.byType(TextFormField).at(1), 'Compra do mês');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final transactions = await TransactionRepository(
      database,
    ).listActiveTransactions();

    expect(transactions, hasLength(1));
    expect(transactions.single.description, 'Compra do mês');
    expect(transactions.single.amountCents, 12345);
    expect(find.text('Saldo total'), findsOneWidget);
  });

  testWidgets('toggles dashboard amount visibility', (tester) async {
    await pumpMindCashApp(tester);

    await tester.tap(find.byTooltip('Ocultar valores'));
    await tester.pump();

    expect(find.byTooltip('Mostrar valores'), findsOneWidget);
    expect(find.text('••••'), findsWidgets);
  });

  testWidgets('changes dashboard month from selector', (tester) async {
    await pumpMindCashApp(tester);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();

    final year = DateTime.now().year;
    await tester.tap(find.text('Janeiro/$year'));
    await tester.pumpAndSettle();

    expect(find.text('Janeiro/$year'), findsOneWidget);
  });

  testWidgets('opens transactions tab from dashboard category action', (
    tester,
  ) async {
    final accountRepository = AccountRepository(database);
    final categoryRepository = CategoryRepository(database);
    final transactionRepository = TransactionRepository(database);
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    final category = await categoryRepository.createCategory(
      name: 'Mercado',
      type: 'expense',
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 1000,
      description: 'Compra',
      date: DateTime.now(),
      sourceAccountId: account.id,
      categoryId: category.id,
    );

    await pumpMindCashApp(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();

    expect(find.text('Transações'), findsWidgets);
    expect(find.text('Compra'), findsOneWidget);
  });

  testWidgets('filters and searches transactions', (tester) async {
    final accountRepository = AccountRepository(database);
    final transactionRepository = TransactionRepository(database);
    final account = await accountRepository.createAccount(
      name: 'Carteira',
      type: 'wallet',
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      amountCents: 1000,
      description: 'Mercado',
      date: DateTime.now(),
      sourceAccountId: account.id,
    );
    await transactionRepository.createTransaction(
      type: 'income',
      amountCents: 2000,
      description: 'Salário',
      date: DateTime.now(),
      sourceAccountId: account.id,
    );

    await pumpMindCashApp(tester);

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);

    await tester.tap(find.text('Despesas'));
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Salário'), findsNothing);

    await tester.enterText(find.byType(TextField), 'mer');
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
  });

  testWidgets('creates account from accounts screen', (tester) async {
    await pumpMindCashApp(tester);

    await tester.tap(find.text('Contas').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Banco');
    await tester.enterText(find.byType(TextFormField).at(1), '15000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Banco'), findsOneWidget);
    expect(find.text('R\$ 150,00'), findsOneWidget);
  });

  testWidgets('does not deactivate account with transactions', (tester) async {
    final account = await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    await TransactionRepository(database).createTransaction(
      type: 'income',
      amountCents: 1000,
      description: 'Entrada',
      date: DateTime.now(),
      sourceAccountId: account.id,
    );

    await pumpMindCashApp(tester);

    await tester.tap(find.text('Contas').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inativar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Conta com transações não pode ser inativada.'),
      findsOneWidget,
    );
  });

  testWidgets('creates credit card from cards screen', (tester) async {
    await pumpMindCashApp(tester);

    await tester.tap(find.text('Cartões').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar cartão'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Nubank');
    await tester.enterText(find.byType(TextFormField).at(1), '500000');
    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.enterText(find.byType(TextFormField).at(3), '17');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final cards = await CreditCardRepository(database).listActiveCreditCards();

    expect(cards, hasLength(1));
    expect(cards.single.name, 'Nubank');
    expect(find.text('Nubank'), findsOneWidget);
    expect(find.text('Limite R\$ 5.000,00'), findsOneWidget);
  });

  testWidgets('creates recurrence from more screen', (tester) async {
    await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    await CategoryRepository(
      database,
    ).createCategory(name: 'Assinaturas', type: 'expense');

    await pumpMindCashApp(tester);

    await tester.tap(find.text('Mais').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Recorrências'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar recorrência'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '3990');
    await tester.enterText(find.byType(TextFormField).at(1), 'Streaming');
    await tester.enterText(find.byType(TextFormField).at(2), '15');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final recurrences = await RecurrenceRepository(
      database,
    ).listActiveRecurrences();

    expect(recurrences, hasLength(1));
    expect(recurrences.single.description, 'Streaming');
    expect(find.text('Streaming'), findsOneWidget);
  });

  testWidgets('shows settings tab without staying on loading', (tester) async {
    await CategoryRepository(
      database,
    ).createCategory(name: 'Mercado', type: 'expense');

    await pumpMindCashApp(tester);

    await tester.tap(find.text('Mais').last);
    await tester.pumpAndSettle();

    expect(find.text('Preferências'), findsOneWidget);
    expect(find.text('Nome do usuário'), findsOneWidget);
    expect(find.text('Moeda padrão'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Dados locais'), findsOneWidget);
    expect(find.text('Sobre o app'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows reports tab with monthly summary', (tester) async {
    final account = await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    final category = await CategoryRepository(
      database,
    ).createCategory(name: 'Mercado', type: 'expense');
    await TransactionRepository(database).createTransaction(
      type: 'expense',
      amountCents: 2500,
      description: 'Compra',
      date: DateTime.now(),
      sourceAccountId: account.id,
      categoryId: category.id,
    );

    await pumpMindCashApp(tester);

    await tester.tap(find.text('Mais').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Relatórios'));
    await tester.pumpAndSettle();

    expect(find.text('Resumo mensal'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
  });

  testWidgets('shows backup tab and exports JSON', (tester) async {
    await pumpMindCashApp(tester);

    await tester.tap(find.text('Mais').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();

    expect(find.text('Exportar JSON'), findsOneWidget);
    expect(find.text('Importar JSON'), findsOneWidget);

    await tester.tap(find.text('Gerar').first);
    await tester.pumpAndSettle();

    expect(find.text('Backup JSON'), findsWidgets);
    expect(find.textContaining('backupVersion'), findsOneWidget);
  });
}
