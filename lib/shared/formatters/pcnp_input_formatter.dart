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
  static String applyMask(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
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

  /// Remove a máscara, retornando apenas dígitos.
  static String stripMask(String masked) => masked.replaceAll(RegExp(r'\D'), '');
}
