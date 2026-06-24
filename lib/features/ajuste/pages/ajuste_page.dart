import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../ajuste_providers.dart';

class AjustePage extends ConsumerStatefulWidget {
  const AjustePage({super.key});

  @override
  ConsumerState<AjustePage> createState() => _AjustePageState();
}

class _AjustePageState extends ConsumerState<AjustePage> {
  String _statusFilter = 'draft';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes (Contratos)'),
        actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 8.0),
              child: SizedBox(
                width: 160,
                child: AudespDropdown<String>.items(
                  label: 'Status',
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Rascunhos', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'sent', child: Text('Enviados', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _statusFilter = v);
                    }
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
              onPressed: () {
                ref.invalidate(ajustesDraftProvider);
                ref.invalidate(ajustesEnviadosProvider);
              },
            ),
            const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ajuste/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Ajuste'),
      ),
      body: _AjusteList(status: _statusFilter),
    );
  }
}

class _AjusteList extends ConsumerWidget {
  final String status;
  const _AjusteList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(ajustesDraftProvider)
        : ref.watch(ajustesEnviadosProvider);

    final editaisAsync = ref.watch(_editaisMapProvider);
    final atasAsync = ref.watch(_atasMapProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (ajustes) {
        if (ajustes.isEmpty) {
          return EmptyState(
            icon: status == 'draft'
                ? Icons.article_outlined
                : Icons.check_circle_outline,
            message: status == 'draft'
                ? 'Nenhum rascunho de ajuste'
                : 'Nenhum ajuste enviado',
          );
        }
        return editaisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (editaisMap) {
            return atasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (atasMap) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: ajustes.length,
               itemBuilder: (context, i) {
                 final ajuste = ajustes[i];
                 final edital = editaisMap[ajuste.editalId];
                 final ata = ajuste.ataId != null ? atasMap[ajuste.ataId] : null;
                 final isSent = ajuste.status == 'sent';
                 final colorScheme = Theme.of(context).colorScheme;
                 final fmt = DateFormat('dd/MM/yyyy HH:mm');

                 return DocumentCard(
                   icon: isSent ? Icons.check : Icons.edit_outlined,
                   iconBackgroundColor: isSent
                       ? colorScheme.primaryContainer
                       : colorScheme.surfaceContainerHighest,
                   iconColor: isSent
                       ? colorScheme.onPrimaryContainer
                       : colorScheme.onSurfaceVariant,
                   title: [
                     PcnpInputFormatter.applyMask(ajuste.codigoContrato),
                     if (ajuste.numeroContratoEmpenho.isNotEmpty && ajuste.anoContrato != 0)
                       'Ajuste ${ajuste.numeroContratoEmpenho}/${ajuste.anoContrato}',
                   ].join(' - '),
                   subtitle: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Builder(builder: (context) {
                         final parts = <String>[
                           if (edital != null &&
                               edital.modalidadeLabel.isNotEmpty &&
                               edital.numeroCompra.isNotEmpty &&
                               edital.anoCompra != 0)
                             '${edital.modalidadeLabel} ${edital.numeroCompra}/${edital.anoCompra} - ${PcnpInputFormatter.applyMask(edital.idContratacaoPNCP)}',
                           if (ajuste.codigoAta != null &&
                               ata != null &&
                               ata.numeroAtaRegistroPreco.isNotEmpty &&
                               ata.anoAta != 0)
                             'Ata ${ata.numeroAtaRegistroPreco}/${ata.anoAta} - ${PcnpInputFormatter.applyMask(ajuste.codigoAta!)}',
                         ];
                         if (parts.isEmpty) return const SizedBox.shrink();
                         return Padding(
                           padding: const EdgeInsets.only(top: 2.0),
                           child: Text(
                             parts.join(' | '),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                   color: colorScheme.onSurface.withAlpha(140),
                                 ),
                           ),
                         );
                       }),
                       if (edital?.objetoCompra.isNotEmpty == true) ...[
                         const SizedBox(height: 2),
                         Text(
                           edital!.objetoCompra,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                 color: colorScheme.onSurface.withAlpha(140),
                               ),
                         ),
                       ],
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           const Icon(Icons.access_time, size: 12),
                           const SizedBox(width: 4),
                           Text(
                             fmt.format(ajuste.updatedAt),
                             style: Theme.of(context).textTheme.bodySmall,
                           ),
                         ],
                       ),
                     ],
                   ),
                   chips: [
                     if (ajuste.retificacao)
                       Chip(
                         label: const Text('Retificação'),
                         backgroundColor: colorScheme.tertiaryContainer,
                         labelStyle: TextStyle(color: colorScheme.onTertiaryContainer),
                         padding: EdgeInsets.zero,
                       ),
                   ],
                   onDelete: isSent ? null : () => _confirmDelete(context, ref, ajuste),
                   onNavigate: () => context.go('/ajuste/${ajuste.id}'),
                   onTap: () => context.go('/ajuste/${ajuste.id}'),
                 );
               },
                );
              },
            );
          },
        );
      },
    );
  }
}

final _editaisMapProvider = FutureProvider<Map<int, Edital>>((ref) async {
  final editais = await ref.watch(editaisDaoProvider).watchAll();
  return {for (final e in editais) e.id: e};
});

final _atasMapProvider = FutureProvider<Map<int, Ata>>((ref) async {
  final atas = await ref.watch(atasDaoProvider).watchAll();
  return {for (final a in atas) a.id: a};
});

Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Ajuste ajuste) async {
  final confirmed = await showAudespDeleteDialog(
    context: context,
    title: 'Excluir Ajuste',
    entityName: ajuste.codigoContrato,
    entityLabel: 'o ajuste',
  );
  if (confirmed == true) {
    try {
      await ref.read(ajustesDaoProvider).deleteById(ajuste.id);
      ref.invalidate(ajustesDraftProvider);
      ref.invalidate(ajustesEnviadosProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
