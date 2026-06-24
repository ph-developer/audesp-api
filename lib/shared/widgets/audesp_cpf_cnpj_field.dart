import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audesp_text_field.dart';

/// Campo de CPF/CNPJ com máscara automática.
///
/// Detecta automaticamente o tipo de documento pela quantidade de dígitos:
/// - 11 dígitos → CPF: `XXX.XXX.XXX-XX`
/// - 14 dígitos → CNPJ: `XX.XXX.XXX/XXXX-XX`
///
/// Exemplo:
/// ```dart
/// AudespCpfCnpjField(
///   label: 'NI do Fornecedor (CNPJ/CPF) *',
///   controller: _niCtrl,
///   validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
/// )
/// ```
class AudespCpfCnpjField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const AudespCpfCnpjField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
    this.hintText,
    this.validator,
    this.onChanged,
  });

  /// Remove tudo que não é dígito.
  static String strip(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// Valida se o valor é um CPF ou CNPJ válido (apenas dígitos).
  static bool isValid(String value) {
    final digits = strip(value);
    return digits.length == 11 || digits.length == 14;
  }

  @override
  Widget build(BuildContext context) {
    return AudespTextField(
      label: label,
      controller: controller,
      initialValue: initialValue,
      readOnly: readOnly,
      enabled: enabled,
      hintText: hintText ?? '000.000.000-00 ou 00.000.000/0000-00',
      maxLength: 18,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CpfCnpjFormatter(),
      ],
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class _CpfCnpjFormatter extends TextInputFormatter {
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

  static String _applyMask(String digits) {
    if (digits.length <= 11) {
      return _applyCpfMask(digits);
    }
    return _applyCnpjMask(digits);
  }

  static String _applyCpfMask(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String _applyCnpjMask(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 14; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
