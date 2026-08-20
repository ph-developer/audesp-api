import 'package:audesp_api/core/utils/pdf_text_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfTextSanitizer', () {
    test('substitui aspas curvas por aspas normais', () {
      const input = '“Texto com aspas curvas” e ‘aspas simples’';
      expect(input.toPdfSafe(), equals('"Texto com aspas curvas" e \'aspas simples\''));
    });

    test('substitui traços e travessões unicode (en dash, em dash)', () {
      const input = 'Item 1 – Descrição — Detalhe ― Barra − Menos';
      expect(input.toPdfSafe(), equals('Item 1 - Descrição - Detalhe - Barra - Menos'));
    });

    test('substitui reticências e marcadores', () {
      const input = 'Aguardando… • Ponto 1 ◦ Ponto 2 ▪ Ponto 3';
      expect(input.toPdfSafe(), equals('Aguardando... - Ponto 1 - Ponto 2 - Ponto 3'));
    });

    test('substitui espaços especiais e remove zero-width', () {
      const input = 'Texto\u00A0com\u202Fespaço \u200Bzero';
      expect(input.toPdfSafe(), equals('Texto com espaço zero'));
    });

    test('substitui símbolos comerciais e matemáticos', () {
      const input = '№ 123 | Marca™ | 5 × 2 ÷ 2 ≤ 10 ± 1';
      expect(input.toPdfSafe(), equals('Nº 123 | Marca(TM) | 5 x 2 / 2 <= 10 +/- 1'));
    });

    test('mantém texto ASCII e caracteres acentuados comuns do português', () {
      const input = 'Licitação pública nº 10/2026 - Órgão: Secretaria de Educação (R\$ 1.500,00)';
      expect(input.toPdfSafe(), equals(input));
    });

    test('retorna string vazia se entrada for vazia', () {
      expect(''.toPdfSafe(), equals(''));
    });
  });
}
