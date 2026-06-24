import 'package:flutter/material.dart';

class HoverCellText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback onTap;
  final String? tooltip;
  final int? maxLines;
  final TextOverflow? overflow;
  final Alignment? alignment;
  final double? width;
  final TextAlign? textAlign;

  const HoverCellText({
    super.key,
    required this.text,
    required this.onTap,
    this.style,
    this.tooltip,
    this.maxLines,
    this.overflow,
    this.alignment,
    this.width,
    this.textAlign,
  });

  @override
  State<HoverCellText> createState() => _HoverCellTextState();
}

class _HoverCellTextState extends State<HoverCellText> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      widget.text,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
      style: (widget.style ?? const TextStyle()).copyWith(
        decoration: _hovering ? TextDecoration.underline : TextDecoration.none,
        decorationStyle: TextDecorationStyle.dotted,
      ),
    );

    if (widget.alignment != null || widget.width != null) {
      child = Container(
        alignment: widget.alignment,
        width: widget.width,
        color: Colors.transparent,
        child: child,
      );
    }

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(onTap: widget.onTap, child: child),
    );
  }
}
