import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma estimativa cadastrada',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: estimativas.length,
          itemBuilder: (context, i) =>
              _EstimativaCard(estimativa: estimativas[i]),
        );
      },
    );
  }
}

class _EstimativaCard extends ConsumerWidget {
  final EstimativaModel estimativa;
  const _EstimativaCard({required this.estimativa});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    final updateDate = DateTime.fromMillisecondsSinceEpoch(
      estimativa.updatedAt * 1000,
    );
    final valorTotalFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(estimativa.valorTotalGlobal);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.calculate_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Estimativa ${estimativa.numero}/${estimativa.ano}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
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
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(valorTotalFmt),
              backgroundColor: colorScheme.secondaryContainer,
              labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Excluir',
              onPressed: () => _confirmDelete(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'Abrir',
              onPressed: () => context.go('/estimativa/${estimativa.id}'),
            ),
          ],
        ),
        onTap: () => context.go('/estimativa/${estimativa.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Estimativa'),
        content: Text(
          'Deseja excluir a Estimativa ${estimativa.numero}/${estimativa.ano}? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
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
}
