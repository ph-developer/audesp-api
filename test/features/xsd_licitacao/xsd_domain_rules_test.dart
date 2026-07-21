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
    expect(fundamento.code, 2);
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
  });
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
