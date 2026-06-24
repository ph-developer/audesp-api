import 'package:flutter/material.dart';

/// Botão segmentado padronizado para os formulários AUDESP.
///
/// Wraps [SegmentedButton<T>] com um mapa de opções.
///
/// Exemplo:
/// ```dart
/// AudespSegmentedButton<String>(
///   label: 'Tipo',
///   segments: {'M': 'Material', 'S': 'Serviço'},
///   selected: _tipo,
///   onSelectionChanged: (v) => setState(() => _tipo = v),
/// )
/// ```
class AudespSegmentedButton<T> extends StatelessWidget {
  final String? label;
  final Map<T, String> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final bool readOnly;

  const AudespSegmentedButton({
    super.key,
    this.label,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        SegmentedButton<T>(
          segments: segments.entries
              .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
              .toList(),
          selected: selected,
          onSelectionChanged: readOnly ? null : onSelectionChanged,
        ),
      ],
    );
  }
}
