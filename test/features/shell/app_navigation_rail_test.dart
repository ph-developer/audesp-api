import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/core/navigation/app_modules.dart';
import 'package:audesp_api/features/shell/widgets/app_navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

User _user({int permissions = 0, bool isAdmin = false}) => User(
  id: 1,
  nome: 'Usuário',
  email: 'usuario@example.com',
  permissions: permissions,
  isAdmin: isAdmin,
  createdAt: DateTime(2026),
);

Future<GoRouter> _pumpRail(
  WidgetTester tester,
  List<AppModule> modules, {
  String initialLocation = '/edital',
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: Row(
            children: [
              AppNavigationRail(
                modules: modules,
                leading: const SizedBox.shrink(),
                trailing: const SizedBox.shrink(),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        routes: [
          for (final module in [...kAppModules, kLogsModule])
            GoRoute(
              path: module.route,
              builder: (context, state) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

Semantics _destinationSemantics(WidgetTester tester, String label) =>
    tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
      ),
    );

void main() {
  testWidgets('admin vê os grupos em ordem e duas divisórias curtas', (
    tester,
  ) async {
    await _pumpRail(tester, modulosPara(_user(isAdmin: true)));

    expect(find.byType(Divider), findsNWidgets(2));
    final dividers = find.byType(Divider);
    expect(
      tester.getCenter(dividers.at(0)).dy,
      greaterThan(tester.getCenter(find.text('Estimativa')).dy),
    );
    expect(
      tester.getCenter(dividers.at(0)).dy,
      lessThan(tester.getCenter(find.text('Edital')).dy),
    );
    expect(
      tester.getCenter(dividers.at(1)).dy,
      greaterThan(tester.getCenter(find.text('Licitação')).dy),
    );
    expect(
      tester.getCenter(dividers.at(1)).dy,
      lessThan(tester.getCenter(find.text('Ata')).dy),
    );
    for (final divider in tester.widgetList<Divider>(dividers)) {
      expect(divider.indent, greaterThan(0));
      expect(divider.endIndent, greaterThan(0));
    }
    expect(tester.getSize(find.byType(AppNavigationRail)).width, 80);
    expect(find.byTooltip('Logs'), findsNothing);
  });

  for (final permissions in [
    AppPermissions.estimativa,
    AppPermissions.edital | AppPermissions.licitacao,
    AppPermissions.ata | AppPermissions.ajuste,
    AppPermissions.none,
  ]) {
    testWidgets('um grupo ou nenhum não gera divisórias ($permissions)', (
      tester,
    ) async {
      final modules = modulosPara(_user(permissions: permissions));
      await _pumpRail(tester, modules);

      expect(find.byType(Divider), findsNothing);
      for (final module in kAppModules) {
        expect(
          find.byTooltip(module.label),
          modules.contains(module) ? findsOneWidget : findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('separa grupos visíveis mesmo sem o grupo intermediário', (
    tester,
  ) async {
    await _pumpRail(
      tester,
      modulosPara(
        _user(permissions: AppPermissions.estimativa | AppPermissions.ajuste),
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
    expect(find.byTooltip('Estimativa'), findsOneWidget);
    expect(find.byTooltip('Ajuste'), findsOneWidget);
    expect(find.byTooltip('Edital'), findsNothing);
    expect(find.byTooltip('Ata'), findsNothing);
  });

  testWidgets('seleção acompanha a rota e subrotas sem índice persistido', (
    tester,
  ) async {
    final router = await _pumpRail(
      tester,
      kAppModules,
      initialLocation: '/licitacao/42',
    );

    expect(find.byIcon(Icons.gavel), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    final licitacao = _destinationSemantics(tester, 'Licitação');
    expect(licitacao.properties.selected, isTrue);
    expect(licitacao.properties.button, isTrue);
    expect(
      _destinationSemantics(tester, 'Edital').properties.selected,
      isFalse,
    );

    router.go('/ata/new');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.assignment), findsOneWidget);
    expect(find.byIcon(Icons.gavel_outlined), findsOneWidget);
    expect(_destinationSemantics(tester, 'Ata').properties.selected, isTrue);
    expect(
      _destinationSemantics(tester, 'Licitação').properties.selected,
      isFalse,
    );

    router.go('/logs');
    await tester.pumpAndSettle();

    for (final module in kAppModules) {
      expect(
        _destinationSemantics(tester, module.label).properties.selected,
        isFalse,
      );
    }
  });

  testWidgets('clicar no destino navega para a rota do módulo', (tester) async {
    final router = await _pumpRail(tester, kAppModules);

    await tester.tap(find.byTooltip('Ajuste'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/ajuste');
    expect(_destinationSemantics(tester, 'Ajuste').properties.selected, isTrue);
  });
}
