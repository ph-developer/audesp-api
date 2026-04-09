import 'package:flutter/material.dart';

/// Botão assíncrono padronizado para os formulários AUDESP.
///
/// Envolve um [FilledButton] e gerencia o estado de carregamento
/// automaticamente: quando [onPressed] está em execução, o botão exibe um
/// [CircularProgressIndicator] de tamanho fixo (16×16, strokeWidth 2) e fica
/// desabilitado, evitando cliques duplos.
///
/// Exemplos:
/// ```dart
/// // Botão simples com label
/// AudespAsyncButton(
///   label: 'Salvar',
///   onPressed: _save,
/// )
///
/// // Botão com ícone
/// AudespAsyncButton.icon(
///   label: 'Enviar à AUDESP',
///   icon: Icons.send,
///   onPressed: _enviar,
/// )
/// ```
class AudespAsyncButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Future<void> Function()? onPressed;

  const AudespAsyncButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  /// Construtor de conveniência com ícone obrigatório.
  const AudespAsyncButton.icon({
    super.key,
    required this.label,
    required IconData this.icon,
    required this.onPressed,
  });

  @override
  State<AudespAsyncButton> createState() => _AudespAsyncButtonState();
}

class _AudespAsyncButtonState extends State<AudespAsyncButton> {
  bool _loading = false;

  Future<void> _handlePress() async {
    if (_loading || widget.onPressed == null) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );

    if (widget.icon != null) {
      return FilledButton.icon(
        onPressed: _loading ? null : _handlePress,
        icon: _loading ? spinner : Icon(widget.icon),
        label: Text(widget.label),
      );
    }

    return FilledButton(
      onPressed: _loading ? null : _handlePress,
      child: _loading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [spinner, const SizedBox(width: 8), Text(widget.label)],
            )
          : Text(widget.label),
    );
  }
}
