import 'package:flutter/material.dart';

/// Checkbox padronizado para os formulários AUDESP.
///
/// Wraps [CheckboxListTile] com layout consistente: alinhamento à esquerda,
/// sem padding interno, Dense por padrão.
///
/// Exemplo:
/// ```dart
/// AudespCheckbox(
///   label: 'Retificação',
///   value: _retificacao,
///   onChanged: (v) => setState(() => _retificacao = v),
/// )
/// ```
class AudespCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool readOnly;

  const AudespCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: readOnly || onChanged == null
          ? null
          : (value) => onChanged!(value ?? false),
    );
  }
}
