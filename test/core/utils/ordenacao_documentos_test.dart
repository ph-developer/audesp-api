import 'package:audesp_api/core/utils/ordenacao_documentos.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Doc = ({String id, ChaveOrdenacao chave});

_Doc _doc(
  String id, {
  int dia = 1,
  String codigo = '',
  String modalidade = '',
  String numero = '',
  int ano = 0,
}) => (
  id: id,
  chave: ChaveOrdenacao(
    data: DateTime(2026, 1, dia),
    codigo: codigo,
    modalidade: modalidade,
    numero: numero,
    ano: ano,
  ),
);

List<String> _ordenar(
  List<_Doc> docs,
  OrdenarPor por, {
  bool decrescente = true,
}) => ordenarDocumentos(
  docs,
  por: por,
  decrescente: decrescente,
  chave: (d) => d.chave,
).map((d) => d.id).toList();

String _pncp(int sequencial, int ano, {int? ata}) =>
    '46523163000150-1-${'$sequencial'.padLeft(6, '0')}/$ano'
    '${ata == null ? '' : '-${'$ata'.padLeft(6, '0')}'}';

void main() {
  group('ordenarDocumentos', () {
    test('data: mais recente primeiro ou o inverso', () {
      final docs = [_doc('a', dia: 2), _doc('b', dia: 5), _doc('c', dia: 1)];

      expect(_ordenar(docs, OrdenarPor.data), ['b', 'a', 'c']);
      expect(_ordenar(docs, OrdenarPor.data, decrescente: false), [
        'c',
        'a',
        'b',
      ]);
    });

    test('código PNCP ordena por ano e depois sequencial', () {
      final docs = [
        _doc('10/2025', codigo: _pncp(10, 2025)),
        _doc('2/2026', codigo: _pncp(2, 2026)),
        _doc('9/2026', codigo: _pncp(9, 2026).replaceAll(RegExp(r'\D'), '')),
      ];

      expect(_ordenar(docs, OrdenarPor.codigo, decrescente: false), [
        '10/2025',
        '2/2026',
        '9/2026',
      ]);
      expect(_ordenar(docs, OrdenarPor.codigo), [
        '9/2026',
        '2/2026',
        '10/2025',
      ]);
    });

    test('código de ata considera o sequencial da ata', () {
      final docs = [
        _doc('ata 2', codigo: _pncp(5, 2026, ata: 2)),
        _doc('ata 1', codigo: _pncp(5, 2026, ata: 1)),
      ];

      expect(_ordenar(docs, OrdenarPor.codigo, decrescente: false), [
        'ata 1',
        'ata 2',
      ]);
    });

    test('códigos locais vêm depois dos PNCP, em ordem natural', () {
      final docs = [
        _doc('PE 10', codigo: 'PE 10/2026'),
        _doc('pncp', codigo: _pncp(1, 2026)),
        _doc('PE 2', codigo: 'PE 2/2026'),
      ];

      expect(_ordenar(docs, OrdenarPor.codigo, decrescente: false), [
        'pncp',
        'PE 2',
        'PE 10',
      ]);
    });

    test(
      'licitação: modalidade A–Z, depois ano e número; sem edital no fim',
      () {
        final docs = [
          _doc('adesão'),
          _doc(
            'PE 9/2026',
            modalidade: 'Pregão Eletrônico',
            numero: '9',
            ano: 2026,
          ),
          _doc('CC 1/2026', modalidade: 'Concorrência', numero: '1', ano: 2026),
          _doc(
            'PE 10/2026',
            modalidade: 'Pregão Eletrônico',
            numero: '10',
            ano: 2026,
          ),
          _doc(
            'PE 50/2025',
            modalidade: 'Pregão Eletrônico',
            numero: '050',
            ano: 2025,
          ),
        ];

        expect(_ordenar(docs, OrdenarPor.licitacao), [
          'CC 1/2026',
          'PE 10/2026',
          'PE 9/2026',
          'PE 50/2025',
          'adesão',
        ]);
        expect(_ordenar(docs, OrdenarPor.licitacao, decrescente: false), [
          'CC 1/2026',
          'PE 50/2025',
          'PE 9/2026',
          'PE 10/2026',
          'adesão',
        ]);
      },
    );

    test('empate cai na data mais recente', () {
      final docs = [
        _doc('antigo', dia: 1, codigo: 'X'),
        _doc('novo', dia: 9, codigo: 'X'),
      ];

      expect(_ordenar(docs, OrdenarPor.codigo, decrescente: false), [
        'novo',
        'antigo',
      ]);
    });
  });

  test('compararNatural trata dígitos como números', () {
    expect(compararNatural('2', '10'), lessThan(0));
    expect(compararNatural('007', '7'), 0);
    expect(compararNatural('ab', 'AB'), 0);
    expect(compararNatural('a1', 'a1b'), lessThan(0));
  });
}
