import 'package:flutter/material.dart';

/// Métricas compartilhadas pelos campos de formulário AUDESP.
///
/// A altura de [fieldHeight] considera inputs de uma linha, sem helper ou
/// mensagem de erro. Esses textos continuam ocupando espaço adicional abaixo
/// do contorno para não serem comprimidos.
abstract final class AudespInputMetrics {
  static const double fieldHeight = 40;
  static const double textLineHeight = 20;

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  // O conteúdo denso do DropdownButton possui altura mínima própria de 24 px.
  static const EdgeInsets dropdownContentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  static TextStyle textStyle(BuildContext context, {Color? color}) {
    final base = Theme.of(context).textTheme.bodyLarge;
    final fontSize = base?.fontSize ?? 14;
    return (base ?? const TextStyle(fontSize: 14)).copyWith(
      height: textLineHeight / fontSize,
      color: color,
    );
  }
}
