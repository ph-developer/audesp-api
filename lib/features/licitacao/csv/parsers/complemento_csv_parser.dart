import '../mappers/complemento_csv_mapper.dart';
import '../models/licitacao_item_csv_model.dart';
import '../../../../core/utils/csv_utils.dart';
import 'portal_csv_parser.dart';

/// Parser para a **planilha complementar** (Template Padrão).
///
/// O arquivo CSV deve ter o separador `;` e as seguintes colunas (na ordem
/// que preferir, pois o parser usa os nomes do cabeçalho):
/// ```
/// NumeroItem;TipoOrcamento;ValorEstimado;DataOrcamento;SituacaoCompraItem;DataSituacao;TipoValor;TipoProposta
/// ```
///
/// - Linhas que começam com `#` são ignoradas (comentários).
/// - Datas devem estar no formato **DD/MM/AAAA**.
/// - Valores monetários devem usar a notação brasileira (ex: `10.500,00`).
///
/// Retorna um `Map<int, LicitacaoItemCsvModel>` indexado pelo [numeroItem].
/// Os campos `licitantes` são preenchidos posteriormente pelo merge com os
/// dados do portal. O campo `situacaoCompraItemId` é fornecido exclusivamente
/// por esta planilha (coluna `SituacaoCompraItem`).
class ComplementoCsvParser {
  const ComplementoCsvParser();

  Map<int, LicitacaoItemCsvModel> parse(List<int> bytes) {
    final content = CsvUtils.decodeBytes(bytes);

    // Remove linhas de comentário antes do parse para evitar interferência.
    final filteredLines = content
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('#'))
        .join('\n');

    final rows = CsvUtils.parseCsv(filteredLines, delimiter: ';');

    if (rows.isEmpty) {
      throw const CsvParseException('Planilha complementar está vazia.');
    }

    final header = CsvUtils.buildHeaderIndex(rows.first);

    if (!header.containsKey('numeroitem')) {
      throw const CsvParseException(
        'Planilha complementar não possui a coluna "NumeroItem".',
      );
    }

    final result = <int, LicitacaoItemCsvModel>{};

    for (final row in rows.skip(1)) {
      if (row.length <= 1) continue;
      try {
        final numeroItemStr = _tryGet(row, header, 'numeroitem') ?? '';
        if (numeroItemStr.isEmpty) continue;

        final numeroItem = int.parse(numeroItemStr);

        final tipoOrcStr = _tryGet(row, header, 'tipoorcamento');
        // Aceita tanto 'ValorEstimado' (template antigo) quanto
        // 'ValorEstimadoMedia' (template estendido) para retrocompatibilidade.
        final valorEstStr = _tryGet(row, header, 'valorestimadimedia') ??
            _tryGet(row, header, 'valorestimado');
        final dataOrcStr = _tryGet(row, header, 'dataorcamento');
        final situacaoCompraItemStr = _tryGet(row, header, 'situacaocompraitem');
        final dataSitStr = _tryGet(row, header, 'datasituacao');
        final tipoValStr = _tryGet(row, header, 'tipovalor');
        final tipoPropStr = _tryGet(row, header, 'tipoproposta');

        result[numeroItem] = LicitacaoItemCsvModel(
          numeroItem: numeroItem,
          licitantes: const [],
          tipoOrcamento: tipoOrcStr != null && tipoOrcStr.isNotEmpty
              ? ComplementoCsvMapper.tipoOrcamento(tipoOrcStr)
              : null,
          valorEstimado: valorEstStr != null && valorEstStr.isNotEmpty
              ? _parseBrCurrency(valorEstStr)
              : null,
          dataOrcamento: dataOrcStr != null && dataOrcStr.isNotEmpty
              ? _parseDate(dataOrcStr)
              : null,
          situacaoCompraItemId: situacaoCompraItemStr != null && situacaoCompraItemStr.isNotEmpty
              ? ComplementoCsvMapper.situacaoCompraItemId(situacaoCompraItemStr)
              : null,
          dataSituacao: dataSitStr != null && dataSitStr.isNotEmpty
              ? _parseDate(dataSitStr)
              : null,
          tipoValor: tipoValStr != null && tipoValStr.isNotEmpty
              ? ComplementoCsvMapper.tipoValor(tipoValStr)
              : null,
          tipoProposta: tipoPropStr != null && tipoPropStr.isNotEmpty
              ? ComplementoCsvMapper.tipoProposta(tipoPropStr)
              : null,
        );
      } catch (e) {
        throw CsvParseException(
          'Erro ao ler linha da planilha complementar: $e',
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

  static double? _parseBrCurrency(String raw) {
    try {
      final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// Converte data no formato DD/MM/AAAA → yyyy-MM-dd.
  static String? _parseDate(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;
    final parts = clean.split('/');
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      return '$year-$month-$day';
    }
    return clean;
  }
}
