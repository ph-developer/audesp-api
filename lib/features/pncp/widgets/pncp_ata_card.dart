import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/formatters/pcnp_input_formatter.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/document_card.dart';
import '../../auth/auth_providers.dart';
import '../domain/pncp_atas_pendencias.dart';
import '../pncp_providers.dart';

class PncpAtaCard extends ConsumerWidget {
  final PendenciaAtaPncp pendencia;

  const PncpAtaCard({super.key, required this.pendencia});

  Future<void> _dispensar(BuildContext context, WidgetRef ref) async {
    final motivo = await showAudespDialog<String>(
      context: context,
      builder: (_) => const _DispensarAtaDialog(),
    );
    if (motivo == null || !context.mounted) return;
    try {
      await ref
          .read(pncpAtasDaoProvider)
          .dispensar(
            pendencia.ata.id,
            userId: ref.read(localSessionProvider)?.id,
            motivo: motivo,
          );
      ref.invalidate(pncpAtasProvider);
      if (context.mounted) {
        AudespSnackBar.success(context, 'Ata dispensada das pendências.');
      }
    } catch (e) {
      if (context.mounted) {
        AudespSnackBar.error(context, 'Erro ao dispensar: $e');
      }
    }
  }

  Future<void> _restaurar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pncpAtasDaoProvider).restaurar(pendencia.ata.id);
      ref.invalidate(pncpAtasProvider);
      if (context.mounted) {
        AudespSnackBar.success(context, 'Dispensa da ata removida.');
      }
    } catch (e) {
      if (context.mounted) {
        AudespSnackBar.error(context, 'Erro ao restaurar: $e');
      }
    }
  }

  Future<void> _abrirPncp(BuildContext context, String url) async {
    try {
      final resultado = Platform.isWindows
          ? await Process.run('rundll32.exe', [
              'url.dll,FileProtocolHandler',
              url,
            ])
          : await Process.run(Platform.isMacOS ? 'open' : 'xdg-open', [url]);
      if (resultado.exitCode != 0) {
        throw const ProcessException('', [], 'Falha ao abrir o navegador.');
      }
    } catch (e) {
      if (context.mounted) {
        AudespSnackBar.error(context, 'Erro ao abrir o PNCP: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ata = pendencia.ata;
    final edital = pendencia.edital;
    final colors = Theme.of(context).colorScheme;
    final formato = DateFormat('dd/MM/yyyy');
    final url =
        'https://pncp.gov.br/app/atas/${ata.cnpj}/${ata.anoCompra}/${ata.sequencialCompra}/${ata.sequencialAta}';
    return DocumentCard(
      icon: ata.dispensada ? Icons.block : Icons.description_outlined,
      title: tituloPncpAta(ata),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ata.objeto.isNotEmpty) Text(ata.objeto),
          Text(
            'Vigência: ${ata.vigenciaInicio == null ? 'não informada' : formato.format(ata.vigenciaInicio!)}'
            ' a ${ata.vigenciaFim == null ? 'não informada' : formato.format(ata.vigenciaFim!)}',
          ),
          Text(
            'Compra: ${PcnpInputFormatter.applyMask(ata.numeroControleCompra)}',
          ),
          if (edital != null)
            TextButton(
              onPressed: () => context.go('/edital/${edital.id}'),
              child: Text(tituloEdital(edital)),
            ),
          Text(
            pendencia.liberada
                ? 'Liberada para lançar ata.'
                : 'Bloqueada: ${pendencia.motivoBloqueio}',
            style: TextStyle(
              color: pendencia.liberada ? colors.primary : colors.error,
            ),
          ),
          if (ata.dispensada)
            Text(
              'Dispensada em ${formato.format(ata.dispensadaEm!)}'
              '${ata.motivoDispensa == null ? '' : ': ${ata.motivoDispensa}'}',
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Tooltip(
                message: url,
                child: TextButton.icon(
                  onPressed: () => _abrirPncp(context, url),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir no PNCP'),
                ),
              ),
              if (ata.dispensada)
                TextButton.icon(
                  onPressed: () => _restaurar(context, ref),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurar'),
                )
              else ...[
                TextButton.icon(
                  onPressed: () => _dispensar(context, ref),
                  icon: const Icon(Icons.block),
                  label: const Text('Dispensar'),
                ),
                if (pendencia.liberada)
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/ata/new?pncpAtaId=${ata.id}'),
                    icon: const Icon(Icons.post_add),
                    label: const Text('Lançar ata'),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String tituloPncpAta(PncpAta ata) => ata.numeroAta.isEmpty
    ? 'Ata PNCP ${ata.sequencialAta}${ata.anoAta == null ? '' : '/${ata.anoAta}'}'
    : 'Ata ${ata.numeroAta}${ata.anoAta == null ? '' : '/${ata.anoAta}'}';

class _DispensarAtaDialog extends StatefulWidget {
  const _DispensarAtaDialog();
  @override
  State<_DispensarAtaDialog> createState() => _DispensarAtaDialogState();
}

class _DispensarAtaDialogState extends State<_DispensarAtaDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Dispensar ata do PNCP'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A ata deixa de aparecer nas pendências. Ela pode ser '
          'restaurada usando "Mostrar dispensadas" na aba Pendências.',
        ),
        const SizedBox(height: 12),
        AudespTextField(
          label: 'Motivo (opcional)',
          controller: _motivoCtrl,
          maxLength: 500,
          maxLines: 2,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_motivoCtrl.text.trim()),
        child: const Text('Dispensar'),
      ),
    ],
  );
}
