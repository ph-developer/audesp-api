import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/status_chip.dart';
import '../domain/ultimo_envio.dart';

/// Badge com o status do último envio do documento ao AUDESP.
class UltimoEnvioChip extends StatelessWidget {
  final EnvioResumo envio;

  const UltimoEnvioChip(this.envio, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color? cor, Color? fundo) = switch (envio.situacao) {
      SituacaoEnvio.falha ||
      SituacaoEnvio.rejeitado => (scheme.error, scheme.errorContainer),
      SituacaoEnvio.armazenado => (
        Colors.green.shade700,
        Colors.green.shade700.withAlpha(25),
      ),
      SituacaoEnvio.encerrado => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      SituacaoEnvio.emAndamento => (null, null),
    };

    final detalhes = [
      'Último envio em ${DateFormat('dd/MM/yyyy HH:mm').format(envio.timestamp)}',
      if (!envio.sucesso)
        envio.statusCode == null || envio.statusCode == 0
            ? 'Sem resposta do servidor'
            : 'HTTP ${envio.statusCode}',
      if (envio.protocolo != null) 'Protocolo ${envio.protocolo}',
    ];

    return Tooltip(
      message: detalhes.join('\n'),
      child: StatusChip(
        label: envio.rotulo,
        color: cor,
        backgroundColor: fundo,
        borderColor: cor?.withAlpha(80),
      ),
    );
  }
}
