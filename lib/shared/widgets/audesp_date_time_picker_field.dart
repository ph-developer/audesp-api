import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Campo de data+hora padronizado para os formulários AUDESP.
///
/// - Formato de exibição: `dd/MM/yyyy HH:mm`.
/// - Limites globais: 1950 – 2100.
/// - Integra-se ao [Form] via [FormField] e suporta `validator` customizado.
/// - Exibe um ícone de calendário quando editável; desabilita o tap quando
///   [readOnly] é `true`.
///
/// Exemplo:
/// ```dart
/// AudespDateTimePickerField(
///   label: 'Abertura de Propostas *',
///   value: _dataAbertura,
///   readOnly: _isSent,
///   onChanged: (d) => setState(() => _dataAbertura = d),
///   validator: (d) => d == null ? 'Obrigatório' : null,
/// )
/// ```
class AudespDateTimePickerField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final bool readOnly;
  final ValueChanged<DateTime?> onChanged;
  final FormFieldValidator<DateTime?>? validator;

  /// Limite inferior do seletor. Padrão: 1 jan 1950.
  final DateTime? firstDate;

  /// Limite superior do seletor. Padrão: 31 dez 2100.
  final DateTime? lastDate;

  const AudespDateTimePickerField({
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
  State<AudespDateTimePickerField> createState() =>
      _AudespDateTimePickerFieldState();
}

class _AudespDateTimePickerFieldState extends State<AudespDateTimePickerField> {
  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1950),
      lastDate: widget.lastDate ?? DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: widget.value != null
          ? TimeOfDay(hour: widget.value!.hour, minute: widget.value!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime?>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.value != widget.value) {
            state.didChange(widget.value);
          }
        });

        final hasError = state.errorText != null;

        return InkWell(
          onTap: widget.readOnly ? null : _pickDateTime,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              labelText: widget.label,
              border: const OutlineInputBorder(),
              errorText: hasError ? state.errorText : null,
              enabled: !widget.readOnly,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              suffixIcon: widget.readOnly
                  ? null
                  : const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              widget.value != null ? _fmt.format(widget.value!) : '—',
              style: widget.readOnly
                  ? TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.38),
                    )
                  : widget.value == null
                  ? TextStyle(color: Theme.of(context).colorScheme.outline)
                  : null,
            ),
          ),
        );
      },
    );
  }
}
