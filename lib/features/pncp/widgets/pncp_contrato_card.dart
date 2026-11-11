import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/prazo_envio_indicador.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../pendencias/domain/prazo_envio.dart';
import '../domain/pncp_contratos_pendencias.dart';
import 'abrir_pncp_button.dart';

class PncpContratoCard extends ConsumerWidget {
  final PendenciaContratoPncp pendencia;
  final PrazoEnvio? prazo;

  const PncpContratoCard({super.key, required this.pendencia, this.prazo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contrato = pendencia.contrato;
    final edital = pendencia.edital;
    final colors = Theme.of(context).colorScheme;
    final formato = DateFormat('dd/MM/yyyy');
    final inicio = contrato.vigenciaInicio;
    final fim = contrato.vigenciaFim;
    final detalhes = [
      if (contrato.valorGlobal != null)
        'Valor global: ${formatBRL(contrato.valorGlobal, casasDecimais: 2)}',
      if (inicio != null || fim != null)
        'Vigência: ${inicio == null ? 'não informada' : formato.format(inicio)}'
            ' a ${fim == null ? 'não informada' : formato.format(fim)}',
      if (edital != null) 'Edital: ${tituloEdital(edital)}',
      if (contrato.dispensado)
        'Dispensado em ${formato.format(contrato.dispensadaEm!)}'
            '${contrato.motivoDispensa == null ? '' : ': ${contrato.motivoDispensa}'}',
    ];
    final destaque = pendencia.liberado && !contrato.dispensado;
    return DocumentCard(
      icon: contrato.dispensado
          ? Icons.block
          : pendencia.liberado
          ? Icons.description_outlined
          : Icons.lock_outline,
      iconBackgroundColor: destaque
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      iconColor: destaque ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      title: tituloPncpContrato(contrato),
      subtitle: DocumentCardSubtitle(
        descricao: contrato.objeto,
        detalhes: detalhes,
        alerta: pendencia.liberado
            ? null
            : 'Bloqueado: ${pendencia.motivoBloqueio}',
      ),
      chips: [
        PrazoEnvioIndicador(prazo: prazo),
        if (pendencia.adesaoParticipacao)
          const StatusChip(label: 'Adesão/participação'),
      ],
      actions: [
        AbrirPncpButton(
          url:
              'https://pncp.gov.br/app/contratos/${contrato.cnpj}/${contrato.ano}/${contrato.sequencial}',
        ),
        if (pendencia.liberado && !contrato.dispensado) ...[
          const SizedBox(width: 4),
          FilledButton.tonalIcon(
            onPressed: () =>
                context.go('/ajuste/new?pncpContratoId=${contrato.id}'),
            icon: const Icon(Icons.post_add),
            label: const Text('Lançar ajuste'),
          ),
        ],
      ],
    );
  }
}

String tituloPncpContrato(PncpContrato contrato) => [
  contrato.numeroContrato.isEmpty
      ? 'Contrato PNCP ${contrato.sequencial}/${contrato.ano}'
      : 'Contrato ${contrato.numeroContrato}/${contrato.ano}',
  contrato.nomeFornecedor,
].where((p) => p.isNotEmpty).join(' — ');
