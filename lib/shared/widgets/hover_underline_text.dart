import 'package:flutter/material.dart';

/// Hover text with dotted underline + hand cursor.
/// Unlike [HoverCellText], this widget delegates taps to [onTap]
/// (typically the parent InkWell or GestureDetector).
class HoverUnderlineText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback? onTap;

  const HoverUnderlineText({
    super.key,
    required this.text,
    this.style,
    this.onTap,
  });

  @override
  State<HoverUnderlineText> createState() => _HoverUnderlineTextState();
}

class _HoverUnderlineTextState extends State<HoverUnderlineText> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      widget.text,
      style: (widget.style ?? const TextStyle()).copyWith(
        decoration: _hovering ? TextDecoration.underline : TextDecoration.none,
        decorationStyle: TextDecorationStyle.dotted,
      ),
    );

    if (widget.onTap != null) {
      child = GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: child,
        ),
      );
    } else {
      child = MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: child,
      );
    }

    return child;
  }
}
