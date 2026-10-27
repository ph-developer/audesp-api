import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/edital/widgets/unlinked_editais_dialog.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Processo _processo(
  int id, {
  required bool srp,
  bool enviada = false,
  String status = 'sent',
}) => Processo(
  edital: Edital(
    id: id,
    municipio: '1',
    entidade: '2',
    codigoEdital: 'edital-$id',
    retificacao: false,
    status: status,
    documentoJson: jsonEncode({'srp': srp, 'objetoCompra': 'Objeto $id'}),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026, 10, 27),
  ),
  licitacoes: [
    Licitacao(
      id: id,
      editalId: id,
      municipio: '1',
      entidade: '2',
      codigoEdital: 'edital-$id',
      retificacao: false,
      status: enviada ? 'sent' : 'draft',
      documentoJson: '{}',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026, 10, 27),
    ),
  ],
  atas: [],
  ajustes: [],
);

void main() {
  final processos = [
    _processo(1, srp: true, enviada: true),
    _processo(2, srp: true),
    _processo(3, srp: false, enviada: true),
    _processo(4, srp: false),
    _processo(5, srp: true, enviada: true, status: 'draft'),
    _processo(6, srp: false, enviada: true, status: 'draft'),
  ];

  for (final target in [
    UnlinkedEditaisTarget.ata,
    UnlinkedEditaisTarget.ajuste,
  ]) {
    test(
      'opções de $target mantêm o filtro SRP e o motivo de bloqueio',
      () async {
        final container = ProviderContainer(
          overrides: [processosProvider.overrideWith((ref) async => processos)],
        );
        addTearDown(container.dispose);

        final data = await container.read(
          unlinkedEditaisProvider(target).future,
        );
        final ids = target == UnlinkedEditaisTarget.ata ? [1, 2] : [3, 4];
        expect(data.editais.map((e) => e.id), ids);
        expect(data.linkedCounts, {for (final id in ids) id: 0});
        expect(data.motivosBloqueio, {
          ids.last: 'A licitação do edital ainda não foi enviada ao AUDESP.',
        });
      },
    );

    testWidgets('$target mostra bloqueados desabilitados e mantém os filtros', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final liberado = processos[target == UnlinkedEditaisTarget.ata ? 0 : 2];
      final bloqueado = processos[target == UnlinkedEditaisTarget.ata ? 1 : 3];
      Edital? selecionado;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unlinkedEditaisProvider(target).overrideWith(
              (ref) async => UnlinkedEditaisData(
                editais: [liberado.edital, bloqueado.edital],
                linkedCounts: {liberado.edital.id: 1, bloqueado.edital.id: 0},
                motivosBloqueio: {
                  bloqueado.edital.id:
                      'A licitação do edital ainda não foi enviada ao AUDESP.',
                },
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    selecionado = await showUnlinkedEditaisDialog(
                      context: context,
                      target: target,
                      title: 'Criar por Edital',
                      emptyMessage: 'Nenhum edital liberado.',
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);

      await tester.tap(find.text('Mostrar bloqueados'));
      await tester.pumpAndSettle();
      final tileBloqueado = tester.widget<ListTile>(find.byType(ListTile));
      expect(tileBloqueado.enabled, isFalse);
      expect(tileBloqueado.onTap, isNull);
      expect(
        find.textContaining('A licitação do edital ainda não foi enviada'),
        findsOneWidget,
      );
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(selecionado, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Exibir já enviados'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));
      await tester.tap(find.text('Mostrar bloqueados'));
      await tester.pumpAndSettle();
      final tileLiberado = tester.widget<ListTile>(find.byType(ListTile));
      expect(tileLiberado.enabled, isTrue);
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(selecionado, same(liberado.edital));
      expect(tester.takeException(), isNull);
    });
  }
}
