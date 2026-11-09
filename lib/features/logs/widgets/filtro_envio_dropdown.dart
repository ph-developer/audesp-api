import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_dropdown.dart';
import '../domain/ultimo_envio.dart';

/// Filtro da barra das listagens pelo status do último envio ao AUDESP.
class FiltroEnvioDropdown extends StatelessWidget {
  final FiltroEnvio value;
  final ValueChanged<FiltroEnvio> onChanged;

  const FiltroEnvioDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: AudespDropdown<FiltroEnvio>(
        label: 'Status do envio',
        value: value,
        items: {for (final f in FiltroEnvio.values) f: f.rotulo},
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
