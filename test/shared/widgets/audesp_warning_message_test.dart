import 'package:audesp_api/shared/widgets/audesp_warning_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza a mensagem e o ícone de aviso', (tester) async {
    const message = 'O rascunho pode ser salvo; o envio está bloqueado.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AudespWarningMessage(message: message)),
      ),
    );

    expect(find.text(message), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
