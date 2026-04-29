import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
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
    await tester.pumpWidget(MindCashApp(database: database));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nova transação'), findsWidgets);
    expect(
      find.text('O formulário será implementado no próximo bloco.'),
      findsOneWidget,
    );
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
}
