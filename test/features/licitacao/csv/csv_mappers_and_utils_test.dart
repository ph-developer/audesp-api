import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/features/licitacao/csv/mappers/csv_mappers.dart';
import 'package:audesp_api/features/licitacao/csv/mappers/bll_mapper.dart';
import 'package:audesp_api/features/licitacao/csv/mappers/br_conectado_mapper.dart';
import 'package:audesp_api/features/licitacao/csv/parsers/_csv_utils.dart';

void main() {
  // ---------------------------------------------------------------------------
  // CsvMappers
  // ---------------------------------------------------------------------------
  group('CsvMappers', () {
    group('cleanNiPessoa', () {
      test('remove pontos, barras e traços de CNPJ', () {
        expect(
          CsvMappers.cleanNiPessoa('14.733.837/0001-54'),
          '14733837000154',
        );
      });

      test('remove pontos e traços de CPF', () {
        expect(CsvMappers.cleanNiPessoa('330.206.793-89'), '33020679389');
      });

      test('mantém número já limpo', () {
        expect(CsvMappers.cleanNiPessoa('14733837000154'), '14733837000154');
      });
    });

    group('tipoPessoaFromCleanNi', () {
      test('14 dígitos → PJ', () {
        expect(
          CsvMappers.tipoPessoaFromCleanNi('14733837000154'),
          'PJ',
        );
      });

      test('11 dígitos → PF', () {
        expect(
          CsvMappers.tipoPessoaFromCleanNi('33020679389'),
          'PF',
        );
      });

      test('outro comprimento → PE', () {
        expect(CsvMappers.tipoPessoaFromCleanNi('123456'), 'PE');
      });
    });

    group('declaracaoMEouEPP', () {
      test('"SIM" → 1', () => expect(CsvMappers.declaracaoMEouEPP('SIM'), 1));
      test('"sim" (case-insensitive) → 1',
          () => expect(CsvMappers.declaracaoMEouEPP('sim'), 1));
      test('"NÃO" → 3', () => expect(CsvMappers.declaracaoMEouEPP('NÃO'), 3));
      test('"NAO" → 3', () => expect(CsvMappers.declaracaoMEouEPP('NAO'), 3));
      test('vazio → 3', () => expect(CsvMappers.declaracaoMEouEPP(''), 3));
    });

    group('parseBrCurrency', () {
      test('formatos com milhar e decimal', () {
        expect(CsvMappers.parseBrCurrency('19.600,00'), closeTo(19600.0, 0.001));
        expect(CsvMappers.parseBrCurrency('2.200,00'), closeTo(2200.0, 0.001));
        expect(CsvMappers.parseBrCurrency('27,50'), closeTo(27.5, 0.001));
        expect(CsvMappers.parseBrCurrency('19600,0000'), closeTo(19600.0, 0.001));
      });

      test('lança FormatException para entrada inválida', () {
        expect(
          () => CsvMappers.parseBrCurrency('abc'),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // BllMapper
  // ---------------------------------------------------------------------------
  group('BllMapper', () {
    group('resultadoHabilitacao', () {
      test('posicao 1 → 1 (Vencedor)', () {
        expect(
          BllMapper.resultadoHabilitacao(posicao: 1, classificado: 'SIM'),
          1,
        );
      });

      test('posicao 2 + classificado SIM → 2 (Classificado)', () {
        expect(
          BllMapper.resultadoHabilitacao(posicao: 2, classificado: 'SIM'),
          2,
        );
      });

      test('posicao 3 + classificado NÃO → 4 (Desclassificado)', () {
        expect(
          BllMapper.resultadoHabilitacao(posicao: 3, classificado: 'NÃO'),
          4,
        );
      });

      test('posicao 2 + classificado NÃO → 4 (Desclassificado)', () {
        expect(
          BllMapper.resultadoHabilitacao(posicao: 2, classificado: 'NÃO'),
          4,
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // BrConectadoMapper
  // ---------------------------------------------------------------------------
  group('BrConectadoMapper', () {
    group('resultadoHabilitacao', () {
      test('"ADJUDICADO" → 1',
          () => expect(BrConectadoMapper.resultadoHabilitacao('ADJUDICADO'), 1));
      test('"Classificada/Habilitada" → 2', () {
        expect(
          BrConectadoMapper.resultadoHabilitacao('Classificada/Habilitada'),
          2,
        );
      });
      test('"DESCLASSIFICADO" → 4',
          () => expect(BrConectadoMapper.resultadoHabilitacao('DESCLASSIFICADO'), 4));
      test('"DESCLASSIFICADA" → 4',
          () => expect(BrConectadoMapper.resultadoHabilitacao('DESCLASSIFICADA'), 4));
      test('desconhecido → 6',
          () => expect(BrConectadoMapper.resultadoHabilitacao('PENDENTE'), 6));
    });

    group('parseNumeroItem', () {
      test('"001" → 1',
          () => expect(BrConectadoMapper.parseNumeroItem('001'), 1));
      test('"010" → 10',
          () => expect(BrConectadoMapper.parseNumeroItem('010'), 10));
      test('lança FormatException em texto',
          () => expect(() => BrConectadoMapper.parseNumeroItem('abc'),
              throwsA(isA<FormatException>())));
    });
  });

  // ---------------------------------------------------------------------------
  // CsvUtils
  // ---------------------------------------------------------------------------
  group('CsvUtils', () {
    group('decodeBytes', () {
      test('decodifica UTF-8 padrão', () {
        final bytes = utf8.encode('Olá,Mundo');
        expect(CsvUtils.decodeBytes(bytes), 'Olá,Mundo');
      });

      test('remove BOM UTF-8', () {
        final bom = [0xEF, 0xBB, 0xBF];
        final content = utf8.encode('Item');
        expect(CsvUtils.decodeBytes([...bom, ...content]), 'Item');
      });

      test('decodifica Latin-1 (fallback)', () {
        // "Razão" em Latin-1
        final bytes = latin1.encode('Razão Social');
        expect(CsvUtils.decodeBytes(bytes), 'Razão Social');
      });
    });

    group('parseCsv', () {
      test('divide linhas por vírgula', () {
        const csv = 'a,b,c\n1,2,3';
        final result = CsvUtils.parseCsv(csv);
        expect(result, [
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ]);
      });

      test('respeita campos entre aspas com vírgula interna', () {
        const csv = '"Lote","Item","Lance"\n"1","1","19.600,00"';
        final result = CsvUtils.parseCsv(csv);
        expect(result[1][2], '19.600,00');
      });

      test('divide por ponto-e-vírgula', () {
        const csv = 'a;b;c\n1;2;3';
        final result = CsvUtils.parseCsv(csv, delimiter: ';');
        expect(result, [
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ]);
      });

      test('ignora linhas vazias', () {
        const csv = 'a,b\n\n1,2\n';
        expect(CsvUtils.parseCsv(csv).length, 2);
      });
    });

    group('getField / buildHeaderIndex', () {
      test('retorna valor pelo nome da coluna', () {
        final header = CsvUtils.buildHeaderIndex(['Lote', 'Item', 'Lance']);
        final row = ['1', '2', '19600'];
        expect(CsvUtils.getField(row, header, 'Item'), '2');
      });

      test('busca case-insensitive', () {
        final header = CsvUtils.buildHeaderIndex(['Razão Social']);
        final row = ['Empresa X'];
        expect(CsvUtils.getField(row, header, 'razão social'), 'Empresa X');
      });

      test('lança StateError para coluna inexistente', () {
        final header = CsvUtils.buildHeaderIndex(['A']);
        expect(
          () => CsvUtils.getField(['x'], header, 'B'),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
