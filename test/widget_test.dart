import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/presentation/app/mindcash_app.dart';

void main() {
  testWidgets('shows the MindCash app shell', (tester) async {
    await tester.pumpWidget(const MindCashApp());
    await tester.pump();

    expect(find.text('Olá, DevBatista'), findsOneWidget);
    expect(find.text('Saldo total'), findsOneWidget);
    expect(find.text('R\$ 25.430,80'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('navigates between main sections', (tester) async {
    await tester.pumpWidget(const MindCashApp());
    await tester.pump();

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma transação cadastrada'), findsOneWidget);
  });
}
