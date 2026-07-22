import 'dart:convert';

import 'package:audesp_api/core/utils/currency_formatter.dart';
import 'package:audesp_api/core/utils/sheet_utils.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SheetUtils.parseRows', () {
    test('converte decimal numérico de XLSX para notação brasileira', () {
      final excel = Excel.createExcel();
      final sheet = excel.tables.values.first;
      sheet.cell(CellIndex.indexByString('A1')).value = const DoubleCellValue(
        1200.5,
      );

      final rows = SheetUtils.parseRows(excel.encode()!);

      expect(rows, [
        ['1200,5'],
      ]);
      expect(parseBrCurrencyOrNull(rows.first.first), 1200.5);
    });

    test('converte percentual numérico como os demais decimais', () {
      final excel = Excel.createExcel();
      final sheet = excel.tables.values.first;
      sheet.cell(CellIndex.indexByString('A1')).value = const DoubleCellValue(
        15.5,
      );

      final rows = SheetUtils.parseRows(excel.encode()!);

      expect(rows, [
        ['15,5'],
      ]);
    });

    test('mantém inteiro e texto de XLSX sem alteração', () {
      final excel = Excel.createExcel();
      final sheet = excel.tables.values.first;
      sheet.cell(CellIndex.indexByString('A1')).value = const IntCellValue(10);
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
        '1.200,50',
      );

      final rows = SheetUtils.parseRows(excel.encode()!);

      expect(rows, [
        ['10', '1.200,50'],
      ]);
    });

    test('mantém o comportamento brasileiro do CSV', () {
      final rows = SheetUtils.parseRows(
        utf8.encode('Valor;Percentual\n1.200,50;15,5'),
        csvDelimiter: ';',
      );

      expect(rows, [
        ['Valor', 'Percentual'],
        ['1.200,50', '15,5'],
      ]);
    });
  });
}
