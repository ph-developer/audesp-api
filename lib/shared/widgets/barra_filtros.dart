import 'package:flutter/material.dart';

/// Abas e filtros das listagens, na mesma linha do título da `AppBar`
/// (use dentro de um `Expanded`). Alinha à direita e rola na horizontal
/// quando a janela é estreita, em vez de estourar.
class BarraFiltros extends StatelessWidget {
  final List<Widget> children;

  const BarraFiltros({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        // Espaço para o rótulo flutuante dos campos não ser cortado.
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
