import 'package:audesp_api/features/pendencias/domain/prazo_envio.dart';
import 'package:audesp_api/shared/widgets/indicador_icone.dart';
import 'package:audesp_api/shared/widgets/prazo_envio_indicador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Publicação em 10/11/2026: 5 dias úteis até 17/11/2026.
  final prazo = PrazoEnvioConfig().calcular(
    TipoPrazo.edital,
    publicacaoEdital: DateTime(2026, 11, 10),
  );

  Future<IndicadorIcone> pump(WidgetTester tester, DateTime hoje) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrazoEnvioIndicador(prazo: prazo, hoje: hoje),
        ),
      ),
    );
    return tester.widget<IndicadorIcone>(find.byType(IndicadorIcone));
  }

  testWidgets('só o ícone, com o prazo na tooltip', (tester) async {
    final emDia = await pump(tester, DateTime(2026, 11, 11));
    expect(emDia.icone, Icons.schedule);
    expect(find.textContaining('Prazo'), findsNothing);
    expect(
      find.byTooltip(
        'Prazo AUDESP até 17/11/2026\n'
        '5 dias úteis da publicação no PNCP (10/11/2026). '
        'Restam 4 dias úteis.',
      ),
      findsOneWidget,
    );

    final proximo = await pump(tester, DateTime(2026, 11, 16));
    expect(proximo.icone, Icons.warning_amber_rounded);
    expect(proximo.detalhe, contains('Resta 1 dia útil.'));

    final hoje = await pump(tester, DateTime(2026, 11, 17));
    expect(hoje.titulo, 'Prazo AUDESP vence hoje (17/11/2026)');

    final vencido = await pump(tester, DateTime(2026, 11, 18));
    expect(vencido.titulo, 'Prazo AUDESP vencido em 17/11/2026');
    expect(vencido.icone, Icons.error_outline);
    expect(vencido.detalhe, isNot(contains('Resta')));
  });

  testWidgets('sem prazo não mostra nada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrazoEnvioIndicador(prazo: null)),
    );
    expect(find.byType(IndicadorIcone), findsNothing);
  });
}
