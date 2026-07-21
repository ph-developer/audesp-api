import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/features/licitacao/csv/parsers/br_conectado_csv_parser.dart';
import 'package:audesp_api/features/licitacao/csv/parsers/portal_csv_parser.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// relatclassificacao.csv com 4 itens (001 adjudicado, 002 adjudicado,
/// 003 adjudicado, 004 desclassificado).
const _relatCsv = '''
Lote/Item;Classificação;Razão Social;Valor Uni.;Valor Total;Situação;CNPJ;REPRESENTANTE LEGAL;CPF REPRESENTANTE
001;1;MEIRI MITIKO SUZUKI NAKAMURA EPP;27,50;2.200,00;ADJUDICADO;03.688.940/0001-03;LUCILIA CAXETA;042.432.098-39
002;1;MEIRI MITIKO SUZUKI NAKAMURA EPP;36,00;1.800,00;ADJUDICADO;03.688.940/0001-03;LUCILIA CAXETA;042.432.098-39
003;1;MEIRI MITIKO SUZUKI NAKAMURA EPP;290,00;5.800,00;ADJUDICADO;03.688.940/0001-03;LUCILIA CAXETA;042.432.098-39
004;1;MEIRI MITIKO SUZUKI NAKAMURA EPP;260,00;5.200,00;DESCLASSIFICADO;03.688.940/0001-03;LUCILIA CAXETA;042.432.098-39
''';

List<int> _toBytes(String s) => utf8.encode(s);

/// Codifica em Latin-1 (simula arquivo do portal com encoding antigo).
List<int> _toLatin1(String s) => latin1.encode(s);

void main() {
  group('BrConectadoCsvParser', () {
    late BrConectadoCsvParser parser;

    setUp(() => parser = const BrConectadoCsvParser());

    test('retorna 4 itens', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result, hasLength(4));
    });

    test('itens são ordenados numericamente', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result.map((e) => e.numeroItem).toList(), [1, 2, 3, 4]);
    });

    test('resultadoHabilitacao = 1 para ADJUDICADO', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result[0].licitantes.first.resultadoHabilitacao, 1);
    });

    test('resultadoHabilitacao = 4 para DESCLASSIFICADO', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result[3].licitantes.first.resultadoHabilitacao, 4);
    });

    test('CNPJ é limpo da máscara', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result[0].licitantes.first.niPessoa, '03688940000103');
    });

    test('tipoPessoaId = PJ para CNPJ', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result[0].licitantes.first.tipoPessoaId, 'PJ');
    });

    test('declaracaoMEouEPP é sempre 3 (Não)', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result[0].licitantes.first.declaracaoMEouEPP, 3);
    });

    test('valorProposta convertido corretamente', () {
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toBytes(_relatCsv),
      });

      expect(result[0].licitantes.first.valorProposta, closeTo(27.5, 0.001));
    });

    test('aceita arquivos em Latin-1', () {
      // Recria a fixture em Latin-1 (simula arquivo real do portal).
      final result = parser.parse({
        CsvFileKeys.brRelatClassificacao: _toLatin1(_relatCsv),
      });

      expect(result, hasLength(4));
      expect(
        result[0].licitantes.first.nomeRazaoSocial,
        'MEIRI MITIKO SUZUKI NAKAMURA EPP',
      );
    });

    test('lança CsvParseException quando relatclassificacao está ausente', () {
      expect(() => parser.parse({}), throwsA(isA<CsvParseException>()));
    });
  });
}
