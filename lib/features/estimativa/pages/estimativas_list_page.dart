import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../estimativa_providers.dart';
import '../models/estimativa_model.dart';

class EstimativasListPage extends ConsumerStatefulWidget {
  const EstimativasListPage({super.key});

  @override
  ConsumerState<EstimativasListPage> createState() =>
      _EstimativasListPageState();
}

class _EstimativasListPageState extends ConsumerState<EstimativasListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimativas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () {
              ref.invalidate(estimativasListProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/estimativa/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Estimativa'),
      ),
      body: const _EstimativaList(),
    );
  }
}

class _EstimativaList extends ConsumerWidget {
  const _EstimativaList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(estimativasListProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (estimativas) {
        if (estimativas.isEmpty) {
          return const EmptyState(
            icon: Icons.calculate_outlined,
            message: 'Nenhuma estimativa cadastrada',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: estimativas.length,
          itemBuilder: (context, i) {
            final estimativa = estimativas[i];
            final colorScheme = Theme.of(context).colorScheme;
            final fmt = DateFormat('dd/MM/yyyy HH:mm');

            final updateDate = DateTime.fromMillisecondsSinceEpoch(
              estimativa.updatedAt * 1000,
            );
            final valorTotalFmt = NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
            ).format(estimativa.valorTotalGlobal);

            return DocumentCard(
              icon: Icons.calculate_outlined,
              iconBackgroundColor: colorScheme.surfaceContainerHighest,
              iconColor: colorScheme.onSurfaceVariant,
              title: 'Estimativa ${estimativa.numero}/${estimativa.ano}',
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (estimativa.objeto.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      estimativa.objeto,
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
                        fmt.format(updateDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              chips: [
                Chip(
                  label: Text(valorTotalFmt),
                  backgroundColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
              onDelete: () => _confirmDelete(context, ref, estimativa),
              onNavigate: () => context.go('/estimativa/${estimativa.id}'),
              onTap: () => context.go('/estimativa/${estimativa.id}'),
            );
          },
        );
      },
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  EstimativaModel estimativa,
) async {
  final confirmed = await showAudespDeleteDialog(
    context: context,
    title: 'Excluir Estimativa',
    entityName: 'Estimativa ${estimativa.numero}/${estimativa.ano}',
  );
  if (confirmed == true) {
    try {
      await ref.read(estimativasDaoProvider).deleteById(estimativa.id);
      ref.invalidate(estimativasListProvider);
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
