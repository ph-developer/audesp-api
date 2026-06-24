import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  factory StatusChip.document(String status) {
    return StatusChip(label: status == 'sent' ? 'Enviado' : 'Rascunho');
  }

  factory StatusChip.retificacao() {
    return const StatusChip(label: 'Retificação');
  }

  factory StatusChip.httpCode(int? code) {
    Color color;
    if (code == null) {
      color = Colors.grey;
    } else if (code >= 200 && code < 300) {
      color = Colors.green.shade700;
    } else if (code >= 400 && code < 500) {
      color = Colors.orange.shade800;
    } else {
      color = Colors.red.shade700;
    }
    return StatusChip(
      label: code?.toString() ?? '-',
      color: color,
      backgroundColor: color.withAlpha(25),
      borderColor: color.withAlpha(80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.onTertiaryContainer;
    final effectiveBackground = backgroundColor ?? scheme.tertiaryContainer;

    return Chip(
      label: Text(label),
      backgroundColor: effectiveBackground,
      labelStyle: TextStyle(color: effectiveColor),
      side: borderColor != null ? BorderSide(color: borderColor!) : null,
      padding: EdgeInsets.zero,
    );
  }
}
