import 'package:flutter/services.dart';

/// Formatter de máscara para IDs de Contratação e Atas do PNCP.
///
/// Formatos:
/// - Contratação (25 dígitos): `XXXXXXXXXXXXXX-X-XXXXXX/XXXX` (28 caracteres).
/// - Ata (31 dígitos): `XXXXXXXXXXXXXX-X-XXXXXX/XXXX-XXXXXX` (35 caracteres).
/// Aceita apenas dígitos na entrada.
class PcnpInputFormatter extends TextInputFormatter {
  final int maxDigits;

  PcnpInputFormatter({this.maxDigits = 25});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) {
      digits = digits.substring(0, maxDigits);
    }
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final masked = _applyMask(digits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  /// Aplica a máscara PNCP a um valor de string já com apenas dígitos.
  /// Suporta IDs de Contratação (25 dígitos) e IDs de Ata (31 dígitos).
  /// Se o valor não contiver 25 nem 31 dígitos numéricos (ex.: código interno alfanumérico),
  /// retorna o valor original sem modificação.
  static String applyMask(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 25 && digits.length != 31) return value;
    return _applyMask(digits);
  }

  static String _applyMask(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 14 || i == 15) buffer.write('-');
      if (i == 21) buffer.write('/');
      if (i == 25) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Remove a máscara, retornando apenas dígitos para PNCPs válidos (25 ou 31 dígitos).
  /// Se não for um PNCP com máscara (ex: código alfanumérico sem PNCP), retorna o texto aparado.
  static String stripMask(String masked) {
    final digits = masked.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 25 || digits.length == 31) return digits;
    return masked.trim();
  }
}
