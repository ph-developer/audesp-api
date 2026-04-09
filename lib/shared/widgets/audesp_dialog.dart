import 'package:flutter/material.dart';

/// Tamanhos semânticos para diálogos AUDESP.
///
/// | Tamanho | maxWidth |
/// |---------|----------|
/// | small   |   400 px |
/// | medium  |   600 px |
/// | large   |   800 px |
enum DialogSize { small, medium, large }

extension _DialogSizeExt on DialogSize {
  double get maxWidth => switch (this) {
        DialogSize.small => 400,
        DialogSize.medium => 600,
        DialogSize.large => 800,
      };
}

/// Helper que exibe um [AlertDialog] responsivo.
///
/// O conteúdo é envolto em um [ConstrainedBox] que limita a largura máxima
/// conforme [size], impedindo overflow em telas menores.
///
/// Exemplo:
/// ```dart
/// await showAudespDialog<bool>(
///   context: context,
///   size: DialogSize.medium,
///   builder: (_) => const MeuDialog(),
/// );
/// ```
Future<T?> showAudespDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  DialogSize size = DialogSize.medium,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => _AudespDialogConstraint(
      size: size,
      child: builder(ctx),
    ),
  );
}

/// Widget interno que aplica a constraint de largura num filho arbitrário.
///
/// Pode ser usado diretamente quando o diálogo é construído fora de
/// [showAudespDialog] (ex: em testes de widget).
class _AudespDialogConstraint extends StatelessWidget {
  final DialogSize size;
  final Widget child;

  const _AudespDialogConstraint({
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: size.maxWidth),
      child: child,
    );
  }
}
