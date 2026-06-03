import 'package:excel/excel.dart';

import '../constants/template_constants.dart';

/// Gera arquivos XLSX a partir de definições de template.
class TemplateGenerator {
  TemplateGenerator._();

  /// Gera os bytes de um arquivo XLSX a partir de [template].
  ///
  /// Estrutura da planilha:
  /// - **Linha 1:** Cabeçalho (negrito)
  /// - **Linha 2:** Descrição de cada coluna (itálico, cinza)
  /// - **Linha 3:** Dados de exemplo (fonte padrão, sem formatação)
  static List<int> generate(TemplateDefinition template) {
    final excel = Excel.createExcel();

    excel.rename('Sheet1', template.sheetName);
    final sheet = excel[template.sheetName];

    final headerStyle = CellStyle(
      bold: true,
      textWrapping: TextWrapping.WrapText,
    );

    final descriptionStyle = CellStyle(
      italic: true,
      fontColorHex: ExcelColor.grey,
      fontSize: 10,
      textWrapping: TextWrapping.WrapText,
    );

    for (var col = 0; col < template.columnCount; col++) {
      final columnTitle = template.columns[col].title;
      final cellIndexHeader = CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 0,
      );
      sheet.cell(cellIndexHeader).value = TextCellValue(columnTitle);
      sheet.cell(cellIndexHeader).cellStyle = headerStyle;

      final cellIndexDesc = CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 1,
      );
      sheet.cell(cellIndexDesc).value =
          TextCellValue(template.columns[col].description);
      sheet.cell(cellIndexDesc).cellStyle = descriptionStyle;

      final cellIndexExample = CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 2,
      );
      sheet.cell(cellIndexExample).value =
          TextCellValue(template.columns[col].example);

      sheet.setColumnAutoFit(col);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Erro ao gerar o arquivo XLSX do template.');
    }
    return bytes;
  }
}
