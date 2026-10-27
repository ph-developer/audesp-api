import 'package:flutter/material.dart';

class AudespWarningMessage extends StatelessWidget {
  final String message;

  const AudespWarningMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
