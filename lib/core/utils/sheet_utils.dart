import 'package:excel/excel.dart';

import 'csv_utils.dart';

/// Utilitário de leitura de planilhas que aceita tanto CSV quanto XLSX.
///
/// A detecção do formato é automática pelos bytes de magic number.
/// XLSX é detectado pelos bytes `PK\x03\x04` (ZIP), o restante é tratado
/// como CSV com suporte a UTF-8, Latin-1 e BOM.
class SheetUtils {
  SheetUtils._();

  /// Magic bytes do formato ZIP (usado por XLSX).
  static const _zipMagic = [0x50, 0x4B, 0x03, 0x04];

  /// Retorna `true` se [bytes] corresponde a um arquivo XLSX.
  static bool _isXlsx(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == _zipMagic[0] &&
        bytes[1] == _zipMagic[1] &&
        bytes[2] == _zipMagic[2] &&
        bytes[3] == _zipMagic[3];
  }

  /// Interpreta [bytes] como planilha e retorna as linhas como
  /// `List<List<String>>`.
  ///
  /// Parâmetros específicos de CSV:
  /// - [csvDelimiter]: delimitador de colunas (padrão `,`)
  /// - [csvCommentPrefix]: linhas que começam com este prefixo são ignoradas
  ///   (padrão: vazio — sem filtro)
  static List<List<String>> parseRows(
    List<int> bytes, {
    String csvDelimiter = ',',
    String csvCommentPrefix = '',
  }) {
    if (_isXlsx(bytes)) {
      return _parseXlsxRows(bytes);
    }

    var content = CsvUtils.decodeBytes(bytes);
    if (csvCommentPrefix.isNotEmpty) {
      content = content
          .split('\n')
          .where((l) => !l.trimLeft().startsWith(csvCommentPrefix))
          .join('\n');
    }
    return CsvUtils.parseCsv(content, delimiter: csvDelimiter);
  }

  /// Lê a primeira aba de um arquivo XLSX e retorna as linhas como
  /// `List<List<String>>`.
  ///
  /// Linhas completamente vazias são omitidas.
  static List<List<String>> _parseXlsxRows(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const FormatException('A planilha XLSX não contém nenhuma aba.');
    }

    final sheet = excel.tables.values.first;
    final rows = <List<String>>[];

    for (final row in sheet.rows) {
      final rowValues = row.map((cell) {
        if (cell?.value == null) return '';
        return cell!.value.toString();
      }).toList();

      if (rowValues.every((v) => v.isEmpty)) continue;
      rows.add(rowValues);
    }

    return rows;
  }
}
