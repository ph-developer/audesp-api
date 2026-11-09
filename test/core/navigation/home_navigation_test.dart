import 'dart:async';

import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/core/navigation/home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/processo/processo_fixtures.dart';

Future<GoRouter> _router(
  WidgetTester tester, {
  String inicio = '/edital',
}) async {
  final router = GoRouter(
    initialLocation: inicio,
    routes: [
      for (final route in [
        '/login',
        '/edital',
        '/licitacao',
        '/ajuste',
        '/profile',
      ])
        GoRoute(path: route, builder: (_, _) => const Scaffold()),
      GoRoute(path: '/edital/:id', builder: (_, _) => const Scaffold()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  final user = usuarioFixture(
    permissions:
        AppPermissions.edital |
        AppPermissions.licitacao |
        AppPermissions.ajuste,
  );

  testWidgets('refina a tela inicial após carregar pendências', (tester) async {
    final router = await _router(tester);
    final completer = Completer<Map<String, int>>();
    final navegar = navegarParaPendencias(
      router: router,
      user: user,
      contagens: completer.future,
      sessaoAtual: () => true,
    );
    expect(router.routeInformationProvider.value.uri.path, '/edital');
    completer.complete({'/ajuste': 2});
    await navegar;
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/ajuste');
  });

  testWidgets('erro e tempo limite mantêm o fallback sem navegação tardia', (
    tester,
  ) async {
    final router = await _router(tester);
    await navegarParaPendencias(
      router: router,
      user: user,
      contagens: Future.error(StateError('Sem banco')),
      sessaoAtual: () => true,
    );
    final completer = Completer<Map<String, int>>();
    final navegar = navegarParaPendencias(
      router: router,
      user: user,
      contagens: completer.future,
      sessaoAtual: () => true,
      timeout: const Duration(milliseconds: 100),
    );
    await tester.pump(const Duration(milliseconds: 101));
    await navegar;
    completer.complete({'/ajuste': 1});
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/edital');
  });

  testWidgets('ignora resultado de sessão encerrada', (tester) async {
    final router = await _router(tester);
    await navegarParaPendencias(
      router: router,
      user: user,
      contagens: Future.value({'/ajuste': 2}),
      sessaoAtual: () => false,
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/edital');
  });

  testWidgets('preserva formulário aberto durante o carregamento', (
    tester,
  ) async {
    final router = await _router(tester);
    final completer = Completer<Map<String, int>>();
    final navegar = navegarParaPendencias(
      router: router,
      user: user,
      contagens: completer.future,
      sessaoAtual: () => true,
    );
    router.go('/edital/42');
    await tester.pumpAndSettle();
    completer.complete({'/ajuste': 2});
    await navegar;
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/edital/42');
  });
}
