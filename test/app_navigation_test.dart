import 'dart:async';

import 'package:audesp_api/app.dart';
import 'package:audesp_api/core/constants/environments.dart';
import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/features/ajuste/pages/ajuste_page.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/auth/pages/login_page.dart';
import 'package:audesp_api/features/documentacao/documentacao_providers.dart';
import 'package:audesp_api/features/edital/pages/edital_page.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:audesp_api/features/pendencias/domain/pendencias_modulos.dart';
import 'package:audesp_api/features/pendencias/pendencias_providers.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/processo/domain/ufesp_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/processo/processo_fixtures.dart';

class _Ambiente extends EnvironmentNotifier {
  @override
  Environment build() => Environment.piloto;

  @override
  Future<void> setEnvironment(Environment env) async => state = env;
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  bool comSessao = true,
  required Future<Map<String, int>> contagens,
  Future<Map<String, int>> Function(Ref)? carregar,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWith(_Ambiente.new),
      pendenciasContagemProvider.overrideWith(
        (ref) => carregar?.call(ref) ?? contagens,
      ),
      pendenciasModulosProvider.overrideWith(
        (ref) async => const PendenciasModulos(),
      ),
      ufespConfigProvider.overrideWith((ref) async => const UfespConfig()),
      pncpConfigProvider.overrideWith((ref) async => const PncpConfig()),
      pncpMonitorProvider.overrideWith((ref) {}),
      protocolosMonitorProvider.overrideWith((ref) {}),
      documentacaoMonitorProvider.overrideWith((ref) {}),
      documentacaoAlertaProvider.overrideWith((ref) => null),
    ],
  );
  addTearDown(container.dispose);
  if (comSessao) {
    container
        .read(localSessionProvider.notifier)
        .login(
          usuarioFixture(
            permissions: AppPermissions.edital | AppPermissions.ajuste,
          ),
        );
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('usa o ambiente carregado durante a abertura da sessão', (
    tester,
  ) async {
    final carregado = Completer<void>();
    final container = await _pumpApp(
      tester,
      contagens: Future.value({}),
      carregar: (ref) async {
        final ambiente = ref.watch(environmentProvider);
        await carregado.future;
        return ambiente == Environment.piloto ? {'/edital': 1} : {'/ajuste': 1};
      },
    );
    await container
        .read(environmentProvider.notifier)
        .setEnvironment(Environment.oficial);
    await tester.pumpAndSettle();
    carregado.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AjustePage), findsOneWidget);
  });

  testWidgets(
    'abertura com sessão segue para o primeiro módulo com pendência',
    (tester) async {
      await _pumpApp(tester, contagens: Future.value({'/ajuste': 1}));
      expect(find.byType(AjustePage), findsOneWidget);
      expect(find.byType(EditalPage), findsNothing);
    },
  );

  testWidgets(
    'login segue ao módulo com pendência depois do fallback síncrono',
    (tester) async {
      final completer = Completer<Map<String, int>>();
      final container = await _pumpApp(
        tester,
        comSessao: false,
        contagens: completer.future,
      );
      expect(find.byType(LoginPage), findsOneWidget);
      container
          .read(localSessionProvider.notifier)
          .login(
            usuarioFixture(
              permissions: AppPermissions.edital | AppPermissions.ajuste,
            ),
          );
      await tester.pumpAndSettle();
      expect(find.byType(EditalPage), findsOneWidget);
      completer.complete({'/ajuste': 1});
      await tester.pumpAndSettle();
      expect(find.byType(AjustePage), findsOneWidget);
    },
  );
}
