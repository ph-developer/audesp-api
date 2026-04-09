import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/features/edital/csv/edital_csv.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<int> _toBytes(String s) => utf8.encode(s);

List<int> _toBytesLatin1(String s) => latin1.encode(s);

List<int> _withUtf8Bom(String s) => [0xEF, 0xBB, 0xBF, ..._toBytes(s)];

/// CSV mínimo válido para o Edital (sem valores opcionais).
const _csvMinimo = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Cadeira ergonômica;M;10;UN
2;Serviço de limpeza;S;1;MES
''';

/// CSV completo com todas as colunas do template estendido.
const _csvCompleto = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitarioMenor;CriterioJulgamento;TipoBeneficio;TipoOrcamento;ValorEstimadoMedia;DataOrcamento;SituacaoCompraItem;DataSituacao;TipoValor;TipoProposta
1;Cadeira ergonômica;M;10;UN;800,00;MENOR_PRECO;SEM_BENEFICIO;GLOBAL;850,00;01/01/2025;HOMOLOGADO;15/01/2025;MOEDA;GLOBAL
2;Mesa escritório;M;5;UN;1.200,50;2;1;GLOBAL;1.300,00;01/01/2025;HOMOLOGADO;15/01/2025;MOEDA;GLOBAL
''';

/// CSV com separação crítica de valores: ValorUnitarioMenor ≠ ValorEstimadoMedia.
const _csvSeparacaoValores = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitarioMenor;ValorEstimadoMedia
1;Item A;M;10;UN;800,00;850,00
''';

void main() {
  // =========================================================================
  // EditalComplementoCsvParser
  // =========================================================================
  group('EditalComplementoCsvParser', () {
    late EditalComplementoCsvParser parser;

    setUp(() => parser = const EditalComplementoCsvParser());

    // -------------------------------------------------------------------------
    // Happy path — campos obrigatórios
    // -------------------------------------------------------------------------
    group('parse mínimo (somente colunas obrigatórias)', () {
      test('retorna 2 itens', () {
        final result = parser.parse(_toBytes(_csvMinimo));
        expect(result, hasLength(2));
      });

      test('item 1 mapeado corretamente', () {
        final item = parser.parse(_toBytes(_csvMinimo)).first;
        expect(item.numeroItem, 1);
        expect(item.descricao, 'Cadeira ergonômica');
        expect(item.materialOuServico, 'M');
        expect(item.quantidade, closeTo(10.0, 0.001));
        expect(item.unidadeMedida, 'UN');
      });

      test('item 2 com MaterialOuServico "S"', () {
        final item = parser.parse(_toBytes(_csvMinimo))[1];
        expect(item.materialOuServico, 'S');
        expect(item.unidadeMedida, 'MES');
      });

      test('campos opcionais são nulos quando colunas ausentes', () {
        final item = parser.parse(_toBytes(_csvMinimo)).first;
        expect(item.valorUnitarioEstimado, isNull);
        expect(item.valorTotal, isNull);
        expect(item.criterioJulgamentoId, isNull);
        expect(item.tipoBeneficioId, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // Separação crítica de valores (Regra de Negócio Central do PRD)
    // -------------------------------------------------------------------------
    group('separação de valores: ValorUnitarioMenor vs ValorEstimadoMedia', () {
      test('valorUnitarioEstimado lê SOMENTE ValorUnitarioMenor (menor valor orçado)', () {
        final item = parser.parse(_toBytes(_csvSeparacaoValores)).first;
        // Deve ler 800,00 (ValorUnitarioMenor), NÃO 850,00 (ValorEstimadoMedia)
        expect(item.valorUnitarioEstimado, closeTo(800.0, 0.001));
      });

      test('ValorEstimadoMedia (coluna de Licitação) é completamente ignorado', () {
        final item = parser.parse(_toBytes(_csvSeparacaoValores)).first;
        // O parser do Edital não deve usar o ValorEstimadoMedia
        expect(item.valorUnitarioEstimado, isNot(closeTo(850.0, 0.001)));
      });

      test('valorTotal calculado como Quantidade × ValorUnitarioMenor', () {
        final item = parser.parse(_toBytes(_csvSeparacaoValores)).first;
        // 10 × 800,00 = 8.000,00
        expect(item.valorTotal, closeTo(8000.0, 0.001));
      });

      test('valorTotal NÃO usa ValorEstimadoMedia para o cálculo', () {
        final item = parser.parse(_toBytes(_csvSeparacaoValores)).first;
        // Se usasse ValorEstimadoMedia, seria 10 × 850 = 8.500,00
        expect(item.valorTotal, isNot(closeTo(8500.0, 0.001)));
      });
    });

    // -------------------------------------------------------------------------
    // CSV completo (todas as colunas do template estendido)
    // -------------------------------------------------------------------------
    group('parse completo (template estendido com colunas de Licitação)', () {
      test('item 1 — ValorUnitarioMenor mapeado para valorUnitarioEstimado', () {
        final item = parser.parse(_toBytes(_csvCompleto)).first;
        expect(item.valorUnitarioEstimado, closeTo(800.0, 0.001));
      });

      test('item 1 — valorTotal calculado: 10 × 800,00 = 8.000,00', () {
        final item = parser.parse(_toBytes(_csvCompleto)).first;
        expect(item.valorTotal, closeTo(8000.0, 0.001));
      });

      test('item 1 — criterioJulgamentoId mapeado de texto "MENOR_PRECO"', () {
        final item = parser.parse(_toBytes(_csvCompleto)).first;
        expect(item.criterioJulgamentoId, 1);
      });

      test('item 1 — tipoBeneficioId mapeado de texto "SEM_BENEFICIO"', () {
        final item = parser.parse(_toBytes(_csvCompleto)).first;
        expect(item.tipoBeneficioId, 4);
      });

      test('item 2 — valor com milhar "1.200,50" convertido corretamente', () {
        final item = parser.parse(_toBytes(_csvCompleto))[1];
        expect(item.valorUnitarioEstimado, closeTo(1200.5, 0.001));
      });

      test('item 2 — valorTotal: 5 × 1.200,50 = 6.002,50', () {
        final item = parser.parse(_toBytes(_csvCompleto))[1];
        expect(item.valorTotal, closeTo(6002.5, 0.001));
      });

      test('item 2 — criterioJulgamentoId mapeado de código numérico "2"', () {
        final item = parser.parse(_toBytes(_csvCompleto))[1];
        expect(item.criterioJulgamentoId, 2);
      });

      test('item 2 — tipoBeneficioId mapeado de código numérico "1"', () {
        final item = parser.parse(_toBytes(_csvCompleto))[1];
        expect(item.tipoBeneficioId, 1);
      });

      test('colunas de Licitação (TipoOrcamento, ValorEstimadoMedia, etc.) são ignoradas', () {
        // Garante que a presença dessas colunas não causa erro
        expect(() => parser.parse(_toBytes(_csvCompleto)), returnsNormally);
      });
    });

    // -------------------------------------------------------------------------
    // ValorUnitarioMenor ausente ou em branco
    // -------------------------------------------------------------------------
    group('ValorUnitarioMenor opcional', () {
      test('coluna ValorUnitarioMenor ausente → valorUnitarioEstimado e valorTotal nulos', () {
        final item = parser.parse(_toBytes(_csvMinimo)).first;
        expect(item.valorUnitarioEstimado, isNull);
        expect(item.valorTotal, isNull);
      });

      test('coluna presente mas valor em branco → valorUnitarioEstimado nulo', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitarioMenor
1;Item teste;M;5;UN;
''';
        final item = parser.parse(_toBytes(csv)).first;
        expect(item.valorUnitarioEstimado, isNull);
        expect(item.valorTotal, isNull);
      });

      test('outros campos preenchidos normalmente mesmo sem valor', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitarioMenor
1;Cadeira;M;10;UN;
''';
        final item = parser.parse(_toBytes(csv)).first;
        expect(item.numeroItem, 1);
        expect(item.descricao, 'Cadeira');
        expect(item.quantidade, closeTo(10.0, 0.001));
      });
    });

    // -------------------------------------------------------------------------
    // unidadeMedida em uppercase
    // -------------------------------------------------------------------------
    group('unidadeMedida normalizada para uppercase', () {
      test('"un" → "UN"', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Item;M;1;un
''';
        final item = parser.parse(_toBytes(csv)).first;
        expect(item.unidadeMedida, 'UN');
      });

      test('"m²" → "M²"', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Item;M;1;m²
''';
        final item = parser.parse(_toBytes(csv)).first;
        expect(item.unidadeMedida, 'M²');
      });
    });

    // -------------------------------------------------------------------------
    // Linhas de comentário (iniciadas por #)
    // -------------------------------------------------------------------------
    group('linhas de comentário', () {
      test('linhas com # são ignoradas', () {
        const csv = '''
# Planilha de itens - versão 2.0
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
# Comentário entre linhas
1;Cadeira;M;10;UN
''';
        final result = parser.parse(_toBytes(csv));
        expect(result, hasLength(1));
        expect(result.first.numeroItem, 1);
      });
    });

    // -------------------------------------------------------------------------
    // Linhas em branco / linhas de item com NumeroItem vazio
    // -------------------------------------------------------------------------
    group('linhas em branco e NumeroItem vazio', () {
      test('linhas com NumeroItem vazio são puladas', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Cadeira;M;10;UN
;Linha sem número;M;1;UN
2;Mesa;M;5;UN
''';
        final result = parser.parse(_toBytes(csv));
        expect(result, hasLength(2));
        expect(result.map((e) => e.numeroItem), containsAll([1, 2]));
      });
    });

    // -------------------------------------------------------------------------
    // Encoding
    // -------------------------------------------------------------------------
    group('encoding', () {
      test('UTF-8 padrão processado corretamente', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Serviço de manutenção;S;12;MÊS
''';
        final item = parser.parse(_toBytes(csv)).first;
        expect(item.descricao, 'Serviço de manutenção');
        expect(item.unidadeMedida, 'MÊS');
      });

      test('UTF-8 com BOM processado corretamente', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Item BOM;M;1;UN
''';
        final item = parser.parse(_withUtf8Bom(csv)).first;
        expect(item.descricao, 'Item BOM');
      });

      test('Latin-1 (fallback) processado corretamente', () {
        // "Descrição" em Latin-1
        const header = 'NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida\n';
        const row = '1;Descri\xe7\xe3o Latin;M;3;UN\n';
        final bytes = _toBytesLatin1(header + row);
        final item = parser.parse(bytes).first;
        expect(item.descricao, 'Descrição Latin');
      });
    });

    // -------------------------------------------------------------------------
    // Erros: colunas obrigatórias ausentes
    // -------------------------------------------------------------------------
    group('erros — colunas obrigatórias ausentes', () {
      test('sem NumeroItem → lança EditalCsvParseException', () {
        const csv = '''
Descricao;MaterialOuServico;Quantidade;UnidadeMedida
Cadeira;M;10;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(
            isA<EditalCsvParseException>().having(
              (e) => e.message,
              'message',
              contains('NumeroItem'),
            ),
          ),
        );
      });

      test('sem Descricao → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;MaterialOuServico;Quantidade;UnidadeMedida
1;M;10;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(isA<EditalCsvParseException>()),
        );
      });

      test('sem MaterialOuServico → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;Descricao;Quantidade;UnidadeMedida
1;Cadeira;10;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(isA<EditalCsvParseException>()),
        );
      });

      test('sem Quantidade → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;UnidadeMedida
1;Cadeira;M;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(isA<EditalCsvParseException>()),
        );
      });

      test('sem UnidadeMedida → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade
1;Cadeira;M;10
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(isA<EditalCsvParseException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Erros: valores inválidos nas linhas de dados
    // -------------------------------------------------------------------------
    group('erros — valores inválidos em linhas', () {
      test('NumeroItem não numérico → lança EditalCsvParseException com número da linha', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
abc;Cadeira;M;10;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(
            isA<EditalCsvParseException>().having(
              (e) => e.message,
              'message',
              allOf(contains('NumeroItem'), contains('abc')),
            ),
          ),
        );
      });

      test('Descricao vazia → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;;M;10;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(
            isA<EditalCsvParseException>().having(
              (e) => e.message,
              'message',
              contains('Descricao'),
            ),
          ),
        );
      });

      test('MaterialOuServico inválido → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Cadeira;X;10;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(
            isA<EditalCsvParseException>().having(
              (e) => e.message,
              'message',
              allOf(contains('MaterialOuServico'), contains('X')),
            ),
          ),
        );
      });

      test('Quantidade inválida → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Cadeira;M;abc;UN
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(
            isA<EditalCsvParseException>().having(
              (e) => e.message,
              'message',
              contains('Quantidade'),
            ),
          ),
        );
      });

      test('UnidadeMedida vazia → lança EditalCsvParseException', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Cadeira;M;10;
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(
            isA<EditalCsvParseException>().having(
              (e) => e.message,
              'message',
              contains('UnidadeMedida'),
            ),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Planilha vazia
    // -------------------------------------------------------------------------
    group('planilha vazia', () {
      test('bytes vazios → lança EditalCsvParseException', () {
        expect(
          () => parser.parse(_toBytes('')),
          throwsA(isA<EditalCsvParseException>()),
        );
      });

      test('somente comentários → lança EditalCsvParseException', () {
        const csv = '''
# apenas comentários
# sem dados
''';
        expect(
          () => parser.parse(_toBytes(csv)),
          throwsA(isA<EditalCsvParseException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Ordem e integridade dos itens
    // -------------------------------------------------------------------------
    group('ordem e integridade', () {
      test('retorna itens na mesma ordem do CSV', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
3;Item C;M;1;UN
1;Item A;S;2;UN
2;Item B;M;3;UN
''';
        final result = parser.parse(_toBytes(csv));
        expect(result.map((e) => e.numeroItem).toList(), [3, 1, 2]);
      });

      test('parse de múltiplos itens retorna todos', () {
        final linhas = List.generate(
          5,
          (i) => '${i + 1};Item ${i + 1};M;${i + 1}.0;UN',
        ).join('\n');
        final csv = 'NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida\n$linhas\n';
        final result = parser.parse(_toBytes(csv));
        expect(result, hasLength(5));
      });
    });

    // -------------------------------------------------------------------------
    // Cabeçalho case-insensitive
    // -------------------------------------------------------------------------
    group('cabeçalho case-insensitive', () {
      test('colunas em uppercase são reconhecidas', () {
        const csv = '''
NUMEROITEM;DESCRICAO;MATERIALOUSERVICO;QUANTIDADE;UNIDADEMEDIDA
1;Cadeira;M;10;UN
''';
        final result = parser.parse(_toBytes(csv));
        expect(result, hasLength(1));
        expect(result.first.numeroItem, 1);
      });

      test('colunas em mixed case são reconhecidas', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Cadeira;M;10;UN
''';
        final result = parser.parse(_toBytes(csv));
        expect(result, hasLength(1));
      });
    });

    // -------------------------------------------------------------------------
    // Formatos de número PT-BR
    // -------------------------------------------------------------------------
    group('formato numérico PT-BR', () {
      test('quantidade inteira sem vírgula', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Item;M;10;UN
''';
        expect(parser.parse(_toBytes(csv)).first.quantidade, closeTo(10.0, 0.001));
      });

      test('quantidade com vírgula como decimal', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
1;Item;M;2,5;UN
''';
        expect(parser.parse(_toBytes(csv)).first.quantidade, closeTo(2.5, 0.001));
      });

      test('valor com milhar e decimal "1.200,50"', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitarioMenor
1;Item;M;1;UN;1.200,50
''';
        expect(
          parser.parse(_toBytes(csv)).first.valorUnitarioEstimado,
          closeTo(1200.5, 0.001),
        );
      });

      test('valor com múltiplos separadores de milhar "1.000.000,00"', () {
        const csv = '''
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitarioMenor
1;Item;M;1;UN;1.000.000,00
''';
        expect(
          parser.parse(_toBytes(csv)).first.valorUnitarioEstimado,
          closeTo(1000000.0, 0.001),
        );
      });
    });
  });

  // =========================================================================
  // EditalComplementoCsvMapper
  // =========================================================================
  group('EditalComplementoCsvMapper', () {
    // -------------------------------------------------------------------------
    // materialOuServico
    // -------------------------------------------------------------------------
    group('materialOuServico', () {
      test('"M" → "M"', () {
        expect(EditalComplementoCsvMapper.materialOuServico('M'), 'M');
      });

      test('"m" (lowercase) → "M"', () {
        expect(EditalComplementoCsvMapper.materialOuServico('m'), 'M');
      });

      test('"MATERIAL" → "M"', () {
        expect(EditalComplementoCsvMapper.materialOuServico('MATERIAL'), 'M');
      });

      test('"Material" (mixed case) → "M"', () {
        expect(EditalComplementoCsvMapper.materialOuServico('Material'), 'M');
      });

      test('"S" → "S"', () {
        expect(EditalComplementoCsvMapper.materialOuServico('S'), 'S');
      });

      test('"SERVICO" → "S"', () {
        expect(EditalComplementoCsvMapper.materialOuServico('SERVICO'), 'S');
      });

      test('"SERVIÇO" (com cedilha) → "S"', () {
        expect(EditalComplementoCsvMapper.materialOuServico('SERVIÇO'), 'S');
      });

      test('" M " (com espaços) → "M"', () {
        expect(EditalComplementoCsvMapper.materialOuServico(' M '), 'M');
      });

      test('valor inválido "X" → null', () {
        expect(EditalComplementoCsvMapper.materialOuServico('X'), isNull);
      });

      test('vazio → null', () {
        expect(EditalComplementoCsvMapper.materialOuServico(''), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // criterioJulgamentoId
    // -------------------------------------------------------------------------
    group('criterioJulgamentoId', () {
      test('"MENOR_PRECO" → 1', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('MENOR_PRECO'), 1);
      });

      test('"MENOR PREÇO" → 1', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('MENOR PREÇO'), 1);
      });

      test('"MAIOR_DESCONTO" → 2', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('MAIOR_DESCONTO'), 2);
      });

      test('"TECNICA_PRECO" → 4', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('TECNICA_PRECO'), 4);
      });

      test('"MAIOR_LANCE" → 5', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('MAIOR_LANCE'), 5);
      });

      test('"MAIOR_RETORNO" → 6', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('MAIOR_RETORNO'), 6);
      });

      test('"NAO_SE_APLICA" → 7', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('NAO_SE_APLICA'), 7);
      });

      test('"MELHOR_TECNICA" → 8', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('MELHOR_TECNICA'), 8);
      });

      test('"CONTEUDO_ARTISTICO" → 9', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('CONTEUDO_ARTISTICO'), 9);
      });

      test('código numérico direto "1" → 1', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('1'), 1);
      });

      test('código numérico direto "9" → 9', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('9'), 9);
      });

      test('"menor_preco" (lowercase) → 1', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('menor_preco'), 1);
      });

      test('valor desconhecido "PRECO_GLOBAL" → null', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId('PRECO_GLOBAL'), isNull);
      });

      test('vazio → null', () {
        expect(EditalComplementoCsvMapper.criterioJulgamentoId(''), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // tipoBeneficioId
    // -------------------------------------------------------------------------
    group('tipoBeneficioId', () {
      test('"EXCLUSIVO_ME_EPP" → 1', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('EXCLUSIVO_ME_EPP'), 1);
      });

      test('"EXCLUSIVO ME EPP" → 1', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('EXCLUSIVO ME EPP'), 1);
      });

      test('"SUBCONTRATACAO_ME_EPP" → 2', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('SUBCONTRATACAO_ME_EPP'), 2);
      });

      test('"SUBCONTRATAÇÃO ME EPP" → 2', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('SUBCONTRATAÇÃO ME EPP'), 2);
      });

      test('"COTA_RESERVADA_ME_EPP" → 3', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('COTA_RESERVADA_ME_EPP'), 3);
      });

      test('"SEM_BENEFICIO" → 4', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('SEM_BENEFICIO'), 4);
      });

      test('"SEM BENEFÍCIO" → 4', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('SEM BENEFÍCIO'), 4);
      });

      test('"NAO_SE_APLICA" → 5', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('NAO_SE_APLICA'), 5);
      });

      test('"NÃO SE APLICA" → 5', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('NÃO SE APLICA'), 5);
      });

      test('código numérico direto "3" → 3', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('3'), 3);
      });

      test('"sem_beneficio" (lowercase) → 4', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('sem_beneficio'), 4);
      });

      test('valor desconhecido "COTINHA" → null', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId('COTINHA'), isNull);
      });

      test('vazio → null', () {
        expect(EditalComplementoCsvMapper.tipoBeneficioId(''), isNull);
      });
    });
  });

  // =========================================================================
  // EditalItemCsvModel
  // =========================================================================
  group('EditalItemCsvModel', () {
    test('toString contém campos principais', () {
      const item = EditalItemCsvModel(
        numeroItem: 1,
        descricao: 'Cadeira',
        materialOuServico: 'M',
        quantidade: 10.0,
        unidadeMedida: 'UN',
        valorUnitarioEstimado: 800.0,
      );
      final s = item.toString();
      expect(s, contains('#1'));
      expect(s, contains('Cadeira'));
      expect(s, contains('800.0'));
    });

    test('campos opcionais nulos por padrão', () {
      const item = EditalItemCsvModel(
        numeroItem: 2,
        descricao: 'Mesa',
        materialOuServico: 'M',
        quantidade: 3.0,
        unidadeMedida: 'UN',
      );
      expect(item.valorUnitarioEstimado, isNull);
      expect(item.valorTotal, isNull);
      expect(item.criterioJulgamentoId, isNull);
      expect(item.tipoBeneficioId, isNull);
    });
  });
}
