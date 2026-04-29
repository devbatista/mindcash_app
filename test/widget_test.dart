import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/presentation/app/mindcash_app.dart';

void main() {
  testWidgets('shows the MindCash app shell', (tester) async {
    await tester.pumpWidget(const MindCashApp());

    expect(find.text('Dashboard'), findsNWidgets(2));
    expect(
      find.text('Seu resumo financeiro vai aparecer aqui'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('navigates between main sections', (tester) async {
    await tester.pumpWidget(const MindCashApp());

    await tester.tap(find.text('Transacoes'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma transacao cadastrada'), findsOneWidget);
  });
}
