/// Formata um [double] no padrão brasileiro com 4 casas decimais.
/// Ex.: 1234.5 → "1.234,5000" | -0.5 → "-0,5000"
String _formatBR(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final fixed = abs.toStringAsFixed(4);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  final buffer = StringBuffer();
  final chars = intPart.split('');
  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && (chars.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(chars[i]);
  }

  return '${isNegative ? '-' : ''}$buffer,$decPart';
}

/// Formata um [double] como moeda brasileira: R$ 1.234,5678
String formatBRL(double? value) {
  if (value == null) return '';
  return 'R\$ ${_formatBR(value)}';
}

/// Formata um [double] no padrão brasileiro sem símbolo: 1.234,5678
String formatNumberBR(double? value) {
  if (value == null) return '';
  return _formatBR(value);
}

/// Converte um valor para string no formato brasileiro (vírgula decimal)
/// com 4 casas, para exibir em campos de texto. Ex.: 123.0 → "123,0000"
/// Aceita [num], [String] ou [null].
String doubleToBrString(dynamic value) {
  if (value == null) return '';
  final n = value is num ? value : double.tryParse(value.toString());
  if (n == null) return '';
  return n.toStringAsFixed(4).replaceAll('.', ',');
}

/// Converte texto no formato brasileiro (1.234,56) para [double].
/// Retorna [fallback] se o texto for vazio ou inválido.
double parseBrCurrency(String text, [double fallback = 0]) {
  final cleaned = text.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(cleaned) ?? fallback;
}

/// Converte texto no formato brasileiro (1.234,56) para [double].
/// Retorna [null] se o texto for vazio ou inválido.
double? parseBrCurrencyOrNull(String text) {
  final cleaned = text.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(cleaned);
}
