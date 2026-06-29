import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audesp_text_field.dart';

/// Campo numérico padronizado para os formulários AUDESP.
///
/// Aceita apenas dígitos, vírgulas e pontos (formato brasileiro).
/// Por padrão, permite decimais. Defina [decimals] como `false` para
/// aceitar apenas inteiros.
///
/// Exemplo:
/// ```dart
/// AudespNumberField(
///   label: 'Quantidade *',
///   controller: _qtdCtrl,
///   validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
/// )
/// ```
class AudespNumberField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;
  final String? hintText;
  final String? prefixText;
  final String? suffixText;
  final bool decimals;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const AudespNumberField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.hintText,
    this.prefixText,
    this.suffixText,
    this.decimals = true,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AudespTextField(
      label: label,
      controller: controller,
      initialValue: initialValue,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      maxLength: maxLength,
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimals ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      validator: validator,
      onChanged: onChanged,
    );
  }
}
