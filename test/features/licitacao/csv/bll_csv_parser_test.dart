import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/features/licitacao/csv/parsers/bll_csv_parser.dart';
import 'package:audesp_api/features/licitacao/csv/parsers/portal_csv_parser.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Cabeçalho + 4 licitantes para o item 1 do BLL.
const _classificacaoCsv = '''
"Lote","Item","Posição","Razão Social","Documento","Lance","Marca","Modelo","ME","Classificado","Habilitado"
"1","1","1","OLLA MAGNETICA LTDA","14733837000154","19600,0000","PIGEONS","LH120","SIM","SIM","SIM"
"1","1","2","ZANON CONSTRUÇÕES LTDA","28801237000190","19750,0000","bird","control","SIM","SIM","SIM"
"1","1","3","TAFF SERVIÇOS EIRELI","29558192000138","41908,3500","test","LH-120","SIM","SIM","SIM"
"1","1","4","MICHEL BURANI","39478217000147","17517,4400","N/A","N/A","SIM","NÃO","SIM"
''';

List<int> _toBytes(String s) => utf8.encode(s);

void main() {
  group('BllCsvParser', () {
    late BllCsvParser parser;

    setUp(() => parser = const BllCsvParser());

    test('vencedor (posição 1) recebe resultadoHabilitacao = 1', () {
      final result = parser.parse({
        CsvFileKeys.bllClassificacao: _toBytes(_classificacaoCsv),
      });

      final vencedor = result.first.licitantes.first;
      expect(vencedor.resultadoHabilitacao, 1);
      expect(vencedor.nomeRazaoSocial, 'OLLA MAGNETICA LTDA');
      expect(vencedor.niPessoa, '14733837000154');
      expect(vencedor.tipoPessoaId, 'PJ');
    });

    test('posição 2 classificado SIM → resultadoHabilitacao = 2', () {
      final result = parser.parse({
        CsvFileKeys.bllClassificacao: _toBytes(_classificacaoCsv),
      });

      final segundo = result.first.licitantes[1];
      expect(segundo.resultadoHabilitacao, 2);
    });

    test('classificado NÃO → resultadoHabilitacao = 4', () {
      final result = parser.parse({
        CsvFileKeys.bllClassificacao: _toBytes(_classificacaoCsv),
      });

      final desclass = result.first.licitantes[3];
      expect(desclass.resultadoHabilitacao, 4);
    });

    test('ME "SIM" → declaracaoMEouEPP = 1', () {
      final result = parser.parse({
        CsvFileKeys.bllClassificacao: _toBytes(_classificacaoCsv),
      });

      expect(result.first.licitantes.first.declaracaoMEouEPP, 1);
    });

    test('valorProposta é convertido corretamente', () {
      final result = parser.parse({
        CsvFileKeys.bllClassificacao: _toBytes(_classificacaoCsv),
      });

      expect(
        result.first.licitantes.first.valorProposta,
        closeTo(19600.0, 0.001),
      );
    });

    test('resultado final ordena itens numericamente', () {
      const multi = '''
"Lote","Item","Posição","Razão Social","Documento","Lance","Marca","Modelo","ME","Classificado","Habilitado"
"1","2","1","EMP B","28801237000190","500,00","x","y","NÃO","SIM","SIM"
"1","1","1","EMP A","14733837000154","300,00","a","b","SIM","SIM","SIM"
''';
      final result = parser.parse({
        CsvFileKeys.bllClassificacao: _toBytes(multi),
      });

      expect(result[0].numeroItem, 1);
      expect(result[1].numeroItem, 2);
    });
  });
}
