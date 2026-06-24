import 'package:flutter/material.dart';

import 'audesp_snack_bar.dart';
import 'package:flutter/services.dart';

import 'audesp_text_field.dart';

/// Campo de entrada com chips (tags) padronizado para os formulários AUDESP.
///
/// Exibe um campo de texto com botão de adicionar e lista de chips removíveis.
/// Genérico para qualquer tipo [T].
///
/// Exemplo:
/// ```dart
/// AudespChipInput<String>(
///   label: 'CPF do Condutor',
///   hintText: '00000000000',
///   chips: _cpfs,
///   onAdd: (cpf) => setState(() => _cpfs.add(cpf)),
///   onRemove: (cpf) => setState(() => _cpfs.remove(cpf)),
///   maxLength: 11,
///   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
///   validateInput: (v) => v.length != 11 ? 'CPF deve conter 11 dígitos' : null,
///   formatChip: (cpf) => cpf,
/// )
/// ```
class AudespChipInput<T> extends StatefulWidget {
  final String label;
  final String? hintText;
  final List<T> chips;
  final ValueChanged<T> onAdd;
  final ValueChanged<T> onRemove;
  final bool readOnly;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validateInput;
  final Widget Function(T)? chipAvatar;
  final String Function(T) formatChip;
  final TextInputType? keyboardType;

  const AudespChipInput({
    super.key,
    required this.label,
    required this.chips,
    required this.onAdd,
    required this.onRemove,
    required this.formatChip,
    this.hintText,
    this.readOnly = false,
    this.maxLength,
    this.inputFormatters,
    this.validateInput,
    this.chipAvatar,
    this.keyboardType,
  });

  @override
  State<AudespChipInput<T>> createState() => _AudespChipInputState<T>();
}

class _AudespChipInputState<T> extends State<AudespChipInput<T>> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;

    final error = widget.validateInput?.call(value);
    if (error != null) {
      AudespSnackBar.show(
        context,
        message: error,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    widget.onAdd(value as T);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AudespTextField(
                label: widget.label,
                controller: _ctrl,
                hintText: widget.hintText,
                readOnly: widget.readOnly,
                maxLength: widget.maxLength,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
              ),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _add,
                tooltip: 'Adicionar',
              ),
            ],
          ],
        ),
        if (widget.chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.chips
                .map(
                  (chip) => Chip(
                    avatar: widget.chipAvatar?.call(chip),
                    label: Text(widget.formatChip(chip)),
                    onDeleted: widget.readOnly
                        ? null
                        : () => widget.onRemove(chip),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
