import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../edital_providers.dart' show editaisDraftProvider, editaisEnviadosProvider;
import '../widgets/pcnp_input_formatter.dart';

class EditalPage extends ConsumerStatefulWidget {
  const EditalPage({super.key});

  @override
  ConsumerState<EditalPage> createState() => _EditalPageState();
}

class _EditalPageState extends ConsumerState<EditalPage> {
  String _statusFilter = 'draft';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editais'),
        actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/edital/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Edital'),
      ),
      body: _EditalList(status: _statusFilter),
    );
  }
}

class _EditalList extends ConsumerWidget {
  final String status;
  const _EditalList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(editaisDraftProvider)
        : ref.watch(editaisEnviadosProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (editais) {
        if (editais.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'draft'
                      ? Icons.description_outlined
                      : Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'draft'
                      ? 'Nenhum rascunho de edital'
                      : 'Nenhum edital enviado',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: editais.length,
          itemBuilder: (context, i) =>
              _EditalCard(edital: editais[i]),
        );
      },
    );
  }
}

class _EditalCard extends ConsumerWidget {
  final Edital edital;
  const _EditalCard({required this.edital});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSent = edital.status == 'sent';
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isSent
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            isSent ? Icons.check : Icons.edit_outlined,
            color: isSent
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          [
            PcnpInputFormatter.applyMask(edital.idContratacaoPNCP),
            if (edital.modalidadeLabel.isNotEmpty &&
                edital.numeroCompra.isNotEmpty &&
                edital.anoCompra != 0)
              '${edital.modalidadeLabel} ${edital.numeroCompra}/${edital.anoCompra}',
          ].join(' - '),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (edital.objetoCompra.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                edital.objetoCompra,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(140),
                    ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12),
                const SizedBox(width: 4),
                Text(
                  fmt.format(edital.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (edital.retificacao)
              Chip(
                label: const Text('Retificação'),
                backgroundColor: colorScheme.tertiaryContainer,
                labelStyle:
                    TextStyle(color: colorScheme.onTertiaryContainer),
                padding: EdgeInsets.zero,
              ),
            const SizedBox(width: 4),
            if (!isSent)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                tooltip: 'Excluir',
                onPressed: () => _confirmDelete(context, ref),
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'Abrir',
              onPressed: () => context.go('/edital/${edital.id}'),
            ),
          ],
        ),
        onTap: () => context.go('/edital/${edital.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Edital'),
        content: Text(
            'Deseja excluir o edital "${edital.codigoEdital}"? Esta ação não pode ser desfeita.'),
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
        await ref.read(editaisDaoProvider).deleteById(edital.id);
        ref.invalidate(editaisDraftProvider);
        ref.invalidate(editaisEnviadosProvider);
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

