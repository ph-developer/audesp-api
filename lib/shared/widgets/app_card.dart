import 'package:fluent_ui/fluent_ui.dart';

/// Card padronizado do projeto com padding uniforme e bordas sutis.
///
/// Uso:
/// ```dart
/// AppCard(
///   child: Text('Conteúdo'),
/// )
/// AppCard(
///   padding: EdgeInsets.all(20),
///   onPressed: () { ... },
///   child: Text('Card clicável'),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onPressed,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      padding: padding,
      child: child,
    );

    if (onPressed != null) {
      return GestureDetector(
        onTap: onPressed,
        child: card,
      );
    }
    return card;
  }
}
