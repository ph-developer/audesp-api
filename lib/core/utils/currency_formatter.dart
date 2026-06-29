String _formatBR(double value, {int casasDecimais = 4}) {
  final isNegative = value < 0;
  final abs = value.abs();
  final fixed = abs.toStringAsFixed(casasDecimais);
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

String formatBRL(double? value, {int casasDecimais = 4}) {
  if (value == null) return '';
  return 'R\$ ${_formatBR(value, casasDecimais: casasDecimais)}';
}

String formatNumberBR(double? value, {int casasDecimais = 4}) {
  if (value == null) return '';
  return _formatBR(value, casasDecimais: casasDecimais);
}

String doubleToBrString(dynamic value, {int casasDecimais = 4}) {
  if (value == null) return '';
  final n = value is num ? value : double.tryParse(value.toString());
  if (n == null) return '';
  return n.toStringAsFixed(casasDecimais).replaceAll('.', ',');
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
