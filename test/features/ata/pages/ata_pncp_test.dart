import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/daos/atas_dao.dart';
import 'package:audesp_api/core/database/daos/licitacoes_dao.dart';
import 'package:audesp_api/core/database/daos/pncp_atas_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/core/theme/app_theme.dart';
import 'package:audesp_api/features/ata/pages/ata_form_page.dart';
import 'package:audesp_api/features/ata/pages/ata_page.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:audesp_api/features/pendencias/pendencias_providers.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/pncp/services/pncp_service.dart';
import 'package:audesp_api/features/pncp/widgets/pncp_ata_card.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/domain/ufesp_rules.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:audesp_api/shared/widgets/audesp_date_picker_field.dart';
import 'package:audesp_api/shared/widgets/audesp_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../pncp/pncp_ata_fixtures.dart';
import '../../processo/processo_fixtures.dart';

class _AtasPncp implements PncpAtasDao {
  List<PncpAta> atas;
  int? dispensadaPor;
  String? motivo;
  int atualizacoes = 0;
  _AtasPncp(this.atas);
  @override
  Future<List<PncpAta>> listAll() async => atas;
  @override
  Future<PncpAta?> findById(int id) async =>
      atas.where((a) => a.id == id).firstOrNull;
  @override
  Future<bool> upsert(PncpAta ata) async {
    atualizacoes++;
    final anterior = atas
        .where((a) => a.numeroControle == ata.numeroControle)
        .firstOrNull;
    atas = [
      for (final a in atas)
        if (a.numeroControle != ata.numeroControle) a,
      ataPncpSalva(
        ata,
        id: anterior?.id ?? 9,
        dispensada: anterior?.dispensada ?? false,
      ),
    ];
    return anterior == null;
  }

  @override
  Future<void> dispensar(int id, {int? userId, String? motivo}) async {
    dispensadaPor = userId;
    this.motivo = motivo;
    atas = [
      for (final a in atas)
        a.id == id ? ataPncpSalva(a, id: id, dispensada: true) : a,
    ];
  }

  @override
  Future<void> restaurar(int id) async {
    atas = [for (final a in atas) a.id == id ? ataPncpSalva(a, id: id) : a];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servico extends PncpService {
  Map<String, dynamic>? resposta;
  final chamadas = <(String, int, int, int)>[];
  @override
  Future<Map<String, dynamic>> consultarAta(
    String cnpj,
    int ano,
    int compra,
    int ata,
  ) async {
    chamadas.add((cnpj, ano, compra, ata));
    if (resposta == null) throw const PncpException('Sem conexão');
    return resposta!;
  }
}

class _Atas implements AtasDao {
  final List<Ata> atas;
  _Atas(this.atas);
  @override
  Future<int> insertAta({
    required int editalId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required String codigoAta,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    atas.add(
      Ata(
        id: 9,
        editalId: editalId,
        municipio: municipio,
        entidade: entidade,
        codigoEdital: codigoEdital,
        codigoAta: codigoAta,
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
    _AtasPncp pncp,
    _Atas locais,
    _Servico servico,
  })
>
_pump(
  WidgetTester tester, {
  List<PncpAta>? atas,
  List<Processo>? processos,
  List<Ata> locais = const [],
  _Servico? servico,
  String initialLocation = '/ata',
  int permissao = AppPermissions.ata,
}) async {
  await tester.binding.setSurfaceSize(const Size(1800, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final ps =
      processos ??
      [
        processoFixture(
          codigo: '49576416000141-1-000001/2026',
          semPncp: false,
          srp: true,
          licitacoes: [licitacaoFixture(1, status: 'sent')],
        ),
      ];
  final pncp = _AtasPncp(atas ?? [ataPncpFixture()]);
  final dao = _Atas([...locais]);
  final service = servico ?? _Servico();
  final container = ProviderContainer(
    overrides: [
      pncpAtasDaoProvider.overrideWithValue(pncp),
      atasDaoProvider.overrideWithValue(dao),
      pncpServiceProvider.overrideWithValue(service),
      appSettingsDaoProvider.overrideWithValue(_Settings()),
      licitacoesDaoProvider.overrideWithValue(
        _Licitacoes(ps.expand((p) => p.licitacoes).toList()),
      ),
      documentosProcessoProvider.overrideWith(
        (ref) async => DocumentosProcesso(
          editais: ps.map((p) => p.edital),
          licitacoes: ps.expand((p) => p.licitacoes),
          atas: dao.atas,
        ),
      ),
      enviosProcessoProvider.overrideWith((ref) async => EnviosProcesso.vazio),
      processosProvider.overrideWith((ref) async {
        final docs = await ref.watch(documentosProcessoProvider.future);
        return Processo.agrupar(
          editais: docs.editais,
          licitacoes: docs.licitacoes,
          atas: docs.atas,
          ajustes: [],
        );
      }),
      pncpConfigProvider.overrideWith(
        (ref) async => const PncpConfig(cnpj: '49576416000141'),
      ),
      pncpComprasProvider.overrideWith((ref) async => const []),
      pncpContratosProvider.overrideWith((ref) async => const []),
      ufespConfigProvider.overrideWith((ref) async => const UfespConfig()),
      enviosProvider.overrideWith((ref, endpoint) async => EnviosIndex.vazio),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(localSessionProvider.notifier)
      .login(usuarioFixture(permissions: permissao));
  final sub = container.listen(pendenciasContagemProvider, (_, _) {});
  addTearDown(sub.close);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/ata', builder: (_, _) => const AtaPage()),
      GoRoute(
        path: '/ata/new',
        builder: (_, state) => AtaFormPage(
          pncpAtaId: int.tryParse(state.uri.queryParameters['pncpAtaId'] ?? ''),
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
    pncp: pncp,
    locais: dao,
    servico: service,
  );
}

Finder _campo(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AudespTextField && w.label == label),
  matching: find.byType(TextField),
);

void main() {
  testWidgets(
    'aba ordena liberadas antes das bloqueadas, filtra e abre a rota PNCP',
    (tester) async {
      final app = await _pump(
        tester,
        atas: [
          ataPncpFixture(
            id: 2,
            alteracoes: {
              ...ataPncpJson(sequencialCompra: 2),
              'numeroAtaRegistroPreco': '73',
            },
          ),
          ataPncpFixture(),
        ],
      );
      expect(find.byTooltip('Consultar PNCP'), findsOneWidget);
      expect(
        tester
            .widgetList<PncpAtaCard>(find.byType(PncpAtaCard))
            .map((w) => w.pendencia.ata.id),
        [1, 2],
      );
      expect(
        find.text(
          'Bloqueada: O edital desta compra ainda não está no sistema.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lançar ata'), findsOneWidget);
      expect(
        find.byTooltip('https://pncp.gov.br/app/atas/49576416000141/2026/1/1'),
        findsOneWidget,
      );
      expect(find.text('Compra: 49576416000141-1-000001/2026'), findsOneWidget);
      expect(
        (await app.container.read(pendenciasContagemProvider.future))['/ata'],
        1,
      );
      await tester.enterText(_campo('Filtrar'), '73/2026');
      await tester.pumpAndSettle();
      expect(find.byType(PncpAtaCard), findsOneWidget);
      expect(find.text('Lançar ata'), findsNothing);
      expect(
        (await app.container.read(pendenciasContagemProvider.future))['/ata'],
        1,
      );
      await tester.enterText(_campo('Filtrar'), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lançar ata'));
      await tester.pumpAndSettle();
      expect(
        app.router.routeInformationProvider.value.uri.toString(),
        '/ata/new?pncpAtaId=1',
      );
      expect(app.servico.chamadas, [('49576416000141', 2026, 1, 1)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dispensa com motivo e restaura, sem contar dispensadas no badge',
    (tester) async {
      final app = await _pump(tester);
      await tester.tap(find.text('Dispensar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _campo('Motivo (opcional)'),
        'Enviada anteriormente',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Dispensar'));
      await tester.pumpAndSettle();
      expect(app.pncp.dispensadaPor, 1);
      expect(app.pncp.motivo, 'Enviada anteriormente');
      expect(find.byType(PncpAtaCard), findsNothing);
      expect(
        (await app.container.read(pendenciasContagemProvider.future))['/ata'],
        0,
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.byType(PncpAtaCard), findsOneWidget);
      expect(find.text('Lançar ata'), findsNothing);
      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();
      expect(
        (await app.container.read(pendenciasContagemProvider.future))['/ata'],
        1,
      );
      expect(find.text('Lançar ata'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelada dispensada continua restaurável e desaparece ao restaurar',
    (tester) async {
      final app = await _pump(
        tester,
        atas: [
          ataPncpFixture(dispensada: true, alteracoes: {'cancelado': true}),
        ],
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(
        find.text('Bloqueada: A ata foi cancelada no PNCP.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();
      expect(find.byType(PncpAtaCard), findsNothing);
      expect(
        (await app.container.read(pendenciasContagemProvider.future))['/ata'],
        0,
      );
    },
  );

  testWidgets(
    'formulário atualiza detalhe, vincula edital e salva cabeçalho sem itens',
    (tester) async {
      final servico = _Servico()
        ..resposta = {
          ...ataPncpJson(),
          'numeroAtaRegistroPreco': '74',
          'dataVigenciaFim': '2027-03-01',
        };
      final app = await _pump(
        tester,
        servico: servico,
        initialLocation: '/ata/new?pncpAtaId=1',
      );
      expect(app.pncp.atualizacoes, 1);
      expect((await app.pncp.findById(1))!.numeroAta, '74');
      expect(
        tester.widget<TextField>(_campo('Número da Ata *')).controller!.text,
        '74',
      );
      final fim = tester.widget<AudespDatePickerField>(
        find.byWidgetPredicate(
          (w) => w is AudespDatePickerField && w.label == 'Fim de Vigência *',
        ),
      );
      expect(fim.value, DateTime(2027, 3, 1));
      await tester.tap(find.text('Salvar Rascunho'));
      await tester.pumpAndSettle();
      final salvo = app.locais.atas.single;
      expect(salvo.editalId, 1);
      expect(salvo.codigoAta, '4957641600014110000012026000001');
      expect(salvo.codigoEdital, '49576416000141-1-000001/2026');
      final json = jsonDecode(salvo.documentoJson);
      expect(json['numeroItem'], isEmpty);
      expect(json['numeroAtaRegistroPreco'], '74');
      expect(json['dataVigenciaFim'], '2027-03-01');
      expect(json['descritor']['anoCompra'], 2026);
      expect(json['descritor']['retificacao'], isFalse);
      expect(
        (await app.container.read(pendenciasContagemProvider.future))['/ata'],
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('falha na rede usa os dados salvos para lançar ata', (
    tester,
  ) async {
    final app = await _pump(tester, initialLocation: '/ata/new?pncpAtaId=1');
    expect(app.pncp.atualizacoes, 0);
    expect(app.servico.chamadas, hasLength(1));
    await tester.tap(find.text('Salvar Rascunho'));
    await tester.pumpAndSettle();
    expect(
      jsonDecode(
        app.locais.atas.single.documentoJson,
      )['numeroAtaRegistroPreco'],
      '72',
    );
    expect(tester.takeException(), isNull);
  });

  for (final situacao in ['bloqueada', 'dispensada', 'lançada', 'cancelada']) {
    testWidgets('rota antiga revalida ata $situacao e não preenche', (
      tester,
    ) async {
      final servico = _Servico()
        ..resposta = {...ataPncpJson(), 'cancelado': situacao == 'cancelada'};
      final app = await _pump(
        tester,
        atas: [ataPncpFixture(dispensada: situacao == 'dispensada')],
        processos: situacao == 'bloqueada' ? [] : null,
        locais: situacao == 'lançada'
            ? [ataFixture(8, codigo: '49576416000141-1-000001/2026-000001')]
            : [],
        servico: servico,
        initialLocation: '/ata/new?pncpAtaId=1',
      );
      expect(
        tester.widget<TextField>(_campo('Número da Ata *')).controller!.text,
        isEmpty,
      );
      expect(
        find.text(
          situacao == 'bloqueada'
              ? 'O edital desta compra ainda não está no sistema.'
              : situacao == 'cancelada'
              ? 'A ata foi cancelada no PNCP.'
              : 'Esta ata já foi lançada, foi dispensada ou não está nas pendências de Ata.',
        ),
        findsOneWidget,
      );
      expect(app.pncp.atualizacoes, 1);
      if (situacao == 'dispensada') {
        expect(app.pncp.atas.single.dispensada, isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('sem permissão de Ata não mostra consulta nem pendências PNCP', (
    tester,
  ) async {
    final app = await _pump(tester, permissao: AppPermissions.licitacao);
    expect(find.byTooltip('Consultar PNCP'), findsNothing);
    expect(find.byType(PncpAtaCard), findsNothing);
    expect(
      (await app.container.read(pendenciasContagemProvider.future))['/ata'],
      0,
    );
  });
}
