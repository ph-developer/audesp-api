import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/ajustes_dao.dart';
import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/daos/licitacoes_dao.dart';
import 'package:audesp_api/core/database/daos/pncp_contratos_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/core/theme/app_theme.dart';
import 'package:audesp_api/features/ajuste/pages/ajuste_form_page.dart';
import 'package:audesp_api/features/ajuste/pages/ajuste_page.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:audesp_api/features/pendencias/pendencias_providers.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/pncp/widgets/pncp_contrato_card.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/domain/ufesp_rules.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:audesp_api/shared/widgets/audesp_dropdown.dart';
import 'package:audesp_api/shared/widgets/audesp_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../pncp/pncp_fixtures.dart';
import '../../processo/processo_fixtures.dart';

class _Contratos implements PncpContratosDao {
  List<PncpContrato> contratos;
  int? dispensadoPor;
  String? motivo;
  _Contratos(this.contratos);

  @override
  Future<List<PncpContrato>> listAll() async => contratos;
  @override
  Future<PncpContrato?> findById(int id) async =>
      contratos.where((c) => c.id == id).firstOrNull;
  @override
  Future<void> dispensar(int id, {required int? userId, String? motivo}) async {
    dispensadoPor = userId;
    this.motivo = motivo;
    contratos = [
      for (final c in contratos)
        if (c.id == id)
          contratoPncpFixture(id: id, dispensado: true, alteracoes: c.dados)
        else
          c,
    ];
  }

  @override
  Future<void> restaurar(int id) async {
    contratos = [
      for (final c in contratos)
        if (c.id == id) contratoPncpFixture(id: id, alteracoes: c.dados) else c,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Ajustes implements AjustesDao {
  final ajustes = <Ajuste>[];
  @override
  Future<int> insertAjuste({
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
    ajustes.add(
      Ajuste(
        id: 9,
        editalId: editalId,
        ataId: ataId,
        municipio: municipio,
        entidade: entidade,
        codigoEdital: codigoEdital,
        codigoAta: codigoAta,
        codigoContrato: codigoContrato,
        retificacao: retificacao,
        status: status,
        documentoJson: documentoJson,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    return 9;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Licitacoes implements LicitacoesDao {
  final List<Licitacao> licitacoes;
  _Licitacoes(this.licitacoes);
  @override
  Future<List<Licitacao>> watchByEdital(int id) async =>
      licitacoes.where((l) => l.editalId == id).toList();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements AppSettingsDao {
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

Future<
  ({
    GoRouter router,
    ProviderContainer container,
    _Contratos contratos,
    _Ajustes ajustes,
  })
>
_pump(
  WidgetTester tester, {
  required List<PncpContrato> contratos,
  List<Processo>? processos,
  String initialLocation = '/ajuste',
}) async {
  await tester.binding.setSurfaceSize(const Size(1800, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final ps =
      processos ??
      [
        processoFixture(
          codigo: '46395000000139-1-000352/2025',
          semPncp: false,
          licitacoes: [licitacaoFixture(1, status: 'sent')],
        ),
      ];
  final dao = _Contratos(contratos);
  final ajustes = _Ajustes();
  final container = ProviderContainer(
    overrides: [
      pncpContratosDaoProvider.overrideWithValue(dao),
      ajustesDaoProvider.overrideWithValue(ajustes),
      appSettingsDaoProvider.overrideWithValue(_Settings()),
      licitacoesDaoProvider.overrideWithValue(
        _Licitacoes(ps.expand((p) => p.licitacoes).toList()),
      ),
      documentosProcessoProvider.overrideWith(
        (ref) async => DocumentosProcesso(
          editais: ps.map((p) => p.edital),
          licitacoes: ps.expand((p) => p.licitacoes),
          ajustes: ajustes.ajustes,
        ),
      ),
      enviosProcessoProvider.overrideWith((ref) async => EnviosProcesso.vazio),
      processosProvider.overrideWith((ref) async {
        final docs = await ref.watch(documentosProcessoProvider.future);
        return Processo.agrupar(
          editais: docs.editais,
          licitacoes: docs.licitacoes,
          atas: [],
          ajustes: docs.ajustes,
        );
      }),
      pncpConfigProvider.overrideWith(
        (ref) async => const PncpConfig(cnpj: '46395000000139'),
      ),
      ufespConfigProvider.overrideWith((ref) async => const UfespConfig()),
      enviosProvider.overrideWith((ref, endpoint) async => EnviosIndex.vazio),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(localSessionProvider.notifier)
      .login(usuarioFixture(permissions: AppPermissions.ajuste));
  final contagem = container.listen(pendenciasContagemProvider, (_, _) {});
  addTearDown(contagem.close);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/ajuste', builder: (_, _) => const AjustePage()),
      GoRoute(
        path: '/ajuste/new',
        builder: (_, state) => AjusteFormPage(
          pncpContratoId: int.tryParse(
            state.uri.queryParameters['pncpContratoId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/edital/:id',
        builder: (_, state) => Scaffold(body: Text('${state.uri}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (
    router: router,
    container: container,
    contratos: dao,
    ajustes: ajustes,
  );
}

Finder _campo(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AudespTextField && w.label == label),
  matching: find.byType(TextField),
);

void main() {
  testWidgets(
    'aba ordena liberados antes dos bloqueados, busca e abre rota PNCP',
    (tester) async {
      final bloqueado = contratoPncpFixture(
        id: 2,
        alteracoes: {
          'numeroControlePNCP': '46395000000139-2-000003/2026',
          'sequencialContrato': 3,
          'numeroContratoEmpenho': '4',
          'numeroControlePncpCompra': null,
        },
      );
      final app = await _pump(
        tester,
        contratos: [bloqueado, contratoPncpFixture()],
      );
      expect(find.byTooltip('Consultar PNCP'), findsOneWidget);
      expect(
        tester
            .widgetList<PncpContratoCard>(find.byType(PncpContratoCard))
            .map((w) => w.pendencia.contrato.id),
        [1, 2],
      );
      expect(
        find.text('Bloqueado: O contrato não informa a compra no PNCP.'),
        findsOneWidget,
      );
      expect(find.text('Lançar ajuste'), findsOneWidget);
      expect(
        find.byTooltip(
          'https://pncp.gov.br/app/contratos/46395000000139/2026/2',
        ),
        findsOneWidget,
      );
      expect(
        (await app.container.read(
          pendenciasContagemProvider.future,
        ))['/ajuste'],
        1,
      );
      await tester.enterText(_campo('Filtrar'), '4/2026');
      await tester.pumpAndSettle();
      expect(find.text('Lançar ajuste'), findsNothing);
      expect(
        (await app.container.read(
          pendenciasContagemProvider.future,
        ))['/ajuste'],
        1,
      );
      await tester.enterText(_campo('Filtrar'), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lançar ajuste'));
      await tester.pumpAndSettle();
      expect(
        app.router.routeInformationProvider.value.uri.toString(),
        '/ajuste/new?pncpContratoId=1',
      );
      final dropdown = tester
          .widgetList<AudespDropdown<int?>>(find.byType(AudespDropdown<int?>))
          .singleWhere((w) => w.label == 'Edital *');
      expect(dropdown.value, 1);
      await tester.tap(find.text('Salvar Rascunho'));
      await tester.pumpAndSettle();
      final salvo = app.ajustes.ajustes.single;
      final doc = jsonDecode(salvo.documentoJson);
      expect(salvo.editalId, 1);
      expect(salvo.codigoContrato, '4639500000013920000022026');
      expect(doc['niFornecedor'], '24195949000152');
      expect(doc['valorGlobal'], 16200);
      expect(doc['dataVigenciaFim'], '2027-01-09');
      expect(doc['itens'], isEmpty);
      expect(doc['tipoObjetoContrato'], isNull);
      expect(
        (await app.container.read(
          pendenciasContagemProvider.future,
        ))['/ajuste'],
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final bloqueado in [false, true]) {
    testWidgets(
      'dispensa e restaura contrato, inclusive bloqueado ($bloqueado)',
      (tester) async {
        final contrato = contratoPncpFixture(
          alteracoes: {if (bloqueado) 'numeroControlePncpCompra': null},
        );
        final app = await _pump(tester, contratos: [contrato]);
        await tester.tap(find.text('Dispensar'));
        await tester.pumpAndSettle();
        await tester.enterText(
          _campo('Motivo (opcional)'),
          '  Já lançado em outro sistema  ',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Dispensar'));
        await tester.pumpAndSettle();
        expect(app.contratos.dispensadoPor, 1);
        expect(app.contratos.motivo, 'Já lançado em outro sistema');
        expect(find.byType(PncpContratoCard), findsNothing);
        expect(
          (await app.container.read(
            pendenciasContagemProvider.future,
          ))['/ajuste'],
          0,
        );
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(find.text('Restaurar'), findsOneWidget);
        expect(find.text('Lançar ajuste'), findsNothing);
        await tester.tap(find.text('Restaurar'));
        await tester.pumpAndSettle();
        expect(app.contratos.contratos.single.dispensado, isFalse);
        expect(
          (await app.container.read(
            pendenciasContagemProvider.future,
          ))['/ajuste'],
          bloqueado ? 0 : 1,
        );
        expect(
          find.text('Lançar ajuste'),
          bloqueado ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('compra de outro órgão abre adesão e salva sem edital local', (
    tester,
  ) async {
    final app = await _pump(
      tester,
      processos: [],
      contratos: [
        contratoPncpFixture(
          alteracoes: {
            'numeroControlePncpCompra': '49576416000141-1-000352/2025',
          },
        ),
      ],
      initialLocation: '/ajuste/new?pncpContratoId=1',
    );
    await tester.tap(find.text('Salvar Rascunho'));
    await tester.pumpAndSettle();
    final salvo = app.ajustes.ajustes.single;
    expect(salvo.editalId, isNull);
    expect(salvo.codigoEdital, '4957641600014110003522025');
    expect(
      jsonDecode(salvo.documentoJson)['descritor']['adesaoParticipacao'],
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rota antiga revalida contrato bloqueado antes de preencher', (
    tester,
  ) async {
    final app = await _pump(
      tester,
      contratos: [contratoPncpFixture()],
      processos: [],
      initialLocation: '/ajuste/new?pncpContratoId=1',
    );
    expect(
      find.text('O edital desta compra ainda não está no sistema.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Salvar Rascunho'));
    await tester.pumpAndSettle();
    expect(app.ajustes.ajustes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
