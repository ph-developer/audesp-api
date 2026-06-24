import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart' as fmt;
import 'audesp_number_field.dart';

/// Campo de percentual padronizado para os formulários AUDESP.
///
/// Exibe sufixo `%`, aceita formato brasileiro e valida valores numéricos.
///
/// Exemplo:
/// ```dart
/// AudespPercentField(
///   label: 'Taxa de Desconto *',
///   controller: _taxaCtrl,
///   validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
/// )
/// ```
class AudespPercentField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const AudespPercentField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
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
      suffixText: ' %',
      validator:
          validator ??
          (v) {
            if (v == null || v.isEmpty) return 'Obrigatório';
            if (fmt.parseBrCurrencyOrNull(v) == null) return 'Valor inválido';
            return null;
          },
      onChanged: onChanged,
    );
  }
}
