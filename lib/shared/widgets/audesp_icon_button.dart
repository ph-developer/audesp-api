import 'package:flutter/material.dart';

/// IconButton padronizado para a UI AUDESP.
///
/// Tamanho de toque fixo via [size], ícone configurável via [iconSize].
/// [tooltip] é obrigatório para acessibilidade.
class AudespIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final bool outlined;

  const AudespIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 30,
    this.iconSize = 20,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = Icon(icon, size: iconSize, color: color);

    final btn = outlined
        ? IconButton.outlined(
            onPressed: onPressed,
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            icon: effectiveIcon,
            iconSize: iconSize,
          )
        : IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            icon: effectiveIcon,
            iconSize: iconSize,
          );

    return Container(
      padding: EdgeInsets.zero,
      width: size,
      height: size,
      child: btn,
    );
  }
}
