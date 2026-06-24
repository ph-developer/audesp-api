import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto padronizado para os formulários AUDESP.
///
/// Wraps [TextFormField] com decoração consistente herdada do tema global.
/// Todos os outros campos de texto especializados (moeda, número, etc.)
/// derivam deste widget.
///
/// Exemplo:
/// ```dart
/// AudespTextField(
///   label: 'Descrição *',
///   controller: _descCtrl,
///   validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
/// )
/// ```
class AudespTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final int? maxLength;
  final int maxLines;
  final String? hintText;
  final String? prefixText;
  final String? suffixText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const AudespTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.maxLength,
    this.maxLines = 1,
    this.hintText,
    this.prefixText,
    this.suffixText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.suffixIcon,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      readOnly: readOnly,
      enabled: enabled,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      decoration: const InputDecoration(counterText: '', isDense: true)
          .copyWith(
            labelText: label,
            hintText: hintText,
            prefixText: prefixText,
            suffixText: suffixText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
    );
  }
}
