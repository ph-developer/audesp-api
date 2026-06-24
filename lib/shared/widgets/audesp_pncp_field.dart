import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formatters/pcnp_input_formatter.dart';
import 'audesp_text_field.dart';

/// Campo de ID de Contratação PNCP padronizado.
///
/// Aplica a máscara `XXXXXXXXXXXXXX-X-XXXXXX/XXXX` automaticamente.
/// Validação mínima: 25 dígitos.
///
/// Exemplo:
/// ```dart
/// AudespPncpField(
///   label: 'ID de Contratação PNCP *',
///   controller: _pncpCtrl,
///   validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
/// )
/// ```
class AudespPncpField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const AudespPncpField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
  });

  /// Remove a máscara, retornando apenas dígitos.
  static String stripMask(String masked) => PcnpInputFormatter.stripMask(masked);

  @override
  Widget build(BuildContext context) {
    return AudespTextField(
      label: label,
      controller: controller,
      initialValue: initialValue,
      readOnly: readOnly,
      enabled: enabled,
      hintText: '00000000000000-0-000000/0000',
      maxLength: 28,
      keyboardType: TextInputType.number,
      inputFormatters: [
        PcnpInputFormatter(),
        LengthLimitingTextInputFormatter(28),
      ],
      validator: validator ??
          (v) {
            if (v == null || v.isEmpty) return 'Obrigatório';
            final raw = PcnpInputFormatter.stripMask(v);
            if (raw.length < 25) return 'ID de Contratação PNCP incompleto';
            return null;
          },
      onChanged: onChanged,
    );
  }
}
