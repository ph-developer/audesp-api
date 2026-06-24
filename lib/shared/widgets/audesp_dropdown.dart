import 'package:flutter/material.dart';

/// Dropdown padronizado para os formulários AUDESP.
///
/// Wraps [DropdownButtonFormField] e converte um [Map<T, String>] em
/// [DropdownMenuItem] automaticamente.
///
/// Para casos onde os items não vêm de um Map (ex: itens const),
/// use o construtor `AudespDropdown.items(...)`.
///
/// Exemplo com Map:
/// ```dart
/// AudespDropdown<int>(
///   label: 'Tipo de Benefício *',
///   value: _tipoBeneficio,
///   items: {1: 'Material', 2: 'Serviço'},
///   onChanged: (v) => setState(() => _tipoBeneficio = v),
///   validator: (v) => v == null ? 'Obrigatório' : null,
/// )
/// ```
///
/// Exemplo com lista de itens:
/// ```dart
/// AudespDropdown<String>.items(
///   label: 'Status',
///   value: _statusFilter,
///   items: [
///     DropdownMenuItem(value: 'draft', child: Text('Rascunhos')),
///     DropdownMenuItem(value: 'sent', child: Text('Enviados')),
///   ],
///   onChanged: (v) => setState(() => _statusFilter = v!),
/// )
/// ```
class AudespDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool readOnly;
  final bool enabled;
  final FormFieldValidator<T>? validator;

  /// Items como Map (construtor padrão).
  final Map<T, String>? _itemsMap;

  /// Items como lista de DropdownMenuItem (construtor alternativo).
  final List<DropdownMenuItem<T>>? _itemsList;

  /// Cria um dropdown a partir de um [Map<T, String>].
  const AudespDropdown({
    super.key,
    required Map<T, String> items,
    this.label,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
  }) : _itemsMap = items,
       _itemsList = null;

  /// Cria um dropdown a partir de uma lista de [DropdownMenuItem].
  const AudespDropdown.items({
    super.key,
    required List<DropdownMenuItem<T>> items,
    this.label,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
  }) : _itemsMap = null,
       _itemsList = items;

  List<DropdownMenuItem<T>> _buildItems() {
    if (_itemsList != null) return _itemsList;
    return _itemsMap!.entries
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: value != null ? ValueKey('dd_${label}_$value') : null,
      initialValue: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(labelText: label),
      items: _buildItems(),
      onChanged: readOnly ? null : onChanged,
      validator: validator,
    );
  }
}
