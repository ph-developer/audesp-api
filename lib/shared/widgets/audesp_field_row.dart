import 'package:flutter/widgets.dart';

import 'audesp_spacing.dart';

class AudespFieldRowItem {
  final Widget child;
  final int flex;
  final double? width;

  const AudespFieldRowItem({required this.child, this.flex = 1, this.width});
}

class AudespFieldRow extends StatelessWidget {
  final List<AudespFieldRowItem> children;
  final double spacing;
  final double runSpacing;
  final double stackBreakpoint;
  final CrossAxisAlignment crossAxisAlignment;

  const AudespFieldRow({
    super.key,
    required this.children,
    this.spacing = AudespSpacing.md,
    this.runSpacing = AudespSpacing.md,
    this.stackBreakpoint = 640,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withVerticalSpacing(
              children.map((item) => item.child).toList(),
            ),
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: _withHorizontalSpacing(
            children.map((item) {
              if (item.width != null) {
                return SizedBox(width: item.width, child: item.child);
              }
              return Expanded(flex: item.flex, child: item.child);
            }).toList(),
          ),
        );
      },
    );
  }

  List<Widget> _withHorizontalSpacing(List<Widget> widgets) {
    return [
      for (var i = 0; i < widgets.length; i++) ...[
        if (i > 0) SizedBox(width: spacing),
        widgets[i],
      ],
    ];
  }

  List<Widget> _withVerticalSpacing(List<Widget> widgets) {
    return [
      for (var i = 0; i < widgets.length; i++) ...[
        if (i > 0) SizedBox(height: runSpacing),
        widgets[i],
      ],
    ];
  }
}
