import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../domain/ufesp_rules.dart';

/// Chip "Envio não obrigatório" para valores abaixo do mínimo em UFESP.
class UfespIndicador extends StatelessWidget {
  final double? valorEstimado;
  final UfespConfig config;

  const UfespIndicador({
    super.key,
    required this.valorEstimado,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    if (config.envioObrigatorio(valorEstimado)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    return Tooltip(
      message:
          'Valor estimado ${formatBRL(valorEstimado, casasDecimais: 2)} abaixo '
          'de ${NumberFormat.decimalPattern('pt_BR').format(config.quantidadeMinima)} '
          'UFESP (${formatBRL(config.limite, casasDecimais: 2)}).',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: ShapeDecoration(
          color: color.withAlpha(20),
          shape: StadiumBorder(side: BorderSide(color: color.withAlpha(100))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              'Envio não obrigatório',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
