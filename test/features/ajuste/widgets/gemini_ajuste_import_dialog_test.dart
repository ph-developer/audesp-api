import 'package:audesp_api/features/ajuste/widgets/gemini_ajuste_import_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _abrirRevisao(
  WidgetTester tester, {
  Map<String, String> atuais = const {},
  required Map<String, String?> sugestoes,
  bool licitacao = false,
  ValueChanged<Map<String, String>?>? onResult,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final resultado = licitacao
                  ? await showGeminiReviewDialog(
                      context: context,
                      currentValues: atuais,
                      suggestedValues: sugestoes,
                      title: 'Preencher pela licitação',
                      suggestionLabel: 'Licitação',
                    )
                  : await showGeminiReviewDialog(
                      context: context,
                      currentValues: atuais,
                      suggestedValues: sugestoes,
                    );
              onResult?.call(resultado);
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Finder _checkboxDoCampo(WidgetTester tester, String label) {
  final table = tester.widget<Table>(find.byType(Table));
  final row = table.children.singleWhere((row) {
    final first = row.children.first;
    return first is Padding &&
        first.child is Text &&
        (first.child as Text).data == label;
  });
  return find.byWidget(row.children.last);
}

void main() {
  testWidgets('mantém título, coluna e seleção padrão da revisão Gemini', (
    tester,
  ) async {
    Map<String, String>? resultado;
    await _abrirRevisao(
      tester,
      atuais: {'valorInicial': '100,00'},
      sugestoes: {
        'valorInicial': '200,00',
        'itens': '1, 2',
        'nomeRazaoSocialFornecedor': null,
      },
      onResult: (value) => resultado = value,
    );
    expect(find.text('Revisão da Importação'), findsOneWidget);
    expect(find.text('Sugestão Gemini'), findsOneWidget);
    expect(find.text('Tipo de Pessoa do Fornecedor'), findsNothing);
    expect(
      tester
          .widget<Checkbox>(_checkboxDoCampo(tester, 'Valor Inicial (R\$)'))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<Checkbox>(_checkboxDoCampo(tester, 'Itens Contratados'))
          .value,
      isTrue,
    );
    await tester.tap(find.text('Aplicar Selecionados'));
    await tester.pumpAndSettle();
    expect(resultado, {'itens': '1, 2'});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'revisão local permite aceitar NI sem aceitar tipo já preenchido',
    (tester) async {
      Map<String, String>? resultado;
      await _abrirRevisao(
        tester,
        licitacao: true,
        atuais: {
          'niFornecedor': '12345678901',
          'tipoPessoaFornecedor': 'PF',
          'nomeRazaoSocialFornecedor': 'Nome digitado',
          'valorInicial': '500,00',
        },
        sugestoes: <String, String>{
          'niFornecedor': 'AB-123',
          'tipoPessoaFornecedor': 'PE',
          'itens': '1, 3',
        },
        onResult: (value) => resultado = value,
      );
      expect(find.text('Preencher pela licitação'), findsOneWidget);
      expect(find.text('Licitação'), findsOneWidget);
      expect(find.text('Sugestão Gemini'), findsNothing);
      expect(find.text('AB-123'), findsOneWidget);
      expect(
        tester
            .widget<Checkbox>(
              _checkboxDoCampo(tester, 'Tipo de Pessoa do Fornecedor'),
            )
            .value,
        isFalse,
      );
      await tester.tap(_checkboxDoCampo(tester, 'CNPJ/CPF do Fornecedor'));
      await tester.tap(find.text('Aplicar Selecionados'));
      await tester.pumpAndSettle();
      expect(resultado, {'niFornecedor': 'AB-123', 'itens': '1, 3'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selecionar tudo inclui tipo explícito e preserva o NI estrangeiro',
    (tester) async {
      Map<String, String>? resultado;
      await _abrirRevisao(
        tester,
        licitacao: true,
        atuais: {'niFornecedor': 'OLD-99', 'tipoPessoaFornecedor': 'PE'},
        sugestoes: <String, String>{
          'niFornecedor': 'AB.123-XYZ',
          'tipoPessoaFornecedor': 'PE',
          'itens': '2',
        },
        onResult: (value) => resultado = value,
      );
      expect(find.text('OLD-99'), findsOneWidget);
      expect(find.text('AB.123-XYZ'), findsOneWidget);
      await tester.tap(find.text('Selecionar tudo'));
      await tester.tap(find.text('Aplicar Selecionados'));
      await tester.pumpAndSettle();
      expect(resultado, {
        'niFornecedor': 'AB.123-XYZ',
        'tipoPessoaFornecedor': 'PE',
        'itens': '2',
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desmarcar tudo desabilita aplicar e cancelar não retorna alterações',
    (tester) async {
      Map<String, String>? resultado = {'sentinela': 'sem alteração'};
      await _abrirRevisao(
        tester,
        licitacao: true,
        sugestoes: <String, String>{'itens': '1, 2'},
        onResult: (value) => resultado = value,
      );
      await tester.tap(find.text('Desmarcar tudo'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Aplicar Selecionados'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(resultado, isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
