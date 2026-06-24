import 'package:flutter/material.dart';

/// Checkbox com suporte a tristate (3 estados) para os formulários AUDESP.
///
/// Útil para padrões "Selecionar Todos" onde o estado intermediário
/// indica seleção parcial.
///
/// - `true` → todos selecionados
/// - `false` → nenhum selecionado
/// - `null` → seleção parcial
///
/// Exemplo:
/// ```dart
/// AudespTriStateCheckbox(
///   label: 'Selecionar Todos',
///   value: allSelected ? true : (someSelected ? null : false),
///   onChanged: _toggleSelectAll,
/// )
/// ```
class AudespTriStateCheckbox extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool readOnly;

  const AudespTriStateCheckbox({
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
      tristate: true,
      onChanged: readOnly ? null : onChanged,
    );
  }
}
