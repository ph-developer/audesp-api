import 'dart:convert';

import 'package:audesp_api/features/logs/widgets/erros_retornados_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _retorno = jsonEncode({
  'status': 'Rejeitado',
  'erros': [
    {
      'mensagem': 'Para este ajuste, deve ser informada a data de início.',
      'campo': 'datavigenciaInicio - vigenciaMeses',
      'codigoErro': 'RN012_AJUSTE',
    },
  ],
});

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  test('erros vêm do retorno; texto inválido ou sem erros é lista vazia', () {
    expect(errosRetornados(_retorno).single['codigoErro'], 'RN012_AJUSTE');
    expect(errosRetornados(null), isEmpty);
    expect(errosRetornados('inválido'), isEmpty);
    expect(errosRetornados('{"status": "Armazenado"}'), isEmpty);
    expect(errosRetornados('[]'), isEmpty);
  });

  testWidgets('rejeitado com erros abre a lista ao clicar', (tester) async {
    await _pump(
      tester,
      ProtocoloStatusChip(status: 'Rejeitado', retornoStatus: _retorno),
    );
    expect(find.byTooltip('Ver erros retornados'), findsOneWidget);
    await tester.tap(find.text('Rejeitado'));
    await tester.pumpAndSettle();
    expect(find.text('Erros Retornados'), findsOneWidget);
    expect(
      find.text(
        'Campo: datavigenciaInicio - vigenciaMeses | Código: RN012_AJUSTE',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sem erros o chip não é clicável', (tester) async {
    await _pump(tester, const ProtocoloStatusChip(status: 'Armazenado'));
    expect(find.text('Armazenado'), findsOneWidget);
    expect(find.byTooltip('Ver erros retornados'), findsNothing);
    await _pump(tester, const ProtocoloStatusChip());
    expect(find.text('Enviado'), findsOneWidget);
  });
}
