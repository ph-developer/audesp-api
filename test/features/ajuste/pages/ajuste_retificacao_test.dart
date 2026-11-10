import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/ajustes_dao.dart';
import 'package:audesp_api/core/database/daos/api_logs_dao.dart';
import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/daos/editais_dao.dart';
import 'package:audesp_api/core/database/daos/licitacoes_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/features/ajuste/pages/ajuste_form_page.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:audesp_api/shared/widgets/audesp_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../processo/processo_fixtures.dart';

const _base = 'https://audesp.tce.sp.gov.br';

String _documento({required bool retificacao, required String objeto}) =>
    jsonEncode({
      'descritor': {
        'municipio': 1,
        'entidade': 2,
        'codigoEdital': 'edital-1',
        'codigoContrato': 'ajuste-21',
        'retificacao': retificacao,
      },
      'objetoContrato': objeto,
    });

final _armazenado = _documento(retificacao: false, objeto: 'Versão armazenada');

class _AjustesMemoria implements AjustesDao {
  Ajuste atual;
  String? retificacaoIniciada;
  ({String documentoJson, bool retificacao})? descarte;
  final salvos = <({bool retificacao, String status, String documentoJson})>[];

  _AjustesMemoria(this.atual);

  Ajuste _com({
    required String status,
    required bool retificacao,
    required String documentoJson,
  }) => Ajuste.fromMap({
    ...atual.toMap(),
    'status': status,
    'retificacao': retificacao ? 1 : 0,
    'documento_json': documentoJson,
  });

  @override
  Future<Ajuste?> findById(int id) async => atual;

  @override
  Future<void> iniciarRetificacao(int id, String documentoJson) async {
    retificacaoIniciada = documentoJson;
    atual = _com(
      status: 'draft',
      retificacao: true,
      documentoJson: documentoJson,
    );
  }

  @override
  Future<void> descartarRetificacao(
    int id, {
    required String documentoJson,
    required bool retificacao,
  }) async {
    descarte = (documentoJson: documentoJson, retificacao: retificacao);
  }

  @override
  Future<bool> updateAjuste({
    required int id,
    required int? editalId,
    int? ataId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    String? codigoAta,
    required String codigoContrato,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    salvos.add((
      retificacao: retificacao,
      status: status,
      documentoJson: documentoJson,
    ));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EditaisMemoria implements EditaisDao {
  final Processo processo;
  _EditaisMemoria(this.processo);

  @override
  Future<Edital?> findById(int id) async => processo.edital;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LicitacoesMemoria implements LicitacoesDao {
  final Processo processo;
  _LicitacoesMemoria(this.processo);

  @override
  Future<List<Licitacao>> watchByEdital(int editalId) async =>
      processo.licitacoes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SettingsMemoria implements AppSettingsDao {
  @override
  Future<String?> get(String key) async => switch (key) {
    SettingsKeys.codigoMunicipio => '1',
    SettingsKeys.codigoEntidade => '2',
    SettingsKeys.codigoTipoOrgao => '1',
    _ => null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LogsMemoria implements ApiLogsDao {
  final Map<int, ApiLog> logs;
  _LogsMemoria(this.logs);

  @override
  Future<ApiLog?> findById(int id) async => logs[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EnvioResumo _envio(int id, String status, {bool retificacao = false}) =>
    EnvioResumo(
      id: id,
      statusCode: 200,
      protocolo: 'P$id',
      statusProtocolo: status,
      timestamp: DateTime(2026, 11, id),
      descritor: {
        'municipio': 1,
        'entidade': 2,
        'codigoEdital': 'edital-1',
        'codigoContrato': 'ajuste-21',
        'retificacao': retificacao,
      },
      endpoint: '$_base/recepcao-fase-4/f4/enviar-ajuste',
    );

ApiLog _log(EnvioResumo envio, String request) => ApiLog(
  id: envio.id,
  endpoint: envio.endpoint,
  request: request,
  statusCode: 200,
  timestamp: envio.timestamp,
  protocolo: envio.protocolo,
  statusProtocolo: envio.statusProtocolo,
);

Future<_AjustesMemoria> _pump(
  WidgetTester tester, {
  required String status,
  required bool retificacao,
  required String documentoJson,
  required List<EnvioResumo> envios,
  required Map<int, ApiLog> logs,
}) async {
  final ajuste = Ajuste.fromMap({
    ...ajusteFixture(21, status: status).toMap(),
    'retificacao': retificacao ? 1 : 0,
    'documento_json': documentoJson,
  });
  final dao = _AjustesMemoria(ajuste);
  final processo = processoFixture(
    licitacoes: [licitacaoFixture(1, status: 'sent')],
    ajustes: [ajuste],
  );
  final router = GoRouter(
    initialLocation: '/ajuste/21',
    routes: [
      GoRoute(
        path: '/ajuste',
        builder: (_, _) => const Scaffold(body: Text('Lista de ajustes')),
      ),
      GoRoute(
        path: '/ajuste/21',
        builder: (_, _) => const AjusteFormPage(ajusteId: 21),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.binding.setSurfaceSize(const Size(1800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ajustesDaoProvider.overrideWithValue(dao),
        editaisDaoProvider.overrideWithValue(_EditaisMemoria(processo)),
        licitacoesDaoProvider.overrideWithValue(_LicitacoesMemoria(processo)),
        appSettingsDaoProvider.overrideWithValue(_SettingsMemoria()),
        apiLogsDaoProvider.overrideWithValue(_LogsMemoria(logs)),
        processosProvider.overrideWith((ref) async => [processo]),
        enviosProcessoProvider.overrideWith(
          (ref) async =>
              EnviosProcesso(baseUrl: _base, ajustes: EnviosIndex(envios)),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return dao;
}

TextField _campo(WidgetTester tester, String label) => tester.widget<TextField>(
  find.descendant(
    of: find.byWidgetPredicate((w) => w is AudespTextField && w.label == label),
    matching: find.byType(TextField),
  ),
);

CheckboxListTile _caixaRetificacao(WidgetTester tester) =>
    tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Retificação'),
    );

void main() {
  testWidgets('armazenado: Retificar volta a rascunho como retificação', (
    tester,
  ) async {
    final envio = _envio(1, 'Armazenado');
    final dao = await _pump(
      tester,
      status: 'sent',
      retificacao: false,
      documentoJson: _armazenado,
      envios: [envio],
      logs: {1: _log(envio, _armazenado)},
    );
    expect(find.text('Armazenado'), findsOneWidget);
    expect(find.text('Descartar retificação'), findsNothing);
    expect(_caixaRetificacao(tester).value, isFalse);

    await tester.tap(find.text('Retificar'));
    await tester.pumpAndSettle();
    expect(find.text('Retificar ajuste?'), findsOneWidget);
    expect(find.textContaining('protocolo P1'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Retificar'));
    await tester.pumpAndSettle();

    final iniciado = jsonDecode(dao.retificacaoIniciada!) as Map;
    expect(iniciado['descritor']['retificacao'], isTrue);
    expect(iniciado['objetoContrato'], 'Versão armazenada');
    expect(find.text('Retificar Ajuste'), findsOneWidget);
    expect(find.text('Descartar retificação'), findsOneWidget);
    // A caixa fica marcada e travada; o código do contrato não muda.
    final caixa = _caixaRetificacao(tester);
    expect(caixa.value, isTrue);
    expect(caixa.onChanged, isNull);
    expect(_campo(tester, 'Código do Contrato (Sem PNCP) *').readOnly, isTrue);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar Rascunho'));
    await tester.pumpAndSettle();
    expect(dao.salvos.single.retificacao, isTrue);
    expect(dao.salvos.single.status, 'draft');
    expect(
      (jsonDecode(dao.salvos.single.documentoJson)
          as Map)['descritor']['retificacao'],
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rascunho em retificação: descartar restaura o envio armazenado',
    (tester) async {
      final envio = _envio(1, 'Armazenado');
      final dao = await _pump(
        tester,
        status: 'draft',
        retificacao: true,
        documentoJson: _documento(retificacao: true, objeto: 'Alterado'),
        envios: [envio],
        logs: {1: _log(envio, _armazenado)},
      );
      expect(find.text('Retificar Ajuste'), findsOneWidget);

      await tester.tap(find.text('Descartar retificação'));
      await tester.pumpAndSettle();
      expect(find.text('Descartar retificação?'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Descartar retificação'),
      );
      await tester.pumpAndSettle();

      expect(dao.descarte?.documentoJson, _armazenado);
      expect(dao.descarte?.retificacao, isFalse);
      expect(find.text('Lista de ajustes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('retificação rejeitada: mostra o protocolo dela e as saídas', (
    tester,
  ) async {
    final armazenado = _envio(1, 'Armazenado');
    final rejeitada = _envio(2, 'Rejeitado', retificacao: true);
    final enviado = _documento(retificacao: true, objeto: 'Alterado');
    await _pump(
      tester,
      status: 'sent',
      retificacao: true,
      documentoJson: enviado,
      envios: [rejeitada, armazenado],
      logs: {1: _log(armazenado, _armazenado), 2: _log(rejeitada, enviado)},
    );
    expect(find.text('Rejeitado'), findsOneWidget);
    expect(find.text('Retornar para rascunho'), findsOneWidget);
    expect(find.text('Descartar retificação'), findsOneWidget);
    expect(find.text('Retificar'), findsNothing);
  });

  testWidgets('original rejeitado volta a rascunho como original', (
    tester,
  ) async {
    final rejeitado = _envio(1, 'Rejeitado');
    await _pump(
      tester,
      status: 'draft',
      retificacao: true,
      documentoJson: _documento(retificacao: true, objeto: 'Corrigido'),
      envios: [rejeitado],
      logs: {1: _log(rejeitado, _armazenado)},
    );
    expect(find.text('Editar Ajuste'), findsOneWidget);
    expect(find.text('Descartar retificação'), findsNothing);
    final caixa = _caixaRetificacao(tester);
    expect(caixa.value, isFalse);
    expect(caixa.onChanged, isNull);
    expect(_campo(tester, 'Código do Contrato (Sem PNCP) *').readOnly, isFalse);
  });
}
