import 'package:audesp_api/features/licitacao/domain/licitacao_rules.dart';
import 'package:flutter_test/flutter_test.dart';

final _hoje = DateTime(2026, 10, 27, 15, 30);

Map<String, dynamic> _item(
  int numero, {
  List<Map<String, dynamic>> licitantes = const [],
}) => {
  'numeroItem': numero,
  'tipoOrcamento': 0,
  'dataSituacaoItem': '2026-10-27',
  'situacaoCompraItemId': 2,
  'licitantes': licitantes,
};

Map<String, dynamic> _licitante(
  String ni, {
  String tipo = 'PJ',
  int resultado = 1,
}) => {'tipoPessoaId': tipo, 'niPessoa': ni, 'resultadoHabilitacao': resultado};

Map<String, dynamic> _edital({
  int modalidade = 6,
  bool srp = false,
  int beneficio = 4,
}) => {
  'modalidadeId': modalidade,
  'srp': srp,
  'itensCompra': [
    {'numeroItem': 7, 'tipoBeneficioId': beneficio},
  ],
};

void main() {
  group('itens e licitantes', () {
    test(
      'exige todos os números do edital e impede duplicidade sem referência',
      () {
        expect(
          LicitacaoRules.validarItens(
            [_item(1)],
            edital: _edital(),
            hoje: _hoje,
          ),
          contains('Item 7 do edital'),
        );
        expect(
          LicitacaoRules.validarItens([_item(1), _item(1)], hoje: _hoje),
          contains('Item 1 repetido'),
        );
      },
    );

    test(
      'homologado exige licitante, exceto dispensa, inexigibilidade e credenciamento',
      () {
        for (final modalidade in [1, 6, 8, 9, 12, 15, 19]) {
          expect(
            LicitacaoRules.validarItens(
              [_item(7)],
              edital: _edital(modalidade: modalidade),
              hoje: _hoje,
            ),
            [8, 9, 12].contains(modalidade)
                ? isNull
                : contains('Item 7 homologado'),
          );
        }
      },
    );

    test('demais situações e modalidade desconhecida dispensam licitantes', () {
      for (final situacao in [1, 3, 4, 5, 6, null]) {
        final item = _item(7)..['situacaoCompraItemId'] = situacao;
        expect(
          LicitacaoRules.validarItens([item], edital: _edital(), hoje: _hoje),
          isNull,
        );
      }
      expect(LicitacaoRules.validarItens([_item(7)], hoje: _hoje), isNull);
      expect(
        LicitacaoRules.validarItens([_item(7)], edital: {}, hoje: _hoje),
        isNull,
      );
    });

    test('duplica por tipo + identificação normalizada e preserva PE', () {
      for (final tipo in ['PJ', 'PF']) {
        expect(
          LicitacaoRules.validarLicitantesDuplicados([
            _licitante('11.222-33', tipo: tipo),
            _licitante('1122233', tipo: tipo),
          ], numeroItem: 7),
          contains('Item 7'),
        );
      }
      expect(
        LicitacaoRules.validarLicitantesDuplicados([
          _licitante('123', tipo: 'PJ'),
          _licitante('123', tipo: 'PF'),
          _licitante('AB-123', tipo: 'PE'),
          _licitante('AB123', tipo: 'PE'),
        ], numeroItem: 7),
        isNull,
      );
      expect(
        LicitacaoRules.validarLicitantesDuplicados([
          _licitante(' AB-123 ', tipo: 'PE'),
          _licitante('AB-123', tipo: 'PE'),
        ], numeroItem: 7),
        contains('Item 7'),
      );
    });

    test('um mesmo licitante pode participar de itens diferentes', () {
      final licitante = _licitante('11222333000144');
      expect(
        LicitacaoRules.validarItens([
          _item(7, licitantes: [licitante]),
          _item(8, licitantes: [licitante]),
        ], hoje: _hoje),
        isNull,
      );
    });

    test(
      'limita vencedores por item, com exceções de cota reservada e SRP',
      () {
        for (final srp in [false, true]) {
          for (final beneficio in [1, 2, 3, 4, 5]) {
            for (final quantidade in [1, 2, 3]) {
              final item = _item(
                7,
                licitantes: [
                  for (var i = 0; i < quantidade; i++) _licitante('100$i'),
                  _licitante('2000', resultado: 2),
                ],
              );
              final limite = beneficio == 3 ? 2 : 1;
              expect(
                LicitacaoRules.validarItens(
                  [item],
                  edital: _edital(srp: srp, beneficio: beneficio),
                  hoje: _hoje,
                ),
                srp || quantidade <= limite ? isNull : contains('Item 7'),
                reason:
                    'SRP $srp, benefício $beneficio, vencedores $quantidade',
              );
            }
          }
        }
      },
    );

    test('SRP não dispensa unicidade do licitante', () {
      final item = _item(7, licitantes: [_licitante('123'), _licitante('123')]);
      expect(
        LicitacaoRules.validarItens(
          [item],
          edital: _edital(srp: true),
          hoje: _hoje,
        ),
        contains('mais de uma vez'),
      );
    });

    test('pula apenas limites que dependem de referência local ausente', () {
      final item = _item(
        7,
        licitantes: [_licitante('1'), _licitante('2'), _licitante('3')],
      );
      for (final edital in <Map<String, dynamic>?>[
        null,
        {},
        {'srp': false},
        {
          'itensCompra': [
            {'numeroItem': 7, 'tipoBeneficioId': 4},
          ],
        },
      ]) {
        expect(
          LicitacaoRules.validarItens([item], edital: edital, hoje: _hoje),
          isNull,
        );
      }
    });
  });

  group('datas e orçamento', () {
    test('situação é obrigatória e aceita limites inclusivos sem horário', () {
      expect(
        LicitacaoRules.validarDataSituacaoItem(null, hoje: _hoje),
        isNotNull,
      );
      for (final data in [
        DateTime(1996, 10, 27),
        DateTime(2026, 10, 27, 23, 59),
      ]) {
        expect(
          LicitacaoRules.validarDataSituacaoItem(data, hoje: _hoje),
          isNull,
        );
      }
      for (final data in [DateTime(1996, 10, 26), DateTime(2026, 10, 28)]) {
        expect(
          LicitacaoRules.validarDataSituacaoItem(data, hoje: _hoje),
          isNotNull,
        );
      }
    });

    test('subtração de 30 anos em 29 de fevereiro usa último dia do mês', () {
      final hoje = DateTime(2028, 2, 29);
      expect(
        LicitacaoRules.dataMinimaSituacaoItem(hoje),
        DateTime(1998, 2, 28),
      );
      expect(
        LicitacaoRules.validarDataSituacaoItem(
          DateTime(1998, 2, 28),
          hoje: hoje,
        ),
        isNull,
      );
      expect(
        LicitacaoRules.validarDataSituacaoItem(
          DateTime(1998, 2, 27),
          hoje: hoje,
        ),
        isNotNull,
      );
    });

    test(
      'tipo diferente de zero exige valor, inclusive aceitando valor zero',
      () {
        for (final tipo in [0, 1, 2]) {
          expect(
            LicitacaoRules.validarValorOrcamento(
              tipoOrcamento: tipo,
              valor: null,
            ),
            tipo == 0 ? isNull : isNotNull,
          );
          expect(
            LicitacaoRules.validarValorOrcamento(tipoOrcamento: tipo, valor: 0),
            isNull,
          );
        }
      },
    );

    test(
      'data do orçamento depende do valor, inclusive zero, e não do tipo',
      () {
        expect(
          LicitacaoRules.validarDataOrcamento(valor: null, dataOrcamento: null),
          isNull,
        );
        for (final valor in [0, 1, 12.50]) {
          expect(
            LicitacaoRules.validarDataOrcamento(
              valor: valor,
              dataOrcamento: null,
            ),
            isNotNull,
          );
          expect(
            LicitacaoRules.validarDataOrcamento(
              valor: valor,
              dataOrcamento: _hoje,
            ),
            isNull,
          );
        }
      },
    );

    test('confere dados importados no envio e cita o número do item', () {
      final invalidos = [
        _item(21)..remove('dataSituacaoItem'),
        _item(21)..['dataSituacaoItem'] = '1996-10-26',
        _item(21)..['dataSituacaoItem'] = '2026-10-28',
        _item(21)..['dataSituacaoItem'] = '2026-02-30',
        _item(21)..['tipoOrcamento'] = 2,
        _item(21)..['valor'] = 0,
        _item(21)..addAll({'valor': 10, 'dataOrcamento': 'inválida'}),
        _item(21, licitantes: [_licitante('1'), _licitante('1')]),
      ];
      for (final item in invalidos) {
        expect(
          LicitacaoRules.validarEnvio({
            'itens': [_item(1), item],
          }, hoje: _hoje),
          contains('Item 21'),
        );
      }
      expect(
        LicitacaoRules.validarEnvio({
          'itens': [
            _item(21)..addAll({'valor': 0, 'dataOrcamento': '2026-01-01'}),
          ],
        }, hoje: _hoje),
        isNull,
      );
    });
  });
}
