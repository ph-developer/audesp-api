import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/pendencias/domain/prazo_envio.dart';
import 'indicador_icone.dart';

/// Ícone informativo com o prazo de envio ao AUDESP; não bloqueia nada.
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
    final restantes = prazo.diasRestantes(agora);
    final restam = restantes == 1
        ? 'Resta 1 dia útil.'
        : 'Restam $restantes dias úteis.';
    final (titulo, situacao, icone, cor) = switch (prazo.situacao(agora)) {
      SituacaoPrazo.vencido => (
        'Prazo AUDESP vencido em $data',
        null,
        Icons.error_outline,
        theme.colorScheme.error,
      ),
      SituacaoPrazo.venceHoje => (
        'Prazo AUDESP vence hoje ($data)',
        null,
        Icons.warning_amber_rounded,
        theme.colorScheme.error,
      ),
      SituacaoPrazo.proximo => (
        'Prazo AUDESP até $data',
        restam,
        Icons.warning_amber_rounded,
        Colors.orange.shade800,
      ),
      SituacaoPrazo.emDia => (
        'Prazo AUDESP até $data',
        restam,
        Icons.schedule,
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    return IndicadorIcone(
      icone: icone,
      cor: cor,
      titulo: titulo,
      detalhe: [prazo.explicacao, ?situacao].join(' '),
    );
  }
}
