import 'package:flutter/material.dart';

/// FAB customizado que expande horizontalmente ao passar o mouse,
/// revelando texto à esquerda do ícone. Largura calculada dinamicamente
/// com base no tamanho real do texto.
class HoverExpandFab extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final String heroTag;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const HoverExpandFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.heroTag,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<HoverExpandFab> createState() => _HoverExpandFabState();
}

class _HoverExpandFabState extends State<HoverExpandFab> {
  bool _expanded = false;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.primaryContainer;
    final fg = widget.foregroundColor ?? theme.colorScheme.onPrimaryContainer;

    final textStyle = TextStyle(
      color: fg,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: widget.tooltip, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width.clamp(0.0, 156.0);
    final expandedWidth = 40 + textWidth + 24;

    return MouseRegion(
      onEnter: (_) => setState(() => _expanded = true),
      onExit: (_) => setState(() => _expanded = false),
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOut,
        width: _expanded ? expandedWidth : 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRect(
                  child: AnimatedContainer(
                    duration: _duration,
                    curve: Curves.easeOut,
                    width: _expanded ? textWidth + 16 : 0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          widget.tooltip,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: textStyle,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(widget.icon, color: fg, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
