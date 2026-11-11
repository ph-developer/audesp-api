import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../features/processo/domain/ufesp_rules.dart';
import 'indicador_icone.dart';

/// Ícone "Envio não obrigatório" para valores abaixo do mínimo em UFESP.
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
    return IndicadorIcone(
      icone: Icons.info_outline,
      cor: Theme.of(context).colorScheme.tertiary,
      titulo: 'Envio não obrigatório',
      detalhe:
          'Valor estimado ${formatBRL(valorEstimado, casasDecimais: 2)} abaixo '
          'de ${NumberFormat.decimalPattern('pt_BR').format(config.quantidadeMinima)} '
          'UFESP (${formatBRL(config.limite, casasDecimais: 2)}).',
    );
  }
}
