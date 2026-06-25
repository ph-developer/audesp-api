import 'package:flutter/material.dart';

/// Botão segmentado padronizado para os formulários AUDESP.
///
/// Wraps [SegmentedButton<T>] com um mapa de opções.
///
/// Exemplo sem ícones:
/// ```dart
/// AudespSegmentedButton<String>(
///   label: 'Tipo',
///   segments: {'M': 'Material', 'S': 'Serviço'},
///   selected: _tipo,
///   onSelectionChanged: (v) => setState(() => _tipo = v),
/// )
/// ```
///
/// Exemplo com ícones:
/// ```dart
/// AudespSegmentedButton<bool>(
///   label: 'Receita ou Despesa',
///   segments: {false: 'Despesa', true: 'Receita'},
///   icons: {false: Icons.arrow_circle_up_outlined, true: Icons.arrow_circle_down_outlined},
///   selected: {_receita},
///   onSelectionChanged: (v) => setState(() => _receita = v.first),
/// )
/// ```
class AudespSegmentedButton<T> extends StatelessWidget {
  final String? label;
  final Map<T, String> segments;
  final Map<T, IconData>? icons;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final bool readOnly;
  final double? width;

  const AudespSegmentedButton({
    super.key,
    this.label,
    required this.segments,
    this.icons,
    required this.selected,
    this.onSelectionChanged,
    this.readOnly = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final button = SegmentedButton<T>(
      segments: segments.entries
          .map(
            (e) => ButtonSegment(
              value: e.key,
              label: Text(e.value),
              icon: icons != null ? Icon(icons![e.key]) : null,
            ),
          )
          .toList(),
      selected: selected,
      onSelectionChanged: readOnly ? null : onSelectionChanged,
    );

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
        if (width != null) SizedBox(width: width, child: button) else button,
      ],
    );
  }
}
