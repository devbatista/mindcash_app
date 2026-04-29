import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
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

    expect(find.text('Nenhuma transação cadastrada'), findsOneWidget);
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
}
