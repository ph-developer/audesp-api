import 'package:audesp_api/core/services/gemini_service.dart';
import 'package:audesp_api/features/estimativa/constants/fornecedores_predefinidos.dart';
import 'package:audesp_api/features/estimativa/widgets/gemini_orcamento_import_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe botão de fornecedores predefinidos e preenche campos ao selecionar', (tester) async {
    GeminiOrcamentoResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showGeminiOrcamentoReviewDialog(
                  context: context,
                  suggestedValues: const GeminiOrcamentoResult(
                    razaoSocial: 'Empresa Original',
                    cnpj: '11111111000111',
                    data: '01/01/2026',
                    itens: {'1': 50.0},
                  ),
                  itensEstimativa: [
                    {'id': '1', 'descricao': 'Item de Teste'},
                  ],
                );
              },
              child: const Text('Abrir Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Dialog'));
    await tester.pumpAndSettle();

    // Verifica que o dialog abriu e exibe os dados iniciais
    expect(find.text('Revisão da Importação de Orçamento'), findsOneWidget);
    expect(find.text('Empresa Original'), findsOneWidget);

    // Verifica que o botão de fornecedores predefinidos está presente no header
    final popupBtn = find.byTooltip('Fornecedores Predefinidos');
    expect(popupBtn, findsOneWidget);

    // Abre o menu de fornecedores predefinidos
    await tester.tap(popupBtn);
    await tester.pumpAndSettle();

    // Seleciona o primeiro fornecedor predefinido
    final primeiroPredefinido = fornecedoresPredefinidos.first;
    expect(find.text(primeiroPredefinido.razaoSocial), findsWidgets);
    await tester.tap(find.text(primeiroPredefinido.razaoSocial).last);
    await tester.pumpAndSettle();

    // Verifica se os campos foram atualizados com os dados do fornecedor predefinido
    expect(find.text(primeiroPredefinido.razaoSocial), findsOneWidget);

    // Confirma a importação
    await tester.tap(find.text('Importar Valores'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.razaoSocial, primeiroPredefinido.razaoSocial);
    expect(result!.cnpj, primeiroPredefinido.cnpj);
    expect(result!.bancoDePrecos, primeiroPredefinido.bancoDePrecos);
    expect(result!.itens, {'1': 50.0});
  });
}

