import 'dart:async';

import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/pncp/widgets/consultar_pncp_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../processo/processo_fixtures.dart';

class _ConsultaTeste extends PncpConsultaNotifier {
  Completer<int?>? resultado;
  int chamadas = 0;

  @override
  PncpConsultaState build() => const PncpConsultaState();

  void falhar() => state = const PncpConsultaState(erro: 'Sem conexão');

  @override
  Future<int?> consultar({bool automatica = false}) async {
    chamadas++;
    state = const PncpConsultaState(executando: true);
    final novas = await resultado!.future;
    state = const PncpConsultaState();
    return novas;
  }
}

void main() {
  testWidgets(
    'mostra última consulta, erro e execução e permite tentar novamente',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          pncpConfigProvider.overrideWith(
            (ref) async => PncpConfig(
              cnpj: '46395000000139',
              ultimaConsultaEm: DateTime(2026, 11, 9, 12, 30),
            ),
          ),
          pncpConsultaProvider.overrideWith(_ConsultaTeste.new),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(localSessionProvider.notifier)
          .login(usuarioFixture(isAdmin: true));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ConsultarPncpButton())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Consultar PNCP (última consulta: 09/11/2026 12:30)'),
        findsOneWidget,
      );

      final consulta =
          container.read(pncpConsultaProvider.notifier) as _ConsultaTeste;
      consulta.falhar();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      expect(
        find.byTooltip(
          'A última consulta ao PNCP falhou: Sem conexão\nClique para tentar de novo.',
        ),
        findsOneWidget,
      );
      consulta.resultado = Completer<int?>();
      await tester.tap(find.byIcon(Icons.sync_problem));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(consulta.chamadas, 1);
      consulta.resultado!.complete(2);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('Consulta ao PNCP concluída. 2 compra(s) nova(s).'),
        findsOneWidget,
      );
    },
  );
}
