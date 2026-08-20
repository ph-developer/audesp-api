import 'package:audesp_api/features/licitacao/domain/licitacao_itens_resumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula resumo dos itens e considera licitantes distintos', () {
    final itens = <Map<String, dynamic>>[
      {
        'numeroItem': 1,
        'valor': 100.0,
        'situacaoCompraItemId': 2,
        'licitantes': [
          {
            'tipoPessoaId': 'PJ',
            'niPessoa': '11.111.111/0001-11',
            'resultadoHabilitacao': 1,
            'valor': 80.0,
          },
          {
            'tipoPessoaId': 'PJ',
            'niPessoa': '22222222000122',
            'resultadoHabilitacao': 2,
            'valor': 90.0,
          },
        ],
      },
      {
        'numeroItem': 2,
        'valor': 200.0,
        'situacaoCompraItemId': 2,
        'licitantes': [
          {
            'tipoPessoaId': 'PJ',
            'niPessoa': '11111111000111',
            'resultadoHabilitacao': 1,
            'valor': 150.0,
          },
        ],
      },
      {
        'numeroItem': 3,
        'valor': 300.0,
        'situacaoCompraItemId': 4,
        'licitantes': [
          {
            'tipoPessoaId': 'PJ',
            'niPessoa': '33333333000133',
            'resultadoHabilitacao': 6,
          },
        ],
      },
    ];

    final resumo = LicitacaoItensResumo.calcular(
      itens,
      quantidadesPorNumeroItem: {1: 2, 2: 3, 3: 4},
    );

    expect(resumo.quantidadeItens, 3);
    expect(resumo.quantidadeLicitantesDistintos, 3);
    expect(resumo.itensPorSituacao[2], 2);
    expect(resumo.itensPorSituacao[4], 1);
    expect(resumo.itensPorSituacao[1], 0);
    expect(resumo.valorMedioTodosItens, 2000);
    expect(resumo.valorMedioItensComVencedor, 800);
    expect(resumo.valorVencedores, 610);
    expect(resumo.fornecedoresVencedores.length, 1);
    expect(resumo.fornecedoresVencedores.first.niPessoa, '11.111.111/0001-11');
    expect(resumo.fornecedoresVencedores.first.quantidadeItens, 2);
    expect(resumo.fornecedoresVencedores.first.numerosItens, [1, 2]);
    expect(resumo.fornecedoresVencedores.first.valorTotal, 610);
  });

  test('calcula totalização por fornecedor com múltiplos vencedores', () {
    final itens = <Map<String, dynamic>>[
      {
        'numeroItem': 1,
        'tipoOrcamento': 2,
        'licitantes': [
          {
            'tipoPessoaId': 'PJ',
            'niPessoa': '11111111000111',
            'nomeRazaoSocial': 'Empresa A',
            'resultadoHabilitacao': 1,
            'valor': 100.0,
          },
        ],
      },
      {
        'numeroItem': 2,
        'tipoOrcamento': 2,
        'licitantes': [
          {
            'tipoPessoaId': 'PJ',
            'niPessoa': '22222222000122',
            'nomeRazaoSocial': 'Empresa B',
            'resultadoHabilitacao': 1,
            'valor': 200.0,
          },
        ],
      },
      {
        'numeroItem': 3,
        'tipoOrcamento': 1, // Lote
        'licitantes': [
          {
            'tipoPessoaId': 'PJ',
            'niPessoa': '11111111000111',
            'nomeRazaoSocial': 'Empresa A',
            'resultadoHabilitacao': 1,
            'valor': 500.0,
          },
        ],
      },
    ];

    final resumo = LicitacaoItensResumo.calcular(
      itens,
      quantidadesPorNumeroItem: {1: 5, 2: 3, 3: 1},
    );

    // Empresa A: item 1 (100 * 5 = 500) + item 3 (lote = 500) = 1000
    // Empresa B: item 2 (200 * 3 = 600)
    expect(resumo.fornecedoresVencedores.length, 2);
    expect(resumo.fornecedoresVencedores[0].nomeRazaoSocial, 'Empresa A');
    expect(resumo.fornecedoresVencedores[0].valorTotal, 1000);
    expect(resumo.fornecedoresVencedores[0].numerosItens, [1, 3]);
    expect(resumo.fornecedoresVencedores[1].nomeRazaoSocial, 'Empresa B');
    expect(resumo.fornecedoresVencedores[1].valorTotal, 600);
    expect(resumo.fornecedoresVencedores[1].numerosItens, [2]);
  });

  test('soma mais de um vencedor registrado no mesmo item', () {
    final item = <String, dynamic>{
      'valor': 500,
      'licitantes': [
        {'resultadoHabilitacao': 1, 'valor': 180},
        {'resultadoHabilitacao': 1, 'valor': 220},
      ],
    };

    expect(valorMedioDoItem(item), 500);
    expect(valorVencedorDoItem(item), 400);
  });

  test('retorna os nomes distintos dos vencedores do item', () {
    final item = <String, dynamic>{
      'licitantes': [
        {
          'nomeRazaoSocial': 'Fornecedor Vencedor',
          'resultadoHabilitacao': 1,
        },
        {
          'nomeRazaoSocial': 'Fornecedor Classificado',
          'resultadoHabilitacao': 2,
        },
        {
          'nomeRazaoSocial': 'Fornecedor Vencedor',
          'resultadoHabilitacao': 1,
        },
      ],
    };

    expect(nomesVencedoresDoItem(item), ['Fornecedor Vencedor']);
  });

  test('identifica corretamente se o item é lote ou item unitário', () {
    expect(isItemLote({'tipoOrcamento': 1}), isTrue);
    expect(isItemLote({'tipoProposta': 1}), isTrue);
    expect(isItemLote({'tipoEstimativa': 'lote'}), isTrue);
    expect(isItemLote({'tipoOrcamento': 2}), isFalse);
    expect(isItemLote({'tipoProposta': 2}), isFalse);
    expect(isItemLote({'tipoOrcamento': 3}), isFalse);
    expect(isItemLote({'tipoOrcamento': 0}), isFalse);
    expect(isItemLote({}), isFalse);
  });
}
