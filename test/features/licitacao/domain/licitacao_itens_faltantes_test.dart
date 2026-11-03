import 'package:audesp_api/features/licitacao/domain/licitacao_itens_faltantes.dart';
import 'package:audesp_api/features/licitacao/domain/licitacao_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoje = DateTime(2026, 11, 3);

  Map<String, dynamic> itemEdital(int numero, {num valor = 10}) => {
    'numeroItem': numero,
    'quantidade': 5,
    'valorUnitarioEstimado': valor,
  };

  Map<String, dynamic> itemLicitacao(
    int numero, {
    int tipoOrcamento = 2,
    String dataSituacao = '2026-10-20',
  }) => {
    'numeroItem': numero,
    'tipoOrcamento': tipoOrcamento,
    'valor': 9.5,
    'dataOrcamento': '2026-08-01',
    'situacaoCompraItemId': 2,
    'dataSituacaoItem': dataSituacao,
    'tipoValor': 'M',
    'tipoProposta': tipoOrcamento,
    'licitantes': [
      {
        'tipoPessoaId': 'PJ',
        'niPessoa': '12345678000199',
        'declaracaoMEouEPP': 3,
        'resultadoHabilitacao': 1,
      },
    ],
  };

  group('LicitacaoItensFaltantes.numeros', () {
    test('retorna os números do edital ausentes na licitação, ordenados', () {
      final edital = [for (final n in [4, 1, 2, 3]) itemEdital(n)];
      final licitacao = [itemLicitacao(1), itemLicitacao(3)];

      expect(LicitacaoItensFaltantes.numeros(edital, licitacao), [2, 4]);
    });

    test('vazio quando todos os itens já existem', () {
      expect(
        LicitacaoItensFaltantes.numeros(
          [itemEdital(1)],
          [itemLicitacao(1), itemLicitacao(2)],
        ),
        isEmpty,
      );
    });
  });

  group('LicitacaoItensFaltantes.desertos', () {
    test('cria os faltantes como desertos seguindo os itens existentes', () {
      final edital = [itemEdital(1), itemEdital(2, valor: 12.345678)];
      final licitacao = [itemLicitacao(1)];

      final novos = LicitacaoItensFaltantes.desertos(
        edital,
        licitacao,
        hoje: hoje,
      );

      expect(novos, [
        {
          'numeroItem': 2,
          'tipoOrcamento': 2,
          'situacaoCompraItemId': 4,
          'dataSituacaoItem': '2026-10-20',
          'tipoValor': 'M',
          'tipoProposta': 2,
          'licitantes': <Map<String, dynamic>>[],
          'valor': 12.3457,
          'dataOrcamento': '2026-08-01',
        },
      ]);
    });

    test('usa o valor mais comum entre os itens existentes', () {
      final licitacao = [
        itemLicitacao(1, tipoOrcamento: 1, dataSituacao: '2026-10-01'),
        itemLicitacao(2, dataSituacao: '2026-10-20'),
        itemLicitacao(3, dataSituacao: '2026-10-20'),
      ];

      final novo = LicitacaoItensFaltantes.desertos(
        [for (final n in [1, 2, 3, 4]) itemEdital(n)],
        licitacao,
        hoje: hoje,
      ).single;

      expect(novo['tipoOrcamento'], 2);
      expect(novo['dataSituacaoItem'], '2026-10-20');
    });

    test('sem itens de referência usa padrões e a data de hoje', () {
      final novo = LicitacaoItensFaltantes.desertos(
        [itemEdital(1)],
        const [],
        hoje: hoje,
      ).single;

      expect(novo['tipoOrcamento'], 2);
      expect(novo['tipoProposta'], 2);
      expect(novo['tipoValor'], 'M');
      expect(novo['dataSituacaoItem'], '2026-11-03');
      expect(novo['dataOrcamento'], '2026-11-03');
    });

    test('sem orçamento não informa valor nem data do orçamento', () {
      final novo = LicitacaoItensFaltantes.desertos(
        [itemEdital(1), itemEdital(2)],
        [itemLicitacao(1, tipoOrcamento: 0)..['tipoProposta'] = 2],
        hoje: hoje,
      ).single;

      expect(novo.containsKey('valor'), isFalse);
      expect(novo.containsKey('dataOrcamento'), isFalse);
    });

    test('itens gerados passam na validação da licitação', () {
      final edital = {
        'modalidadeId': 6,
        'srp': false,
        'itensCompra': [for (final n in [1, 2, 3]) itemEdital(n)],
      };
      final licitacao = [itemLicitacao(2)];
      final itens = [
        ...licitacao,
        ...LicitacaoItensFaltantes.desertos(
          edital['itensCompra'] as List<Map<String, dynamic>>,
          licitacao,
          hoje: hoje,
        ),
      ];

      expect(
        LicitacaoRules.validarItens(itens, edital: edital, hoje: hoje),
        isNull,
      );
    });
  });
}
