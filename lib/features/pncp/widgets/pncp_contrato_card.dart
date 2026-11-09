import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/document_card.dart';
import '../../auth/auth_providers.dart';
import '../domain/pncp_contratos_pendencias.dart';
import '../pncp_providers.dart';

class PncpContratoCard extends ConsumerWidget {
  final PendenciaContratoPncp pendencia;

  const PncpContratoCard({super.key, required this.pendencia});

  Future<void> _dispensar(BuildContext context, WidgetRef ref) async {
    final motivo = await showAudespDialog<String>(
      context: context,
      builder: (_) => const _DispensarContratoDialog(),
    );
    if (motivo == null || !context.mounted) return;
    try {
      await ref
          .read(pncpContratosDaoProvider)
          .dispensar(
            pendencia.contrato.id,
            userId: ref.read(localSessionProvider)?.id,
            motivo: motivo,
          );
      ref.invalidate(pncpContratosProvider);
      if (context.mounted) {
        AudespSnackBar.success(context, 'Contrato dispensado das pendências.');
      }
    } catch (e) {
      if (context.mounted) {
        AudespSnackBar.error(context, 'Erro ao dispensar: $e');
      }
    }
  }

  Future<void> _restaurar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pncpContratosDaoProvider).restaurar(pendencia.contrato.id);
      ref.invalidate(pncpContratosProvider);
      if (context.mounted) {
        AudespSnackBar.success(context, 'Contrato restaurado nas pendências.');
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
    final contrato = pendencia.contrato;
    final edital = pendencia.edital;
    final colors = Theme.of(context).colorScheme;
    final formato = DateFormat('dd/MM/yyyy');
    final url =
        'https://pncp.gov.br/app/contratos/${contrato.cnpj}/${contrato.ano}/${contrato.sequencial}';
    return DocumentCard(
      icon: contrato.dispensado ? Icons.block : Icons.description_outlined,
      title: tituloPncpContrato(contrato),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contrato.objeto.isNotEmpty) Text(contrato.objeto),
          if (contrato.valorGlobal != null)
            Text(
              'Valor global: ${formatBRL(contrato.valorGlobal, casasDecimais: 2)}',
            ),
          Text(
            'Vigência: ${contrato.vigenciaInicio == null ? 'não informada' : formato.format(contrato.vigenciaInicio!)}'
            ' a ${contrato.vigenciaFim == null ? 'não informada' : formato.format(contrato.vigenciaFim!)}',
          ),
          if (edital != null)
            TextButton(
              onPressed: () => context.go('/edital/${edital.id}'),
              child: Text(tituloEdital(edital)),
            ),
          if (pendencia.adesaoParticipacao) const Text('Adesão/participação'),
          Text(
            pendencia.liberado
                ? 'Liberado para lançar ajuste.'
                : 'Bloqueado: ${pendencia.motivoBloqueio}',
            style: TextStyle(
              color: pendencia.liberado ? colors.primary : colors.error,
            ),
          ),
          if (contrato.dispensado)
            Text(
              'Dispensado em ${formato.format(contrato.dispensadaEm!)}'
              '${contrato.motivoDispensa == null ? '' : ': ${contrato.motivoDispensa}'}',
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
              if (contrato.dispensado)
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
                if (pendencia.liberado)
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.go('/ajuste/new?pncpContratoId=${contrato.id}'),
                    icon: const Icon(Icons.post_add),
                    label: const Text('Lançar ajuste'),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String tituloPncpContrato(PncpContrato contrato) => [
  contrato.numeroContrato.isEmpty
      ? 'Contrato PNCP ${contrato.sequencial}/${contrato.ano}'
      : 'Contrato ${contrato.numeroContrato}/${contrato.ano}',
  contrato.nomeFornecedor,
].where((p) => p.isNotEmpty).join(' — ');

class _DispensarContratoDialog extends StatefulWidget {
  const _DispensarContratoDialog();

  @override
  State<_DispensarContratoDialog> createState() =>
      _DispensarContratoDialogState();
}

class _DispensarContratoDialogState extends State<_DispensarContratoDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Dispensar contrato do PNCP'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O contrato deixa de aparecer nas pendências. Ele pode ser '
          'restaurado usando "Mostrar dispensados" na aba Pendências.',
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
