import 'package:audesp_api/features/licitacao/domain/licitacao_resultado.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _licitante({
  String ni = '12345678000190',
  String tipo = 'PJ',
  String? nome = 'Fornecedor',
  double? valor = 10,
  int resultado = 1,
}) => {
  'niPessoa': ni,
  'tipoPessoaId': tipo,
  'nomeRazaoSocial': ?nome,
  'valor': ?valor,
  'resultadoHabilitacao': resultado,
};

Map<String, dynamic> _item(
  int numero, {
  int situacao = 2,
  String tipoValor = 'M',
  int tipoProposta = 2,
  int tipoOrcamento = 2,
  List<Map<String, dynamic>>? licitantes,
}) => {
  'numeroItem': numero,
  'situacaoCompraItemId': situacao,
  'tipoValor': tipoValor,
  'tipoProposta': tipoProposta,
  'tipoOrcamento': tipoOrcamento,
  'licitantes': licitantes ?? [_licitante()],
};

Map<String, dynamic> _edital(Map<int, num?> quantidades) => {
  'itensCompra': [
    for (final entry in quantidades.entries)
      {'numeroItem': entry.key, 'quantidade': entry.value},
  ],
};

void main() {
  test('lista somente os itens homologados, sem exigir vencedor', () {
    final doc = {
      'itens': [
        _item(5),
        _item(1, situacao: 1),
        _item(2, licitantes: []),
        _item(3, situacao: 3),
        _item(4, situacao: 4),
        _item(6, situacao: 5),
      ],
    };
    expect(LicitacaoResultado.itensHomologados(doc), {2, 5});
    expect(LicitacaoResultado.itensHomologados({}), isEmpty);
  });

  test('ignora itens não homologados e licitantes não vencedores', () {
    final fornecedores = LicitacaoResultado.fornecedoresVencedores({
      'itens': [
        _item(1, situacao: 1),
        _item(2, situacao: 3),
        _item(3, situacao: 4),
        _item(4, situacao: 5),
        _item(
          5,
          licitantes: [
            for (var resultado = 2; resultado <= 7; resultado++)
              _licitante(ni: '$resultado', resultado: resultado),
          ],
        ),
        _item(6),
      ],
    }, _edital({6: 2}));
    expect(fornecedores.single.itens, [6]);
    expect(fornecedores.single.valorSugerido, 20);
    expect(LicitacaoResultado.fornecedoresVencedores({}, {}), isEmpty);
  });

  for (final (tipo, ni, mascara) in [
    ('PJ', '12345678000190', '12.345.678/0001-90'),
    ('PF', '12345678901', '123.456.789-01'),
  ]) {
    test(
      'agrupa $tipo pelo NI normalizado e usa o primeiro nome não vazio',
      () {
        final fornecedores = LicitacaoResultado.fornecedoresVencedores({
          'itens': [
            _item(
              3,
              licitantes: [_licitante(tipo: tipo, ni: mascara, nome: ' ')],
            ),
            _item(
              1,
              licitantes: [
                _licitante(tipo: tipo, ni: ni, nome: ' Primeiro nome '),
              ],
            ),
            _item(
              2,
              licitantes: [_licitante(tipo: tipo, ni: ni, nome: 'Outro')],
            ),
          ],
        }, _edital({1: 2, 2: 3, 3: 4}));
        final fornecedor = fornecedores.single;
        expect(fornecedor.niPessoa, ni);
        expect(fornecedor.tipoPessoaId, tipo);
        expect(fornecedor.nomeRazaoSocial, 'Primeiro nome');
        expect(fornecedor.itens, [1, 2, 3]);
        expect(fornecedor.valorSugerido, 90);
      },
    );
  }

  test('preserva NI estrangeiro e separa tipos de pessoa com o mesmo NI', () {
    final fornecedores = LicitacaoResultado.fornecedoresVencedores({
      'itens': [
        _item(
          3,
          licitantes: [_licitante(tipo: 'PE', ni: ' AB-123 ')],
        ),
        _item(
          2,
          licitantes: [_licitante(tipo: 'PF', ni: '123')],
        ),
        _item(
          1,
          licitantes: [_licitante(tipo: 'PJ', ni: '123')],
        ),
      ],
    }, _edital({1: 1, 2: 1, 3: 1}));
    expect(fornecedores.map((f) => f.tipoPessoaId), ['PJ', 'PF', 'PE']);
    expect(fornecedores.map((f) => f.niPessoa), ['123', '123', 'AB-123']);
    expect(fornecedores.map((f) => f.itens), [
      [1],
      [2],
      [3],
    ]);
  });

  test('proposta unitária multiplica o valor pela quantidade do edital', () {
    final fornecedor = LicitacaoResultado.fornecedoresVencedores({
      'itens': [
        _item(1, licitantes: [_licitante(valor: 12.5)]),
      ],
    }, _edital({1: 2.5})).single;
    expect(fornecedor.valorSugerido, 31.25);
  });

  for (final (orcamento, proposta) in [(2, 1), (1, 2)]) {
    test(
      'lote ($orcamento/$proposta) usa valor sem multiplicar a quantidade',
      () {
        final doc = {
          'itens': [_item(1, tipoOrcamento: orcamento, tipoProposta: proposta)],
        };
        expect(
          LicitacaoResultado.fornecedoresVencedores(
            doc,
            _edital({1: 99}),
          ).single.valorSugerido,
          10,
        );
        expect(
          LicitacaoResultado.fornecedoresVencedores(
            doc,
            {},
          ).single.valorSugerido,
          10,
        );
      },
    );
  }

  for (final (tipoValor, proposta) in [
    ('P', 1),
    ('P', 2),
    ('P', 3),
    ('M', 3),
  ]) {
    test(
      '$tipoValor com proposta $proposta não sugere valor total parcial',
      () {
        final fornecedor = LicitacaoResultado.fornecedoresVencedores({
          'itens': [
            _item(1),
            _item(2, tipoValor: tipoValor, tipoProposta: proposta),
            _item(3),
          ],
        }, _edital({1: 2, 2: 2, 3: 2})).single;
        expect(fornecedor.itens, [1, 2, 3]);
        expect(fornecedor.valorSugerido, isNull);
      },
    );
  }

  test('quantidade ausente invalida somente o valor do fornecedor afetado', () {
    final fornecedores = LicitacaoResultado.fornecedoresVencedores({
      'itens': [
        _item(1),
        _item(2),
        _item(3, licitantes: [_licitante(ni: '22222222000122')]),
      ],
    }, _edital({1: 2, 3: 3}));
    expect(fornecedores[0].valorSugerido, isNull);
    expect(fornecedores[1].valorSugerido, 30);
  });

  test('quantidade nula não é interpretada como zero', () {
    final fornecedor = LicitacaoResultado.fornecedoresVencedores({
      'itens': [_item(1)],
    }, _edital({1: null})).single;
    expect(fornecedor.valorSugerido, isNull);
  });

  test(
    'valor ausente de um item invalida a soma do fornecedor, inclusive lote',
    () {
      for (final proposta in [1, 2]) {
        final fornecedor = LicitacaoResultado.fornecedoresVencedores({
          'itens': [
            _item(1),
            _item(
              2,
              tipoProposta: proposta,
              licitantes: [_licitante(valor: null)],
            ),
            _item(3),
          ],
        }, _edital({1: 2, 2: 2, 3: 2})).single;
        expect(fornecedor.valorSugerido, isNull);
      }
    },
  );

  test(
    'limitarItens filtra fornecedores e recalcula valor só dos itens da ata',
    () {
      final doc = {
        'itens': [
          _item(1, tipoValor: 'P'),
          _item(2),
          _item(3, licitantes: [_licitante(ni: '22222222000122')]),
          _item(4),
        ],
      };
      final edital = _edital({1: 2, 2: 3, 3: 4, 4: 5});
      final fornecedor = LicitacaoResultado.fornecedoresVencedores(
        doc,
        edital,
        limitarItens: {2, 4, 99},
      ).single;
      expect(fornecedor.itens, [2, 4]);
      expect(fornecedor.valorSugerido, 80);
      expect(
        LicitacaoResultado.fornecedoresVencedores(
          doc,
          edital,
          limitarItens: {},
        ),
        isEmpty,
      );
    },
  );

  test('nome ausente é retornado vazio sem impedir a sugestão', () {
    final fornecedor = LicitacaoResultado.fornecedoresVencedores({
      'itens': [
        _item(1, licitantes: [_licitante(nome: null)]),
      ],
    }, _edital({1: 2})).single;
    expect(fornecedor.nomeRazaoSocial, isEmpty);
    expect(fornecedor.niPessoa, '12345678000190');
    expect(fornecedor.valorSugerido, 20);
  });

  test('calcula cada fornecedor quando há vários vencedores no mesmo item', () {
    final fornecedores = LicitacaoResultado.fornecedoresVencedores({
      'itens': [
        _item(
          1,
          licitantes: [
            _licitante(valor: 5),
            _licitante(ni: '22222222000122', valor: 8),
          ],
        ),
      ],
    }, _edital({1: 3}));
    expect(fornecedores.map((f) => f.itens), [
      [1],
      [1],
    ]);
    expect(fornecedores.map((f) => f.valorSugerido), [15, 24]);
  });
}
