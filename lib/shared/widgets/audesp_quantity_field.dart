import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart' as fmt;
import 'audesp_number_field.dart';

/// Campo de quantidade padronizado para os formulários AUDESP.
///
/// Aceita formato brasileiro com até 4 casas decimais, sem prefixo ou sufixo.
///
/// Exemplo:
/// ```dart
/// AudespQuantityField(
///   label: 'Quantidade *',
///   controller: _qtdCtrl,
///   validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
/// )
/// ```
class AudespQuantityField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const AudespQuantityField({
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

  @override
  Widget build(BuildContext context) {
    return AudespNumberField(
      label: label,
      controller: controller,
      initialValue: initialValue,
      readOnly: readOnly,
      enabled: enabled,
      decimals: true,
      hintText: hintText,
      validator: validator ??
          (v) {
            if (v == null || v.isEmpty) return 'Obrigatório';
            if (fmt.parseBrCurrencyOrNull(v) == null) {
              return 'Número inválido';
            }
            return null;
          },
      onChanged: onChanged,
    );
  }
}
