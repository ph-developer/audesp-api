import 'package:audesp_api/features/pendencias/domain/prazo_envio.dart';
import 'package:audesp_api/shared/widgets/prazo_envio_indicador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Publicação em 10/11/2026: 5 dias úteis até 17/11/2026.
  final prazo = PrazoEnvioConfig().calcular(
    TipoPrazo.edital,
    publicacaoEdital: DateTime(2026, 11, 10),
  );

  Future<void> pump(WidgetTester tester, DateTime hoje) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PrazoEnvioIndicador(prazo: prazo, hoje: hoje),
      ),
    ),
  );

  testWidgets('mostra o limite e destaca quando está perto ou venceu', (
    tester,
  ) async {
    await pump(tester, DateTime(2026, 11, 11));
    expect(find.text('Prazo AUDESP até 17/11/2026'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(
      find.byTooltip(
        '5 dias úteis da publicação no PNCP (10/11/2026). '
        'Restam 4 dias úteis. Alerta apenas informativo.',
      ),
      findsOneWidget,
    );

    await pump(tester, DateTime(2026, 11, 16));
    expect(
      find.text('Prazo AUDESP até 17/11/2026 · 1 dia útil'),
      findsOneWidget,
    );

    await pump(tester, DateTime(2026, 11, 17));
    expect(find.text('Prazo AUDESP vence hoje'), findsOneWidget);

    await pump(tester, DateTime(2026, 11, 18));
    expect(find.text('Prazo AUDESP vencido em 17/11/2026'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('sem prazo não mostra nada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrazoEnvioIndicador(prazo: null)),
    );
    expect(find.textContaining('Prazo'), findsNothing);
  });
}
