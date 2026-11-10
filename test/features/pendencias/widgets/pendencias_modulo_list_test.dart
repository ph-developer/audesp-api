import 'package:audesp_api/core/constants/environments.dart';
import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/api_logs_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/core/services/auth_service.dart';
import 'package:audesp_api/core/theme/app_theme.dart';
import 'package:audesp_api/features/ajuste/pages/ajuste_page.dart';
import 'package:audesp_api/features/ata/pages/ata_page.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/edital/pages/edital_page.dart';
import 'package:audesp_api/features/licitacao/pages/licitacao_page.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:audesp_api/features/logs/services/consulta_service.dart';
import 'package:audesp_api/features/pendencias/widgets/pendencia_protocolo_card.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/domain/ufesp_rules.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/json_http_adapter.dart';
import '../../processo/processo_fixtures.dart';
import '../pendencias_fixtures.dart';

class _Ambiente extends EnvironmentNotifier {
  @override
  Environment build() => Environment.piloto;
}

class _Consulta implements ConsultaService {
  final protocolos = <String>[];
  bool falhar = false;
  @override
  Future<String> consultarStatus(String protocolo) async {
    protocolos.add(protocolo);
    if (falhar) throw Exception('Sem conexão');
    return '{"status":"Armazenado"}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Logs implements ApiLogsDao {
  String situacao = 'Recebido';
  final atualizacoes = <(int, String, String)>[];
  @override
  Future<void> updateProtocoloInfo(int id, String status, String json) async {
    atualizacoes.add((id, status, json));
    situacao = status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String modulo,
  required DocumentosProcesso documentos,
  _Consulta? consulta,
  _Logs? logs,
  AuthService? auth,
  String? situacaoEdital,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final pagina = switch (modulo) {
    '/edital' => const EditalPage(),
    '/licitacao' => const LicitacaoPage(),
    '/ata' => const AtaPage(),
    _ => const AjustePage(),
  };
  final router = GoRouter(
    initialLocation: modulo,
    routes: [
      GoRoute(path: modulo, builder: (_, _) => pagina),
      GoRoute(
        path: '$modulo/:id',
        builder: (_, state) => Scaffold(body: Text('${state.uri}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWith(_Ambiente.new),
      documentosProcessoProvider.overrideWith((ref) async => documentos),
      enviosProvider.overrideWith((ref, endpoint) async {
        final Iterable<Object> docs = switch (endpoint) {
          EnviosEndpoint.edital => documentos.editais,
          EnviosEndpoint.licitacao => documentos.licitacoes,
          EnviosEndpoint.ata => documentos.atas,
          _ => documentos.ajustes,
        };
        return EnviosIndex([
          for (final doc in docs)
            envioFixture(
              doc,
              situacao: doc is Edital && situacaoEdital != null
                  ? situacaoEdital
                  : logs?.situacao ?? 'Recebido',
            ),
        ]);
      }),
      pncpComprasProvider.overrideWith((ref) async => const []),
      pncpConfigProvider.overrideWith((ref) async => const PncpConfig()),
      ufespConfigProvider.overrideWith((ref) async => const UfespConfig()),
      if (consulta != null) consultaServiceProvider.overrideWithValue(consulta),
      if (logs != null) apiLogsDaoProvider.overrideWithValue(logs),
      if (auth != null) authServiceProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(localSessionProvider.notifier)
      .login(usuarioFixture(isAdmin: true));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final modulo in ['/edital', '/licitacao', '/ata', '/ajuste']) {
    testWidgets('$modulo abre em Pendências, busca e abre o documento', (
      tester,
    ) async {
      final docs = DocumentosProcesso(
        editais: [processoFixture(valorTotal: 50000).edital],
        licitacoes: [licitacaoFixture(7)],
        atas: [
          ataFixture(
            8,
            documentoJson: '{"numeroAtaRegistroPreco":"8","anoAta":2026}',
          ),
        ],
        ajustes: [ajusteFixture(9, editalId: null)],
      );
      final router = await _pump(tester, modulo: modulo, documentos: docs);
      expect(
        tester
            .widget<SegmentedButton<String>>(
              find.byType(SegmentedButton<String>),
            )
            .selected,
        {'pendencias'},
      );
      expect(find.byType(PendenciaProtocoloCard), findsOneWidget);
      expect(find.text('Recebido'), findsOneWidget);
      expect(
        find.textContaining('ainda não foi armazenado pelo AUDESP'),
        findsOneWidget,
      );
      expect(find.byTooltip('Atualizar situação'), findsOneWidget);
      expect(find.text('Nova licitação'), findsNothing);
      if (modulo == '/edital') {
        expect(find.text('Envio não obrigatório'), findsOneWidget);
      }

      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();
      expect(find.byType(PendenciaProtocoloCard), findsNothing);
      await tester.tap(find.byTooltip('Limpar filtro'));
      await tester.pumpAndSettle();
      expect(find.byType(PendenciaProtocoloCard), findsOneWidget);
      await tester.tap(find.byTooltip('Abrir'));
      await tester.pumpAndSettle();
      final id = switch (modulo) {
        '/edital' => 1,
        '/licitacao' => 7,
        '/ata' => 8,
        _ => 9,
      };
      expect(router.routeInformationProvider.value.uri.path, '$modulo/$id');
    });
  }

  testWidgets(
    'licitação oferece criação por edital concluído, com UFESP e busca',
    (tester) async {
      final docs = DocumentosProcesso(
        editais: [processoFixture(valorTotal: 50000).edital],
      );
      final router = await _pump(
        tester,
        modulo: '/licitacao',
        documentos: docs,
        situacaoEdital: 'Armazenado',
      );
      expect(find.text('Nova licitação'), findsOneWidget);
      expect(find.text('Envio não obrigatório'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'pregao%1/2026');
      await tester.pumpAndSettle();
      expect(find.text('Nova licitação'), findsOneWidget);
      await tester.tap(find.text('Nova licitação'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/licitacao/new?editalId=1',
      );
    },
  );

  for (final token in [true, false]) {
    testWidgets(
      'atualiza situação ${token ? 'direto com token' : 'após autenticar'} e retira a pendência',
      (tester) async {
        final adapter = JsonHttpAdapter({
          'access_token': 'token-teste',
          'expire_in': 3600,
        });
        final dio = Dio()..httpClientAdapter = adapter;
        final auth = AuthService(dio: dio);
        addTearDown(() => dio.close(force: true));
        if (token) {
          await tester.runAsync(
            () => auth.loginAudesp(
              userId: 1,
              email: 'teste@example.com',
              password: 'senha',
              baseUrl: ambientePendencias,
            ),
          );
        }
        final consulta = _Consulta();
        final logs = _Logs();
        await _pump(
          tester,
          modulo: '/ajuste',
          documentos: DocumentosProcesso(
            ajustes: [ajusteFixture(9, editalId: null)],
          ),
          consulta: consulta,
          logs: logs,
          auth: auth,
        );
        await tester.tap(find.byTooltip('Atualizar situação'));
        await tester.pumpAndSettle();
        if (!token) {
          expect(find.text('Senha AUDESP'), findsOneWidget);
          expect(consulta.protocolos, isEmpty);
          await tester.enterText(find.byType(TextField).last, 'senha');
          await tester.tap(find.text('Autenticar e Atualizar'));
          await tester.pumpAndSettle();
        }
        expect(find.byType(AlertDialog), findsNothing);
        expect(consulta.protocolos, ['P1']);
        expect(logs.atualizacoes, [
          (1, 'Armazenado', '{"status":"Armazenado"}'),
        ]);
        expect(find.byType(PendenciaProtocoloCard), findsNothing);
        expect(find.text('Nenhuma pendência para você.'), findsOneWidget);
        expect(adapter.requests, hasLength(1));
      },
    );
  }

  testWidgets(
    'cancelar autenticação mantém pendência sem consultar o protocolo',
    (tester) async {
      final consulta = _Consulta();
      final logs = _Logs();
      await _pump(
        tester,
        modulo: '/ata',
        documentos: DocumentosProcesso(atas: [ataFixture(1)]),
        consulta: consulta,
        logs: logs,
      );
      await tester.tap(find.byTooltip('Atualizar situação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(consulta.protocolos, isEmpty);
      expect(logs.atualizacoes, isEmpty);
      expect(find.byType(PendenciaProtocoloCard), findsOneWidget);
    },
  );

  testWidgets('falha na consulta preserva a pendência e informa o erro', (
    tester,
  ) async {
    final adapter = JsonHttpAdapter({
      'access_token': 'token-teste',
      'expire_in': 3600,
    });
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final auth = AuthService(dio: dio);
    await tester.runAsync(
      () => auth.loginAudesp(
        userId: 1,
        email: 'teste@example.com',
        password: 'senha',
        baseUrl: ambientePendencias,
      ),
    );
    final logs = _Logs();
    await _pump(
      tester,
      modulo: '/ata',
      documentos: DocumentosProcesso(atas: [ataFixture(1)]),
      consulta: _Consulta()..falhar = true,
      logs: logs,
      auth: auth,
    );
    await tester.tap(find.byTooltip('Atualizar situação'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Erro ao atualizar:'), findsOneWidget);
    expect(logs.atualizacoes, isEmpty);
    expect(find.byType(PendenciaProtocoloCard), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  for (final outroUsuario in [true, false]) {
    testWidgets(
      'token de ${outroUsuario ? 'outro usuário' : 'outro ambiente'} exige autenticação',
      (tester) async {
        final dio = Dio()
          ..httpClientAdapter = JsonHttpAdapter({
            'access_token': 'token-teste',
            'expire_in': 3600,
          });
        addTearDown(() => dio.close(force: true));
        final auth = AuthService(dio: dio);
        await tester.runAsync(
          () => auth.loginAudesp(
            userId: outroUsuario ? 2 : 1,
            email: 'teste@example.com',
            password: 'senha',
            baseUrl: outroUsuario
                ? ambientePendencias
                : Environment.oficial.baseUrl,
          ),
        );
        final consulta = _Consulta();
        await _pump(
          tester,
          modulo: '/ata',
          documentos: DocumentosProcesso(atas: [ataFixture(1)]),
          consulta: consulta,
          logs: _Logs(),
          auth: auth,
        );
        await tester.tap(find.byTooltip('Atualizar situação'));
        await tester.pumpAndSettle();
        expect(find.text('Senha AUDESP'), findsOneWidget);
        expect(consulta.protocolos, isEmpty);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      },
    );
  }
}
