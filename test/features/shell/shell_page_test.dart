import 'package:audesp_api/core/constants/environments.dart';
import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/core/navigation/app_modules.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/documentacao/documentacao_providers.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/shell/shell_page.dart';
import 'package:audesp_api/features/pendencias/pendencias_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _TestEnvironmentNotifier extends EnvironmentNotifier {
  @override
  Environment build() => Environment.piloto;
}

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  int permissions = 0,
  bool isAdmin = false,
  DocumentacaoAlerta? alertaDocumentacao,
}) async {
  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWith(_TestEnvironmentNotifier.new),
      pendenciasContagemProvider.overrideWith((ref) async => {}),
      // Sem banco, PNCP nem AUDESP nos testes do shell.
      pncpMonitorProvider.overrideWith((ref) {}),
      documentacaoMonitorProvider.overrideWith((ref) {}),
      protocolosMonitorProvider.overrideWith((ref) {}),
      documentacaoAlertaProvider.overrideWith((ref) => alertaDocumentacao),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(localSessionProvider.notifier)
      .login(
        User(
          id: 1,
          nome: 'Usuário',
          email: 'usuario@example.com',
          permissions: permissions,
          isAdmin: isAdmin,
          createdAt: DateTime(2026),
        ),
      );

  final router = GoRouter(
    initialLocation: '/edital',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          for (final module in [...kAppModules, kLogsModule])
            GoRoute(
              path: module.route,
              builder: (context, state) => const SizedBox.shrink(),
            ),
        ],
      ),
      for (final path in ['/admin', '/profile'])
        GoRoute(path: path, builder: (context, state) => const Scaffold()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final permissions in [AppPermissions.none, AppPermissions.estimativa]) {
    testWidgets('oculta Logs para usuário sem envio ($permissions)', (
      tester,
    ) async {
      await _pumpShell(tester, permissions: permissions);

      expect(find.byTooltip('Logs'), findsNothing);
      expect(find.byTooltip('Processos'), findsNothing);
      expect(find.byTooltip('Meu perfil'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final profile in [
    (
      permissions: AppPermissions.edital | AppPermissions.licitacao,
      isAdmin: false,
    ),
    (permissions: AppPermissions.ata | AppPermissions.ajuste, isAdmin: false),
    (permissions: AppPermissions.none, isAdmin: true),
  ]) {
    testWidgets('Logs no rodapé navega e acompanha a seleção ($profile)', (
      tester,
    ) async {
      final router = await _pumpShell(
        tester,
        permissions: profile.permissions,
        isAdmin: profile.isAdmin,
      );
      final logs = find.widgetWithIcon(IconButton, kLogsModule.icon);
      final profileButton = find.byTooltip(
        profile.isAdmin ? 'Administração' : 'Meu perfil',
      );

      expect(logs, findsOneWidget);
      expect(find.byTooltip('Processos'), findsNothing);
      expect(tester.widget<IconButton>(logs).isSelected, isFalse);
      expect(
        tester.getCenter(logs).dy,
        lessThan(tester.getCenter(profileButton).dy),
      );

      await tester.tap(find.byTooltip('Logs'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/logs');
      final selectedLogs = find.widgetWithIcon(
        IconButton,
        kLogsModule.activeIcon,
      );
      expect(tester.widget<IconButton>(selectedLogs).isSelected, isTrue);
      final style = tester.widget<IconButton>(selectedLogs).style!;
      final colors = Theme.of(tester.element(selectedLogs)).colorScheme;
      expect(style.backgroundColor!.resolve({}), colors.secondaryContainer);

      router.go('/edital');
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(logs).isSelected, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  const dica = 'A documentação do AUDESP foi alterada.\nInforme o TI.';

  testWidgets('alerta da documentação aparece só quando houve alteração', (
    tester,
  ) async {
    await _pumpShell(tester, permissions: 1);
    expect(find.byTooltip(dica), findsNothing);
  });

  testWidgets('alerta da documentação lista as alterações sem botão de admin', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      permissions: 1,
      alertaDocumentacao: const DocumentacaoAlerta(
        alteracoes: ['Anexo alterado: edital-20261015.zip'],
      ),
    );
    expect(find.byTooltip(dica), findsOneWidget);

    await tester.tap(find.byTooltip(dica));
    await tester.pumpAndSettle();

    expect(find.text('• Anexo alterado: edital-20261015.zip'), findsOneWidget);
    expect(find.text('Marcar como verificada'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
