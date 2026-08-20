import 'package:flutter/services.dart';

/// Formatter de máscara para IDs de Contratação PNCP.
///
/// Formato: `XXXXXXXXXXXXXX-X-XXXXXX/XXXX` (28 caracteres com máscara).
/// Aceita apenas dígitos na entrada.
class PcnpInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final masked = _applyMask(digits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  /// Aplica a máscara PNCP a um valor de string já com apenas dígitos.
  /// Se o valor não contiver exatamente 25 dígitos numéricos (ex.: código interno alfanumérico),
  /// retorna o valor original sem modificação.
  static String applyMask(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 25) return value;
    return _applyMask(digits);
  }

  static String _applyMask(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 14 || i == 15) buffer.write('-');
      if (i == 21) buffer.write('/');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Remove a máscara, retornando apenas dígitos para PNCPs válidos (25 dígitos).
  /// Se não for um PNCP com máscara (ex: código alfanumérico sem PNCP), retorna o texto aparado.
  static String stripMask(String masked) {
    final digits = masked.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 25) return digits;
    return masked.trim();
  }
}
