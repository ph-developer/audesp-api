import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/formatters/pcnp_input_formatter.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/document_card.dart';
import '../../auth/auth_providers.dart';
import '../../edital/domain/edital_domain.dart';
import '../../processo/domain/ufesp_rules.dart';
import '../../processo/widgets/ufesp_indicador.dart';
import '../pncp_providers.dart';

/// Compra do PNCP sem edital no sistema, com as ações de iniciar o edital
/// ou dispensar (restaurar, quando já dispensada).
class PncpCompraCard extends ConsumerWidget {
  final PncpCompra compra;
  final UfespConfig ufesp;

  const PncpCompraCard({super.key, required this.compra, required this.ufesp});

  Future<void> _dispensar(BuildContext context, WidgetRef ref) async {
    final motivo = await showAudespDialog<String>(
      context: context,
      builder: (_) => const _DispensarDialog(),
    );
    if (motivo == null) return;
    await ref
        .read(pncpComprasDaoProvider)
        .dispensar(
          compra.id,
          userId: ref.read(localSessionProvider)?.id,
          motivo: motivo,
        );
    ref.invalidate(pncpComprasProvider);
    if (context.mounted) {
      AudespSnackBar.success(context, 'Compra dispensada das pendências.');
    }
  }

  Future<void> _restaurar(BuildContext context, WidgetRef ref) async {
    await ref.read(pncpComprasDaoProvider).restaurar(compra.id);
    ref.invalidate(pncpComprasProvider);
    if (context.mounted) {
      AudespSnackBar.success(context, 'Compra restaurada nas pendências.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final titulo = tituloPncpCompra(compra);
    final detalhes = [
      if (compra.valorTotalEstimado != null)
        'Valor estimado: ${formatBRL(compra.valorTotalEstimado, casasDecimais: 2)}',
      if (compra.dataPublicacao != null)
        'Publicada no PNCP em ${DateFormat('dd/MM/yyyy').format(compra.dataPublicacao!)}',
      if (compra.dispensada)
        'Dispensada em ${DateFormat('dd/MM/yyyy').format(compra.dispensadaEm!)}'
            '${compra.motivoDispensa == null ? '' : ': ${compra.motivoDispensa}'}',
    ];

    final colors = theme.colorScheme;
    return DocumentCard(
      icon: compra.dispensada ? Icons.block : Icons.travel_explore,
      iconBackgroundColor: compra.dispensada
          ? colors.surfaceContainerHighest
          : colors.primaryContainer,
      iconColor: compra.dispensada
          ? colors.onSurfaceVariant
          : colors.onPrimaryContainer,
      title: titulo,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compra.objeto.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              compra.objeto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withAlpha(140),
              ),
            ),
          ],
          if (detalhes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(detalhes.join('  |  '), style: theme.textTheme.bodySmall),
          ],
        ],
      ),
      chips: [
        UfespIndicador(valorEstimado: compra.valorTotalEstimado, config: ufesp),
      ],
      actions: [
        const SizedBox(width: 4),
        if (compra.dispensada)
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
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () =>
                context.go('/edital/new?pncpCompraId=${compra.id}'),
            icon: const Icon(Icons.post_add),
            label: const Text('Iniciar edital'),
          ),
        ],
      ],
    );
  }
}

String tituloPncpCompra(PncpCompra compra) => [
  PcnpInputFormatter.applyMask(compra.numeroControle),
  [
    if (compra.modalidadeId != null)
      kModalidadesDropdown[compra.modalidadeId] ?? '',
    if (compra.numeroCompra.isNotEmpty) '${compra.numeroCompra}/${compra.ano}',
  ].where((part) => part.isNotEmpty).join(' '),
].where((part) => part.isNotEmpty).join(' - ');

class _DispensarDialog extends StatefulWidget {
  const _DispensarDialog();

  @override
  State<_DispensarDialog> createState() => _DispensarDialogState();
}

class _DispensarDialogState extends State<_DispensarDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dispensar compra do PNCP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A compra deixa de aparecer nas pendências. Ela pode ser '
            'restaurada na visão "Todos".',
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
}
