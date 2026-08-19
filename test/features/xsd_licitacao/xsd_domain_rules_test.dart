import 'package:audesp_api/features/xsd_licitacao/models/xsd_licitacao_models.dart';
import 'package:audesp_api/features/xsd_licitacao/services/xsd_domain_rules.dart';
import 'package:audesp_api/features/xsd_licitacao/services/xsd_source_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seleção de variante', () {
    test('dispensa e inexigibilidade usam NÃO3', () {
      expect(
        XsdDomainRules.selectVariant(_source(modalidade: 8)),
        XsdLicitacaoVariant.nao3,
      );
      expect(
        XsdDomainRules.selectVariant(_source(modalidade: 9)),
        XsdLicitacaoVariant.nao3,
      );
    });

    test('bloqueia SRP, carona e modalidade internacional', () {
      expect(
        () => XsdDomainRules.selectVariant(_source(srp: true)),
        throwsA(isA<XsdDomainException>()),
      );
      expect(
        () => XsdDomainRules.selectVariant(_source(carona: true)),
        throwsA(isA<XsdDomainException>()),
      );
      expect(
        () => XsdDomainRules.selectVariant(_source(modalidade: 16)),
        throwsA(isA<XsdDomainException>()),
      );
    });
  });

  group('propostas', () {
    test('calcula global, unitária e desconto percentual', () {
      final items = [
        _item(quantidade: 3, valorEstimado: 100, valor: 50, tipo: 1),
        _item(quantidade: 4, valorEstimado: 100, valor: 12, tipo: 2),
        _item(
          quantidade: 1,
          valorEstimado: 200,
          valor: 10,
          tipo: 3,
          tipoValor: 'P',
        ),
      ];
      expect(XsdDomainRules.calculateTotal(items), 278);
    });

    test('desconto percentual considera o valor total estimado do lote', () {
      final items = [
        _item(
          quantidade: 3,
          valorEstimado: 100,
          valor: 10,
          tipo: 3,
          tipoValor: 'P',
        ),
      ];

      expect(XsdDomainRules.calculateTotal(items), 270);
    });

    test('mapeia todos os resultados existentes', () {
      expect(
        [for (var id = 1; id <= 7; id++) XsdDomainRules.mapResultado(id)],
        [2, 6, 7, 1, 5, 8, 3],
      );
    });

    test('converte a ordem dos índices econômicos para o XSD', () {
      expect(
        [for (var id = 1; id <= 8; id++) XsdDomainRules.mapIndiceEconomico(id)],
        [7, 5, 6, 2, 4, 1, 3, 8],
      );
    });
  });

  test('converte critérios de julgamento para os códigos do XSD', () {
    expect(
      [
        for (final id in [1, 2, 4, 5, 6, 8, 9, 1000, 1001])
          XsdDomainRules.mapTipoLicitacao(id),
      ],
      [1, 5, 2, 4, 7, 3, 3, 12, 6],
    );
  });

  test('converte natureza da licitação para os códigos do XSD', () {
    expect(
      [for (var id = 1; id <= 8; id++) XsdDomainRules.mapNaturezaLicitacao(id)],
      [1, 8, 6, 5, 4, 7, 3, 2],
    );
  });

  group('fundamento legal', () {
    test('agrupa os subitens da Lei 14.133 nos incisos do XSD', () {
      for (var id = 8; id <= 15; id++) {
        expect(XsdDomainRules.mapFundamento(9, id, null).code, 60);
      }
      for (var id = 61; id <= 70; id++) {
        expect(XsdDomainRules.mapFundamento(8, id, null).code, 79);
      }
      for (var id = 71; id <= 76; id++) {
        expect(XsdDomainRules.mapFundamento(8, id, null).code, 80);
      }
    });

    test('converte os fundamentos da Lei 13.303 aceitos pelo XSD', () {
      expect(XsdDomainRules.mapFundamento(9, 104, null).code, 55);
      for (var id = 105; id <= 111; id++) {
        expect(XsdDomainRules.mapFundamento(9, id, null).code, 56);
      }
      for (var id = 84; id <= 98; id++) {
        expect(XsdDomainRules.mapFundamento(8, id, null).code, id - 44);
      }
    });

    test('bloqueia fundamentos sem representação no XSD 2026_A', () {
      for (final id in [60, 77, 78, 99, 100, 101]) {
        expect(
          () => XsdDomainRules.mapFundamento(8, id, null),
          throwsA(isA<XsdDomainException>()),
        );
      }
      for (final id in [102, 103]) {
        expect(
          () => XsdDomainRules.mapFundamento(9, id, null),
          throwsA(isA<XsdDomainException>()),
        );
      }
    });
  });

  test('mapeia benefícios PNCP para o domínio de três valores do XSD', () {
    expect(
      XsdDomainRules.mapBeneficio([
        {'tipoBeneficioId': 1},
      ]),
      2,
    );
    expect(
      XsdDomainRules.mapBeneficio([
        {'tipoBeneficioId': 2},
      ]),
      3,
    );
    expect(
      XsdDomainRules.mapBeneficio([
        {'tipoBeneficioId': 3},
      ]),
      3,
    );
    expect(
      XsdDomainRules.mapBeneficio([
        {'tipoBeneficioId': 4},
      ]),
      1,
    );
    expect(
      XsdDomainRules.mapBeneficio([
        {'tipoBeneficioId': 5},
      ]),
      1,
    );
  });

  test('perfil preserva snapshot da comissão no JSON', () {
    const profile = XsdLicitacaoProfile(
      comissao: [
        XsdComissaoMembro(
          cpf: '12345678901',
          nome: 'Pessoa',
          atribuicao: 1,
          cargo: 'Agente',
          naturezaCargo: 1,
        ),
      ],
      numAtoDesignacao: '10',
      anoAtoDesignacao: 2026,
    );
    final reopened = XsdLicitacaoProfile.decode(profile.encode());
    expect(reopened.comissao.single.nome, 'Pessoa');
    expect(reopened.numAtoDesignacao, '10');
  });

  test('amparo do edital prevalece sobre valor complementar antigo', () {
    final fundamento = XsdDomainRules.mapFundamento(9, 6, 18);

    expect(fundamento.element, 'FundamentoLei14133Art74');
    expect(fundamento.code, 58);
  });

  test('normalizador sempre omite enquadramento LRF salvo anteriormente', () {
    const normalizer = XsdSourceNormalizer();
    final profile = normalizer.mergeProfile(
      source: _source(),
      persisted: const XsdLicitacaoProfile(lrf: XsdLrfEnquadramento.artigo16),
    );

    expect(profile.lrf, XsdLrfEnquadramento.omitido);
  });

  test('normalizador importa situação, tributos e recursos da licitação', () {
    const normalizer = XsdSourceNormalizer();
    final source = normalizer.normalize(
      edital: {
        'modalidadeId': 9,
        'numeroCompra': '1',
        'anoCompra': 2026,
        'numeroProcesso': '1',
        'objetoCompra': 'Objeto',
        'amparoLegalId': 6,
      },
      licitacao: {
        'descritor': {
          'municipio': 1,
          'entidade': 1,
          'codigoEdital': '1234567890123410001232026',
        },
        'quitacaoTributosFederais': true,
        'quitacaoTributosEstaduais': false,
        'quitacaoTributosMunicipais': true,
        'declaracaoRecursosContratacao': true,
        'tipoNatureza': 2,
        'fonteRecursosContratacao': [1, 91],
        'itens': [
          {'dataSituacaoItem': '2026-02-01'},
          {'dataSituacaoItem': '2026-03-15'},
        ],
      },
    );
    final profile = normalizer.mergeProfile(source: source);

    expect(source.editalData, isNull);
    expect(source.amparoLegalId, 6);
    expect(profile.situacaoData, DateTime(2026, 3, 15));
    expect(profile.tributosFederais, isTrue);
    expect(profile.tributosEstaduais, isFalse);
    expect(profile.tributosMunicipais, isTrue);
    expect(profile.recursos.declarados, isTrue);
    expect(profile.recursos.fontes, [1]);
    expect(profile.opcionais['naturezaLicitacao'], 8);
  });

  test(
    'normalizador completa os lotes com quantidade e descrição do edital',
    () {
      const normalizer = XsdSourceNormalizer();
      final source = normalizer.normalize(
        edital: {
          'modalidadeId': 6,
          'itensCompra': [
            {
              'numeroItem': 2,
              'descricao': 'Serviço do lote',
              'quantidade': 3.5,
              'unidadeMedida': 'UN',
            },
          ],
        },
        licitacao: {
          'itens': [
            {
              'numeroItem': 2,
              'licitantes': [
                {'niPessoa': '123'},
              ],
            },
          ],
        },
      );

      expect(source.itens.single['descricao'], 'Serviço do lote');
      expect(source.itens.single['quantidade'], 3.5);
      expect(source.itens.single['unidadeMedida'], 'UN');
      expect(source.itens.single['licitantes'], hasLength(1));
    },
  );
}

Map<String, dynamic> _item({
  double quantidade = 1,
  double valorEstimado = 100,
  double valor = 10,
  int tipo = 1,
  String tipoValor = 'M',
}) => {
  'numeroItem': 1,
  'descricao': 'Item',
  'quantidade': quantidade,
  'valorUnitarioEstimado': valorEstimado,
  'licitantes': [
    {
      'resultadoHabilitacao': 1,
      'valor': valor,
      'tipoProposta': tipo,
      'tipoValor': tipoValor,
    },
  ],
};

XsdLicitacaoSource _source({
  int modalidade = 6,
  bool srp = false,
  bool carona = false,
}) => XsdLicitacaoSource(
  modalidadeId: modalidade,
  srp: srp,
  carona: carona,
  municipio: '0000',
  entidade: '000000',
  codigoEdital: '1234567890123410001232026',
  numeroCompra: '1',
  anoCompra: 2026,
  numeroProcesso: '1',
  objeto: 'Objeto',
  criterioJulgamentoId: 1,
  amparoLegalId: modalidade == 8
      ? 18
      : modalidade == 9
      ? 6
      : 1,
  editalData: DateTime(2026),
  situacaoData: DateTime(2026),
  quitacaoTributosFederais: false,
  quitacaoTributosEstaduais: false,
  quitacaoTributosMunicipais: false,
  declaracaoRecursos: false,
  fontesRecursos: const [],
  parecerTecnicoJuridico: false,
  entregaPropostaData: null,
  aberturaData: null,
  itens: [_item()],
  editalJson: const {},
  licitacaoJson: const {},
);
