import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/credit_card_repository.dart';
import 'package:mindcash_app/data/repositories/recurrence_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';
import 'package:mindcash_app/presentation/app/mindcash_app.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('shows the MindCash app shell', (tester) async {
    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

    expect(find.text('Olá, DevBatista'), findsOneWidget);
    expect(find.text('Saldo total'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsWidgets);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('navigates between main sections', (tester) async {
    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
  });

  testWidgets('opens new transaction route from action button', (tester) async {
    await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    await CategoryRepository(
      database,
    ).createCategory(name: 'Mercado', type: 'expense');

    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

    await tester.tap(find.byTooltip('Ocultar valores'));
    await tester.pump();

    expect(find.byTooltip('Mostrar valores'), findsOneWidget);
    expect(find.text('••••'), findsWidgets);
  });

  testWidgets('changes dashboard month from selector', (tester) async {
    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

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

    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();
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

    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

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
    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

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

    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

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
    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

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

    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

    await tester.tap(find.text('Mais').last);
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
}
