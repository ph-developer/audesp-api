import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/pendencias/domain/prazo_envio.dart';

/// Chip informativo com o prazo de envio ao AUDESP; não bloqueia nada.
class PrazoEnvioIndicador extends StatelessWidget {
  final PrazoEnvio? prazo;

  /// Só para testes; padrão: agora.
  final DateTime? hoje;

  const PrazoEnvioIndicador({super.key, required this.prazo, this.hoje});

  @override
  Widget build(BuildContext context) {
    final prazo = this.prazo;
    if (prazo == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final agora = hoje ?? DateTime.now();
    final data = DateFormat('dd/MM/yyyy').format(prazo.limite);
    final situacao = prazo.situacao(agora);
    final restantes = prazo.diasRestantes(agora);
    final (texto, icone, cor) = switch (situacao) {
      SituacaoPrazo.vencido => (
        'Prazo AUDESP vencido em $data',
        Icons.error_outline,
        theme.colorScheme.error,
      ),
      SituacaoPrazo.venceHoje => (
        'Prazo AUDESP vence hoje',
        Icons.warning_amber_rounded,
        theme.colorScheme.error,
      ),
      SituacaoPrazo.proximo => (
        'Prazo AUDESP até $data · '
            '$restantes ${restantes == 1 ? 'dia útil' : 'dias úteis'}',
        Icons.warning_amber_rounded,
        Colors.orange.shade800,
      ),
      SituacaoPrazo.emDia => (
        'Prazo AUDESP até $data',
        Icons.schedule,
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    final restam = switch (situacao) {
      SituacaoPrazo.vencido => '',
      SituacaoPrazo.venceHoje => ' Vence hoje.',
      _ =>
        ' ${restantes == 1 ? 'Resta 1 dia útil' : 'Restam $restantes dias úteis'}.',
    };
    return Tooltip(
      message: '${prazo.explicacao}$restam Alerta apenas informativo.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: ShapeDecoration(
          color: cor.withAlpha(20),
          shape: StadiumBorder(side: BorderSide(color: cor.withAlpha(100))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 6),
            Text(
              texto,
              style: theme.textTheme.labelMedium?.copyWith(color: cor),
            ),
          ],
        ),
      ),
    );
  }
}
