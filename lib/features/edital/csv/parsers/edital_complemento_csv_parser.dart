import '../../../../core/constants/template_constants.dart';
import '../../../../core/utils/csv_utils.dart';
import '../../../../core/utils/sheet_utils.dart';
import '../mappers/edital_complemento_csv_mapper.dart';
import '../models/edital_item_csv_model.dart';

/// Parser para a planilha de itens do Edital (Template Estendido).
///
/// O arquivo CSV deve usar separador `;` e conter ao menos as colunas
/// obrigatórias (case-insensitive, ordem livre):
///
/// ```
/// NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida
/// ```
///
/// Colunas opcionais reconhecidas:
/// ```
/// ValorUnitarioMenor;CriterioJulgamento;TipoBeneficio;ItemCategoria
/// ```
///
/// Colunas da planilha da Licitação (ex: `ValorEstimadoMedia`, `TipoOrcamento`)
/// presentes no mesmo arquivo são simplesmente ignoradas.
///
/// - Linhas que começam com `#` são ignoradas (comentários).
/// - Valores monetários devem usar notação brasileira (ex: `1.200,50`).
/// - Retorna uma lista de [EditalItemCsvModel] na ordem em que aparecem no CSV.
class EditalComplementoCsvParser {
  const EditalComplementoCsvParser();

  /// Colunas obrigatórias (em lowercase para comparação).
  static const _required = [
    'numeroitem',
    'descricao',
    'materialouservico',
    'quantidade',
    'unidademedida',
  ];

  List<EditalItemCsvModel> parse(List<int> bytes) {
    final rows = SheetUtils.parseRows(
      bytes,
      csvDelimiter: ';',
      csvCommentPrefix: '#',
    );

    if (rows.isEmpty) {
      throw const EditalCsvParseException(
        'Planilha de itens do Edital está vazia.',
      );
    }

    final header = CsvUtils.buildHeaderIndex(
      rows.first,
      aliases: templateItens.headerAliases,
    );

    // Valida colunas obrigatórias.
    for (final col in _required) {
      if (!header.containsKey(col)) {
        throw EditalCsvParseException(
          'Coluna obrigatória "${_prettyName(col)}" não encontrada na planilha.',
        );
      }
    }

    final result = <EditalItemCsvModel>[];

    for (final (index, row) in rows.skip(1).indexed) {
      if (row.length <= 1) continue;

      try {
        final numeroItemStr = _tryGet(row, header, 'numeroitem') ?? '';
        if (numeroItemStr.isEmpty) continue;

        final numeroItem = int.tryParse(numeroItemStr);
        if (numeroItem == null) continue;

        final descricao = _tryGet(row, header, 'descricao') ?? '';
        if (descricao.isEmpty) {
          throw EditalCsvParseException(
            'Linha ${index + 2}: "Descricao" está vazia para o item $numeroItem.',
          );
        }

        final materialOuServicoRaw =
            _tryGet(row, header, 'materialouservico') ?? '';
        final materialOuServico =
            EditalComplementoCsvMapper.materialOuServico(materialOuServicoRaw);
        if (materialOuServico == null) {
          throw EditalCsvParseException(
            'Linha ${index + 2}: valor inválido para "MaterialOuServico": '
            '"$materialOuServicoRaw". Use "M" (Material) ou "S" (Serviço).',
          );
        }

        final quantidadeStr = _tryGet(row, header, 'quantidade') ?? '';
        final quantidade = _parseBrNumber(quantidadeStr);
        if (quantidade == null) {
          throw EditalCsvParseException(
            'Linha ${index + 2}: "Quantidade" inválida para o item $numeroItem: "$quantidadeStr".',
          );
        }

        final unidadeMedida = _tryGet(row, header, 'unidademedida') ?? '';
        if (unidadeMedida.isEmpty) {
          throw EditalCsvParseException(
            'Linha ${index + 2}: "UnidadeMedida" está vazia para o item $numeroItem.',
          );
        }

        // Campos opcionais.
        final valorStr = _tryGet(row, header, 'valorunitariomenor');
        final valorUnitario =
            valorStr != null ? _parseBrNumber(valorStr) : null;

        final valorTotal = (valorUnitario != null)
            ? double.parse(
                (quantidade * valorUnitario).toStringAsFixed(4),
              )
            : null;

        final criterioStr = _tryGet(row, header, 'criteriojulgamento');
        final criterioId = criterioStr != null
            ? EditalComplementoCsvMapper.criterioJulgamentoId(criterioStr)
            : null;

        final beneficioStr = _tryGet(row, header, 'tipobeneficio');
        final beneficioId = beneficioStr != null
            ? EditalComplementoCsvMapper.tipoBeneficioId(beneficioStr)
            : null;

        final categoriaStr = _tryGet(row, header, 'itemcategoria');
        final categoriaId = categoriaStr != null
            ? EditalComplementoCsvMapper.itemCategoriaId(categoriaStr)
            : null;

        result.add(EditalItemCsvModel(
          numeroItem: numeroItem,
          descricao: descricao,
          materialOuServico: materialOuServico,
          quantidade: quantidade,
          unidadeMedida: unidadeMedida.toUpperCase(),
          valorUnitarioEstimado: valorUnitario,
          valorTotal: valorTotal,
          criterioJulgamentoId: criterioId,
          tipoBeneficioId: beneficioId,
          itemCategoriaId: categoriaId,
        ));
      } on EditalCsvParseException {
        rethrow;
      } catch (e) {
        throw EditalCsvParseException(
          'Erro inesperado ao processar linha ${index + 2}: $e',
        );
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String? _tryGet(
    List<String> row,
    Map<String, int> header,
    String col,
  ) {
    final idx = header[col];
    if (idx == null || idx >= row.length) return null;
    final val = row[idx].trim();
    return val.isEmpty ? null : val;
  }

  /// Converte número no formato brasileiro (ex: "1.200,50") para [double].
  static double? _parseBrNumber(String raw) {
    try {
      final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// Retorna o nome da coluna com capitalização original para exibição de erro.
  static String _prettyName(String col) {
    const names = {
      'numeroitem': 'NumeroItem',
      'descricao': 'Descricao',
      'materialouservico': 'MaterialOuServico',
      'quantidade': 'Quantidade',
      'unidademedida': 'UnidadeMedida',
      'itemcategoria': 'ItemCategoria',
    };
    return names[col] ?? col;
  }
}

/// Exceção lançada quando o CSV de itens do Edital contém dados inválidos.
class EditalCsvParseException implements Exception {
  final String message;
  const EditalCsvParseException(this.message);

  @override
  String toString() => 'EditalCsvParseException: $message';
}
