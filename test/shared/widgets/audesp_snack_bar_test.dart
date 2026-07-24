import 'package:audesp_api/shared/widgets/audesp_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('erro fica interativo acima de um diálogo aberto', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Diálogo aberto'),
                  actions: [
                    TextButton(
                      onPressed: () => AudespSnackBar.error(
                        dialogContext,
                        'Falha de validação',
                      ),
                      child: const Text('Exibir erro'),
                    ),
                  ],
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exibir erro'));
    await tester.pump();

    expect(find.text('Falha de validação'), findsOneWidget);
    expect(find.text('Diálogo aberto'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar mensagem'));
    await tester.pump();

    expect(find.text('Falha de validação'), findsNothing);
    expect(find.text('Diálogo aberto'), findsOneWidget);
  });
}
