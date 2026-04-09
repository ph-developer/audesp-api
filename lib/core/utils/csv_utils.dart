import 'dart:convert';

/// Utilitários de leitura e parse de arquivos CSV.
///
/// Suporta arquivos em UTF-8 (com ou sem BOM) e Latin-1/ISO-8859-1.
class CsvUtils {
  CsvUtils._();

  // ---------------------------------------------------------------------------
  // Decodificação de bytes
  // ---------------------------------------------------------------------------

  /// Decodifica bytes de arquivo CSV para String.
  ///
  /// Tenta UTF-8 (com remoção de BOM se presente); se falhar, usa Latin-1.
  static String decodeBytes(List<int> bytes) {
    // Remove BOM UTF-8 (EF BB BF) se presente.
    final data = (bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF)
        ? bytes.sublist(3)
        : bytes;

    try {
      return utf8.decode(data, allowMalformed: false);
    } on FormatException {
      return latin1.decode(data);
    }
  }

  // ---------------------------------------------------------------------------
  // Parse de linhas CSV
  // ---------------------------------------------------------------------------

  /// Divide [content] em linhas ignorando delimitadores dentro de campos
  /// entre aspas. Suporta delimitadores: vírgula (`,`) e ponto-e-vírgula (`;`).
  ///
  /// Retorna lista de listas de strings (uma lista por linha), excluindo
  /// linhas completamente vazias.
  ///
  /// **Não lida com quebras de linha dentro de campos entre aspas** —
  /// os CSVs dos portais BLL e BRConectado não usam essa construção.
  static List<List<String>> parseCsv(
    String content, {
    String delimiter = ',',
  }) {
    final result = <List<String>>[];
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimRight(); // remove \r residual do Windows
      if (line.isEmpty) continue;
      result.add(_splitLine(line, delimiter));
    }
    return result;
  }

  /// Divide uma única linha CSV respeitando campos entre aspas duplas.
  static List<String> _splitLine(String line, String delimiter) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];

      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Aspas duplas escapadas dentro de campo: "" → "
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == delimiter && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }

  // ---------------------------------------------------------------------------
  // Helpers de cabeçalho
  // ---------------------------------------------------------------------------

  /// Constrói um mapa de nome de coluna → índice a partir da linha de cabeçalho.
  ///
  /// Os nomes são normalizados (trim + toLowerCase) para facilitar buscas
  /// case-insensitive.
  static Map<String, int> buildHeaderIndex(List<String> headerRow) {
    return {
      for (var i = 0; i < headerRow.length; i++)
        headerRow[i].trim().toLowerCase(): i,
    };
  }

  /// Retorna o valor de [row] no índice correspondente a [columnName] no
  /// [headerIndex], ou lança [StateError] se a coluna não existir.
  static String getField(
    List<String> row,
    Map<String, int> headerIndex,
    String columnName,
  ) {
    final idx = headerIndex[columnName.toLowerCase()];
    if (idx == null) {
      throw StateError(
        'Coluna "$columnName" não encontrada no CSV. '
        'Colunas disponíveis: ${headerIndex.keys.join(', ')}',
      );
    }
    if (idx >= row.length) return '';
    return row[idx].trim();
  }
}
