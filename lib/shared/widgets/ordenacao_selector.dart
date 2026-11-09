import 'package:flutter/material.dart';

import '../../core/utils/ordenacao_documentos.dart';
import 'audesp_dropdown.dart';
import 'audesp_icon_button.dart';

/// "Ordenar por" das barras de filtro, com o botão de sentido ao lado.
class OrdenacaoSelector extends StatelessWidget {
  final OrdenarPor value;
  final bool decrescente;
  final ValueChanged<OrdenarPor> onChanged;
  final ValueChanged<bool> onSentidoChanged;

  const OrdenacaoSelector({
    super.key,
    required this.value,
    required this.decrescente,
    required this.onChanged,
    required this.onSentidoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 112,
          child: AudespDropdown<OrdenarPor>(
            label: 'Ordenar por',
            value: value,
            items: {for (final o in OrdenarPor.values) o: o.rotulo},
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
        AudespIconButton(
          icon: decrescente ? Icons.arrow_downward : Icons.arrow_upward,
          tooltip: decrescente ? 'Decrescente' : 'Crescente',
          onPressed: () => onSentidoChanged(!decrescente),
        ),
      ],
    );
  }
}
