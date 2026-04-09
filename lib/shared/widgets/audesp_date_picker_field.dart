import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Campo de data padronizado para os formulários AUDESP.
///
/// - Formato de exibição: `dd/MM/yyyy`.
/// - Limites globais: 1950 – 2100.
/// - Integra-se ao [Form] via [FormField] e suporta `validator` customizado.
/// - Exibe um ícone de calendário quando editável; desabilita o tap quando
///   [readOnly] é `true`.
///
/// Exemplo:
/// ```dart
/// AudespDatePickerField(
///   label: 'Data de Assinatura *',
///   value: _dataAssinatura,
///   readOnly: _isSent,
///   onChanged: (d) => setState(() => _dataAssinatura = d),
///   validator: (d) => d == null ? 'Obrigatório' : null,
/// )
/// ```
class AudespDatePickerField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final bool readOnly;
  final ValueChanged<DateTime?> onChanged;
  final FormFieldValidator<DateTime?>? validator;

  /// Limite inferior do seletor. Padrão: 1 jan 1950.
  final DateTime? firstDate;

  /// Limite superior do seletor. Padrão: 31 dez 2100.
  final DateTime? lastDate;

  const AudespDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
    this.validator,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<AudespDatePickerField> createState() => _AudespDatePickerFieldState();
}

class _AudespDatePickerFieldState extends State<AudespDatePickerField> {
  static final _fmt = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1950),
      lastDate: widget.lastDate ?? DateTime(2100),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime?>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (state) {
        // Sincroniza o FormField com mudanças externas de `value`.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.value != widget.value) {
            state.didChange(widget.value);
          }
        });

        final hasError = state.errorText != null;

        return InkWell(
          onTap: widget.readOnly ? null : _pickDate,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              errorText: hasError ? state.errorText : null,
              suffixIcon: widget.readOnly
                  ? null
                  : const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              widget.value != null ? _fmt.format(widget.value!) : '—',
              style: widget.value == null
                  ? TextStyle(color: Theme.of(context).colorScheme.outline)
                  : null,
            ),
          ),
        );
      },
    );
  }
}
