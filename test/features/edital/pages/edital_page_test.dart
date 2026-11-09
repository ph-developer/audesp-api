import 'dart:convert';

import 'package:audesp_api/core/database/models/edital.dart';
import 'package:audesp_api/core/theme/app_theme.dart';
import 'package:audesp_api/features/edital/edital_providers.dart';
import 'package:audesp_api/features/edital/pages/edital_page.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Edital _edital(int id, {required int modalidadeId, required String numero}) =>
    Edital(
      id: id,
      municipio: '1',
      entidade: '2',
      codigoEdital: 'edital-$id',
      retificacao: false,
      status: 'draft',
      documentoJson: jsonEncode({
        'modalidadeId': modalidadeId,
        'numeroCompra': numero,
        'anoCompra': 2026,
        'objetoCompra': 'Objeto $id',
      }),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026, 10, id),
    );

Future<void> _pump(WidgetTester tester, List<Edital> editais, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        editaisDraftProvider.overrideWith((ref) async => editais),
        editaisEnviadosProvider.overrideWith((ref) async => const []),
        enviosProvider.overrideWith((ref, _) async => EnviosIndex.vazio),
      ],
      child: MaterialApp(
        theme: AppTheme.light.copyWith(visualDensity: VisualDensity.compact),
        home: const EditalPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _escolher(WidgetTester tester, String campo, String opcao) async {
  await tester.tap(find.widgetWithText(InputDecorator, campo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcao).last);
  await tester.pumpAndSettle();
}

void main() {
  final editais = [
    _edital(1, modalidadeId: 6, numero: '9'),
    _edital(2, modalidadeId: 8, numero: '3'),
    _edital(3, modalidadeId: 6, numero: '10'),
  ];

  testWidgets('filtra por modalidade e ordena por licitação', (tester) async {
    await _pump(tester, editais, const Size(1600, 900));

    expect(find.textContaining('Objeto '), findsNWidgets(3));

    await _escolher(tester, 'Modalidade', 'Pregão Eletrônico');
    expect(find.text('Objeto 2'), findsNothing);
    expect(find.text('Objeto 1'), findsOneWidget);
    expect(find.text('Objeto 3'), findsOneWidget);

    await _escolher(tester, 'Ordenar por', 'Licitação');
    final y1 = tester.getTopLeft(find.text('Objeto 1')).dy;
    final y3 = tester.getTopLeft(find.text('Objeto 3')).dy;
    expect(y3, lessThan(y1), reason: 'PE 10 antes de PE 9 (decrescente)');

    await tester.tap(find.byTooltip('Decrescente'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Objeto 1')).dy,
      lessThan(tester.getTopLeft(find.text('Objeto 3')).dy),
    );

    await _escolher(tester, 'Modalidade', 'Inexigibilidade');
    expect(
      find.text('Nenhum resultado para os filtros selecionados'),
      findsOneWidget,
    );
  });

  testWidgets('barra de filtros não estoura em janela estreita', (
    tester,
  ) async {
    await _pump(tester, editais, const Size(900, 700));

    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.byTooltip('Atualizar')).dy,
      tester.getCenter(find.byTooltip('Decrescente')).dy,
      reason: 'Atualizar alinhado com os botões da barra',
    );
    expect(find.widgetWithText(InputDecorator, 'Ordenar por'), findsOneWidget);
  });
}
