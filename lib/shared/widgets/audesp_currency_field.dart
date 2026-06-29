import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart' as fmt;
import 'audesp_number_field.dart';

/// Campo de valor monetário (R$) padronizado para os formulários AUDESP.
///
/// Exibe prefixo `R$`, aceita formato brasileiro (1.234,56) e valida
/// com [parseBrCurrencyOrNull]. Sempre trabalha com 4 casas decimais.
///
/// Exemplo:
/// ```dart
/// AudespCurrencyField(
///   label: 'Valor Unitário Estimado *',
///   controller: _valorUnitCtrl,
///   validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
/// )
/// ```
class AudespCurrencyField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final String? prefixText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const AudespCurrencyField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.prefixText = 'R\$ ',
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
      autofocus: autofocus,
      decimals: true,
      prefixText: prefixText,
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
