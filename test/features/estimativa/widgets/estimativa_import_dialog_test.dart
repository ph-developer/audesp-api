import 'package:audesp_api/features/edital/widgets/edital_import_csv_dialog.dart';
import 'package:audesp_api/features/estimativa/estimativa_providers.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_item_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:audesp_api/features/estimativa/widgets/estimativa_import_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

EstimativaModel _estimativa(int numero, {bool finalizada = false}) =>
    EstimativaModel(
      id: numero,
      numero: numero,
      ano: 2026,
      objeto: 'Objeto $numero',
      status: finalizada
          ? EstimativaStatus.finalizada
          : EstimativaStatus.rascunho,
      itens: [
        EstimativaItem(
          numero: 1,
          descricao: 'Material',
          unidade: 'UN',
          quantidade: 2,
        ),
      ],
    );

Future<void> _pumpDialog(
  WidgetTester tester, {
  required List<EstimativaModel> estimativas,
  required Future<void> Function(BuildContext context) abrir,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        estimativasListProvider.overrideWith((ref) async => estimativas),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => abrir(context),
              child: const Text('Abrir importação'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir importação'));
  await tester.pumpAndSettle();
}

void main() {
  for (final somenteFinalizadas in [true, false]) {
    testWidgets('somenteFinalizadas filtra a lista ($somenteFinalizadas)', (
      tester,
    ) async {
      final finalizada = _estimativa(2, finalizada: true);
      EstimativaModel? selecionada;
      await _pumpDialog(
        tester,
        estimativas: [_estimativa(1), finalizada],
        abrir: (context) async {
          selecionada = await showEstimativaImportDialog(
            context,
            somenteFinalizadas: somenteFinalizadas,
          );
        },
      );
      expect(
        find.text('Estimativa 1/2026 - Objeto 1'),
        somenteFinalizadas ? findsNothing : findsOneWidget,
      );
      expect(find.text('Estimativa 2/2026 - Objeto 2'), findsOneWidget);
      await tester.tap(find.text('Estimativa 2/2026 - Objeto 2'));
      await tester.pumpAndSettle();
      expect(selecionada, same(finalizada));
    });
  }

  testWidgets('sem finalizadas orienta finalizar antes de importar', (
    tester,
  ) async {
    await _pumpDialog(
      tester,
      estimativas: [_estimativa(1)],
      abrir: (context) async {
        await showEstimativaImportDialog(context, somenteFinalizadas: true);
      },
    );
    expect(
      find.text(
        'Nenhuma estimativa finalizada. Finalize a estimativa antes de importá-la.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('lista vazia mantém a mensagem padrão', (tester) async {
    await _pumpDialog(
      tester,
      estimativas: [],
      abrir: (context) async {
        await showEstimativaImportDialog(context);
      },
    );
    expect(find.text('Nenhuma estimativa encontrada.'), findsOneWidget);
  });

  testWidgets(
    'importação do edital escolhe só finalizadas e retorna origem e itens',
    (tester) async {
      EditalImportResult? resultado;
      await _pumpDialog(
        tester,
        estimativas: [_estimativa(1), _estimativa(2, finalizada: true)],
        abrir: (context) async {
          resultado = await showEditalImportCsvDialog(context);
        },
      );
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();
      expect(find.text('Estimativa 1/2026 - Objeto 1'), findsNothing);
      await tester.tap(find.text('Estimativa 2/2026 - Objeto 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar Importação'));
      await tester.pumpAndSettle();
      expect(resultado!.estimativaId, 2);
      expect(resultado!.itens.single['descricao'], 'Material');
      expect(resultado!.itens.single['quantidade'], 2);
    },
  );
}
