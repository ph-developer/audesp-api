import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudespTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
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
    this.autofocus = false,
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
  State<AudespTextField> createState() => _AudespTextFieldState();
}

class _AudespTextFieldState extends State<AudespTextField> {
  late TextEditingController _effectiveController;
  FocusNode? _internalFocusNode;
  bool _pendingPaste = false;
  bool _dialogShowing = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    if (widget.focusNode == null) _internalFocusNode = FocusNode();
    _effectiveController.addListener(_onTextChanged);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    if (widget.controller == null) _effectiveController.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AudespTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _effectiveController = widget.controller ?? TextEditingController();
      _effectiveController.addListener(_onTextChanged);
      _lastText = _effectiveController.text;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }
  }

  String _lastText = '';

  bool _handleKeyEvent(KeyEvent event) {
    if (_dialogShowing) return false;
    if (widget.readOnly || !widget.enabled) return false;

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyV &&
        HardwareKeyboard.instance.isControlPressed &&
        _effectiveFocusNode.hasFocus) {
      _pendingPaste = true;
    }
    return false;
  }

  void _onTextChanged() {
    final current = _effectiveController.text;
    if (current == _lastText) return;
    if (_dialogShowing) {
      _lastText = current;
      return;
    }

    if (_pendingPaste) {
      _pendingPaste = false;
      if (current.contains('\n')) {
        _dialogShowing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final remove = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Quebras de linha detectadas'),
              content: const Text(
                'O texto colado contém quebras de linha. '
                'Deseja removê-las?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Não'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sim'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (remove == true) {
            final text = _effectiveController.text;
            final cursorPos = _effectiveController.selection.baseOffset;
            final sanitized = _sanitizeText(text);
            final textBeforeCursor = text.substring(0, cursorPos);
            final sanitizedBeforeCursor = _sanitizeText(textBeforeCursor);
            _effectiveController.value = TextEditingValue(
              text: sanitized,
              selection: TextSelection.collapsed(
                offset: sanitizedBeforeCursor.length.clamp(0, sanitized.length),
              ),
            );
          }
          _lastText = _effectiveController.text;
          _dialogShowing = false;
        });
        return;
      }
    }

    _lastText = current;
  }

  static String _sanitizeText(String text) {
    var result = text.replaceAll(RegExp(r'[\r\n]+'), ' ');
    result = result.replaceAll(RegExp(r' {2,}'), ' ');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _effectiveController,
      initialValue: widget.initialValue,
      focusNode: _effectiveFocusNode,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      textCapitalization: widget.textCapitalization,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      decoration: const InputDecoration(counterText: '', isDense: true)
          .copyWith(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixText: widget.prefixText,
            suffixText: widget.suffixText,
            helperText: widget.helperText,
            prefixIcon: Container(
              width: widget.prefixIcon == null ? 12.0 : 32.0,
              padding: const EdgeInsets.all(4.0),
              child: widget.prefixIcon,
            ),
            prefixIconConstraints: const BoxConstraints(
              maxHeight: 32,
              maxWidth: 32,
            ),
            suffixIcon: Container(
              width: widget.suffixIcon == null ? 12.0 : 32.0,
              padding: const EdgeInsets.all(4.0),
              child: widget.suffixIcon,
            ),
            suffixIconConstraints: const BoxConstraints(
              maxHeight: 32,
              maxWidth: 32,
            ),
          ),
    );
  }
}
