import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/formatters/pcnp_input_formatter.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/prazo_envio_indicador.dart';
import '../../pendencias/domain/prazo_envio.dart';
import '../domain/pncp_atas_pendencias.dart';
import 'abrir_pncp_button.dart';

class PncpAtaCard extends ConsumerWidget {
  final PendenciaAtaPncp pendencia;
  final PrazoEnvio? prazo;

  const PncpAtaCard({super.key, required this.pendencia, this.prazo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ata = pendencia.ata;
    final edital = pendencia.edital;
    final colors = Theme.of(context).colorScheme;
    final formato = DateFormat('dd/MM/yyyy');
    final inicio = ata.vigenciaInicio;
    final fim = ata.vigenciaFim;
    final detalhes = [
      'Compra: ${PcnpInputFormatter.applyMask(ata.numeroControleCompra)}',
      if (inicio != null || fim != null)
        'Vigência: ${inicio == null ? 'não informada' : formato.format(inicio)}'
            ' a ${fim == null ? 'não informada' : formato.format(fim)}',
      if (edital != null) 'Edital: ${tituloEdital(edital)}',
      if (ata.dispensada)
        'Dispensada em ${formato.format(ata.dispensadaEm!)}'
            '${ata.motivoDispensa == null ? '' : ': ${ata.motivoDispensa}'}',
    ];
    final destaque = pendencia.liberada && !ata.dispensada;
    return DocumentCard(
      icon: ata.dispensada
          ? Icons.block
          : pendencia.liberada
          ? Icons.description_outlined
          : Icons.lock_outline,
      iconBackgroundColor: destaque
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      iconColor: destaque ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      title: tituloPncpAta(ata),
      subtitle: DocumentCardSubtitle(
        descricao: ata.objeto,
        detalhes: detalhes,
        alerta: pendencia.liberada
            ? null
            : 'Bloqueada: ${pendencia.motivoBloqueio}',
      ),
      chips: [PrazoEnvioIndicador(prazo: prazo)],
      actions: [
        AbrirPncpButton(
          url:
              'https://pncp.gov.br/app/atas/${ata.cnpj}/${ata.anoCompra}/${ata.sequencialCompra}/${ata.sequencialAta}',
        ),
        if (pendencia.liberada && !ata.dispensada) ...[
          const SizedBox(width: 4),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/ata/new?pncpAtaId=${ata.id}'),
            icon: const Icon(Icons.post_add),
            label: const Text('Lançar ata'),
          ),
        ],
      ],
    );
  }
}

String tituloPncpAta(PncpAta ata) => ata.numeroAta.isEmpty
    ? 'Ata PNCP ${ata.sequencialAta}${ata.anoAta == null ? '' : '/${ata.anoAta}'}'
    : 'Ata ${ata.numeroAta}${ata.anoAta == null ? '' : '/${ata.anoAta}'}';
