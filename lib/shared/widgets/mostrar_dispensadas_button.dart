import 'package:flutter/material.dart';

import 'audesp_icon_button.dart';

/// Alterna a exibição dos itens dispensados na aba Pendências.
class MostrarDispensadasButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Concordância do rótulo: "dispensadas" (compras, atas) ou
  /// "dispensados" (contratos).
  final bool feminino;

  const MostrarDispensadasButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.feminino = true,
  });

  @override
  Widget build(BuildContext context) {
    final rotulo = feminino ? 'dispensadas' : 'dispensados';
    return AudespIconButton(
      icon: value ? Icons.inventory_2 : Icons.inventory_2_outlined,
      color: value ? Theme.of(context).colorScheme.primary : null,
      tooltip: value ? 'Ocultar $rotulo' : 'Mostrar $rotulo',
      onPressed: () => onChanged(!value),
    );
  }
}
