import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/pncp_compras_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/core/theme/app_theme.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/edital/edital_providers.dart';
import 'package:audesp_api/features/edital/pages/edital_page.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:audesp_api/features/pendencias/pendencias_providers.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/domain/ufesp_rules.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../processo/processo_fixtures.dart';

PncpCompra _compra({bool dispensada = false, String? motivo}) => PncpCompra(
  id: 9,
  cnpj: '46395000000139',
  ano: 2026,
  sequencial: 3,
  numeroControle: '4639500000013910000032026',
  modalidadeId: 6,
  numeroCompra: '3',
  objeto: 'Material de escritório',
  valorTotalEstimado: 50000,
  dadosJson: '{}',
  dispensadaEm: dispensada ? DateTime(2026, 11, 9) : null,
  motivoDispensa: motivo,
);

class _ComprasMemoria implements PncpComprasDao {
  List<PncpCompra> compras;
  int? dispensadaPor;
  String? motivo;
  _ComprasMemoria(this.compras);

  @override
  Future<void> dispensar(int id, {required int? userId, String? motivo}) async {
    dispensadaPor = userId;
    this.motivo = motivo;
    compras = [_compra(dispensada: true, motivo: motivo)];
  }

  @override
  Future<void> restaurar(int id) async => compras = [_compra()];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _pumpPage(
  WidgetTester tester, {
  List<Edital> editais = const [],
  List<PncpCompra> compras = const [],
  _ComprasMemoria? dao,
  int permissions = AppPermissions.edital,
  PncpConfig config = const PncpConfig(cnpj: '46395000000139'),
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/edital',
    routes: [
      GoRoute(path: '/edital', builder: (_, _) => const EditalPage()),
      GoRoute(
        path: '/edital/new',
        builder: (_, state) => Scaffold(body: Text('${state.uri}')),
      ),
      GoRoute(
        path: '/edital/:id',
        builder: (_, state) => Scaffold(body: Text('${state.uri}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      documentosProcessoProvider.overrideWith(
        (ref) async => DocumentosProcesso(editais: editais),
      ),
      enviosProcessoProvider.overrideWith((ref) async => EnviosProcesso.vazio),
      pncpComprasProvider.overrideWith((ref) async => dao?.compras ?? compras),
      pncpContratosProvider.overrideWith((ref) async => const []),
      pncpAtasProvider.overrideWith((ref) async => const []),
      pncpConfigProvider.overrideWith((ref) async => config),
      ufespConfigProvider.overrideWith((ref) async => const UfespConfig()),
      editaisDraftProvider.overrideWith(
        (ref) async =>
            editais.where((e) => !e.oculto && e.status == 'draft').toList(),
      ),
      editaisEnviadosProvider.overrideWith(
        (ref) async =>
            editais.where((e) => !e.oculto && e.status == 'sent').toList(),
      ),
      enviosProvider.overrideWith((ref, endpoint) async => EnviosIndex.vazio),
      if (dao != null) pncpComprasDaoProvider.overrideWithValue(dao),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(localSessionProvider.notifier)
      .login(usuarioFixture(permissions: permissions));
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
  testWidgets('PNCP sem edital aparece de início, busca e inicia edital', (
    tester,
  ) async {
    final compra = _compra();
    final router = await _pumpPage(tester, compras: [compra]);
    final segmented = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    expect(segmented.selected, {'pendencias'});
    expect(
      segmented.segments.first.label,
      isA<Text>().having((t) => t.data, 'label', 'Pendências'),
    );
    expect(find.text('Envio não obrigatório'), findsOneWidget);
    expect(find.byTooltip('Consultar PNCP'), findsOneWidget);
    expect(find.text('Iniciar edital'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'veiculos');
    await tester.pumpAndSettle();
    expect(find.text('Iniciar edital'), findsNothing);
    await tester.enterText(find.byType(TextField), 'escritorio');
    await tester.pumpAndSettle();
    expect(find.text('Iniciar edital'), findsOneWidget);
    await tester.tap(find.text('Iniciar edital'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/edital/new?pncpCompraId=9',
    );
  });

  testWidgets('dispensa com motivo e restauração atualizam aba e badge', (
    tester,
  ) async {
    final dao = _ComprasMemoria([_compra()]);
    await _pumpPage(tester, dao: dao);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditalPage)),
    );
    expect(
      (await container.read(pendenciasContagemProvider.future))['/edital'],
      1,
    );

    await tester.tap(find.text('Dispensar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Enviado pelo sistema anterior',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Dispensar'));
    await tester.pumpAndSettle();
    expect(dao.dispensadaPor, 1);
    expect(dao.motivo, 'Enviado pelo sistema anterior');
    expect(find.text('Iniciar edital'), findsNothing);
    expect(
      (await container.read(pendenciasContagemProvider.future))['/edital'],
      0,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Restaurar'), findsOneWidget);
    expect(
      find.textContaining('Enviado pelo sistema anterior'),
      findsOneWidget,
    );
    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar edital'), findsOneWidget);
    expect(find.text('Restaurar'), findsNothing);
    expect(
      (await container.read(pendenciasContagemProvider.future))['/edital'],
      1,
    );
  });

  testWidgets('edital oculto continua casando com PNCP e não aparece', (
    tester,
  ) async {
    final compra = _compra();
    await _pumpPage(
      tester,
      compras: [compra],
      editais: [
        processoFixture(codigo: compra.numeroControle, oculto: true).edital,
      ],
    );
    expect(find.text('Iniciar edital'), findsNothing);
    expect(find.text('Nenhuma pendência para você.'), findsOneWidget);
    await tester.tap(find.text('Enviados'));
    await tester.pumpAndSettle();
    expect(find.text('Objeto do edital 1'), findsNothing);
    expect(find.byTooltip('Ocultar edital'), findsNothing);
  });

  testWidgets('UFESP e código local permanecem na listagem de editais', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      editais: [
        processoFixture(
          codigo: '1234567800019010000012026',
          valorTotal: 50000,
        ).edital,
      ],
    );
    await tester.tap(find.text('Enviados'));
    await tester.pumpAndSettle();
    expect(find.text('Envio não obrigatório'), findsOneWidget);
    expect(
      find.text('1234567800019010000012026 - Pregão Eletrônico 1/2026'),
      findsOneWidget,
    );
  });

  testWidgets(
    'sem permissão não mostra compras, consulta nem criação de edital',
    (tester) async {
      await _pumpPage(
        tester,
        compras: [_compra()],
        permissions: AppPermissions.ajuste,
      );
      expect(find.text('Iniciar edital'), findsNothing);
      expect(find.text('Mostrar dispensadas'), findsNothing);
      expect(find.byTooltip('Consultar PNCP'), findsNothing);
      expect(find.byTooltip('Novo Edital'), findsNothing);
    },
  );

  testWidgets('consulta PNCP fica oculta sem configuração', (tester) async {
    await _pumpPage(tester, config: const PncpConfig());
    expect(find.byTooltip('Consultar PNCP'), findsNothing);
  });
}
