import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/ajuste/widgets/atas_para_ajuste_dialog.dart';
import 'package:audesp_api/features/edital/widgets/pcnp_input_formatter.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Processo _processo(
  int id, {
  bool srp = true,
  bool licitacaoEnviada = true,
  String ataStatus = 'sent',
  int ajustesVinculados = 0,
}) => Processo(
  edital: Edital(
    id: id,
    municipio: '1',
    entidade: '2',
    codigoEdital: 'edital-$id',
    retificacao: false,
    status: 'sent',
    documentoJson: jsonEncode({
      'srp': srp,
      'modalidadeId': 6,
      'numeroCompra': '$id',
      'anoCompra': 2026,
      'objetoCompra': 'Aquisição de materiais $id',
    }),
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
      status: licitacaoEnviada ? 'sent' : 'draft',
      documentoJson: '{}',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026, 10, 27),
    ),
  ],
  atas: [
    Ata(
      id: id,
      editalId: id,
      municipio: '1',
      entidade: '2',
      codigoEdital: 'edital-$id',
      codigoAta: '1234567800019910000012026${id.toString().padLeft(6, '0')}',
      retificacao: false,
      status: ataStatus,
      documentoJson: jsonEncode({
        'numeroAtaRegistroPreco': '$id',
        'anoAta': 2026,
      }),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026, 10, 27),
    ),
  ],
  ajustes: [
    for (var i = 0; i < ajustesVinculados; i++)
      Ajuste(
        id: id * 10 + i,
        editalId: id,
        ataId: id,
        municipio: '1',
        entidade: '2',
        codigoEdital: 'edital-$id',
        codigoContrato: 'ajuste-$id-$i',
        retificacao: false,
        status: i.isEven ? 'draft' : 'sent',
        documentoJson: '{}',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 10, 27),
      ),
  ],
);

Future<void> _abrirDialogo(
  WidgetTester tester,
  List<Processo> processos, {
  ValueChanged<Ata?>? onSelected,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [processosProvider.overrideWith((ref) async => processos)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final ata = await showAtasParaAjusteDialog(context: context);
                onSelected?.call(ata);
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
}

Finder _tile(Ata ata) => find.widgetWithText(
  ListTile,
  '${PcnpInputFormatter.applyMask(ata.codigoAta)} - Ata ${ata.numeroAtaRegistroPreco}/${ata.anoAta}',
);

void main() {
  final processos = [
    _processo(1),
    _processo(2, ajustesVinculados: 2),
    _processo(3, licitacaoEnviada: false),
    _processo(4, ataStatus: 'draft'),
    _processo(5, srp: false),
    _processo(6, licitacaoEnviada: false, ajustesVinculados: 1),
  ];

  testWidgets('filtros padrão exibem só atas liberadas sem ajuste', (
    tester,
  ) async {
    await _abrirDialogo(tester, processos);

    expect(find.byType(ListTile), findsOneWidget);
    expect(_tile(processos.first.atas.single), findsOneWidget);
    for (final processo in processos.skip(1)) {
      expect(_tile(processo.atas.single), findsNothing);
    }
    expect(
      find.textContaining('${processos.first.edital.modalidadeLabel} 1/2026'),
      findsOneWidget,
    );
    expect(find.textContaining('Aquisição de materiais 1'), findsOneWidget);
    expect(
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .every((c) => !c.value!),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exibir já vinculadas permite outro ajuste e mostra contagem', (
    tester,
  ) async {
    Ata? selecionada;
    await _abrirDialogo(
      tester,
      processos,
      onSelected: (ata) => selecionada = ata,
    );

    await tester.tap(find.text('Exibir já vinculadas'));
    await tester.pumpAndSettle();

    final ata = processos[1].atas.single;
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('2 ajustes'), findsOneWidget);
    expect(tester.widget<ListTile>(_tile(ata)).enabled, isTrue);
    await tester.tap(_tile(ata));
    await tester.pumpAndSettle();

    expect(selecionada, same(ata));
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mostrar bloqueadas exibe o motivo e impede seleção', (
    tester,
  ) async {
    Ata? selecionada;
    await _abrirDialogo(
      tester,
      processos,
      onSelected: (ata) => selecionada = ata,
    );

    await tester.tap(find.text('Mostrar bloqueadas'));
    await tester.pumpAndSettle();
    final bloqueada = _tile(processos[2].atas.single);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.widget<ListTile>(bloqueada).enabled, isFalse);
    expect(tester.widget<ListTile>(bloqueada).onTap, isNull);
    expect(
      find.textContaining('A licitação do edital ainda não foi enviada'),
      findsOneWidget,
    );
    await tester.tap(bloqueada);
    await tester.pumpAndSettle();
    expect(selecionada, isNull);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Exibir já vinculadas'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(4));
    expect(find.text('1 ajuste'), findsOneWidget);
    expect(find.text('2 ajustes'), findsOneWidget);
    final bloqueadaVinculada = _tile(processos[5].atas.single);
    expect(tester.widget<ListTile>(bloqueadaVinculada).enabled, isFalse);
    expect(tester.widget<ListTile>(bloqueadaVinculada).onTap, isNull);
    expect(_tile(processos[3].atas.single), findsNothing);
    expect(_tile(processos[4].atas.single), findsNothing);

    await tester.tap(find.text('Mostrar bloqueadas'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.tap(find.text('Exibir já vinculadas'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busca por código da ata e objeto respeita os filtros', (
    tester,
  ) async {
    await _abrirDialogo(tester, processos);
    final ata = processos[1].atas.single;
    final campoBusca = find.byType(TextField);

    await tester.enterText(campoBusca, ata.codigoAta);
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma ata para este filtro.'), findsOneWidget);

    await tester.tap(find.text('Exibir já vinculadas'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(_tile(ata), findsOneWidget);

    for (final query in [
      PcnpInputFormatter.applyMask(ata.codigoAta),
      'aquisicao % materiais 2',
      '2/2026',
    ]) {
      await tester.enterText(campoBusca, query);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(_tile(ata), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Limpar filtro'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
