import 'package:audesp_api/features/licitacao/domain/licitacao_itens_resumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula resumo dos itens e considera licitantes distintos', () {
    final itens = <Map<String, dynamic>>[
      {
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

    final resumo = LicitacaoItensResumo.calcular(itens);

    expect(resumo.quantidadeItens, 3);
    expect(resumo.quantidadeLicitantesDistintos, 3);
    expect(resumo.itensPorSituacao[2], 2);
    expect(resumo.itensPorSituacao[4], 1);
    expect(resumo.itensPorSituacao[1], 0);
    expect(resumo.valorMedioTodosItens, 600);
    expect(resumo.valorMedioItensComVencedor, 300);
    expect(resumo.valorVencedores, 230);
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
}
