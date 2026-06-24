import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../ata_providers.dart';

class AtaPage extends ConsumerStatefulWidget {
  const AtaPage({super.key});

  @override
  ConsumerState<AtaPage> createState() => _AtaPageState();
}

class _AtaPageState extends ConsumerState<AtaPage> {
  String _statusFilter = 'draft';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atas de Registro de Preço'),
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
                    DropdownMenuItem(value: 'sent', child: Text('Enviadas', overflow: TextOverflow.ellipsis)),
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
                ref.invalidate(atasDraftProvider);
                ref.invalidate(atasEnviadasProvider);
              },
            ),
            const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ata/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Ata'),
      ),
      body: _AtaList(status: _statusFilter),
    );
  }
}

class _AtaList extends ConsumerWidget {
  final String status;
  const _AtaList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(atasDraftProvider)
        : ref.watch(atasEnviadasProvider);

    final editaisAsync = ref.watch(_editaisMapProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (atas) {
        if (atas.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'draft'
                      ? Icons.assignment_outlined
                      : Icons.assignment_turned_in_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'draft'
                      ? 'Nenhum rascunho de ata'
                      : 'Nenhuma ata enviada',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }
        return editaisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (editaisMap) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: atas.length,
              itemBuilder: (context, i) => _AtaCard(
                ata: atas[i],
                edital: editaisMap[atas[i].editalId],
              ),
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

class _AtaCard extends ConsumerWidget {
  final Ata ata;
  final Edital? edital;
  const _AtaCard({required this.ata, this.edital});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSent = ata.status == 'sent';
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
            PcnpInputFormatter.applyMask(ata.codigoAta),
            if (ata.numeroAtaRegistroPreco.isNotEmpty && ata.anoAta != 0)
              'Ata ${ata.numeroAtaRegistroPreco}/${ata.anoAta}',
          ].join(' - '),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (edital != null &&
                edital!.modalidadeLabel.isNotEmpty &&
                edital!.numeroCompra.isNotEmpty &&
                edital!.anoCompra != 0) ...[
              const SizedBox(height: 2),
              Text(
                '${edital!.modalidadeLabel} ${edital!.numeroCompra}/${edital!.anoCompra} - ${PcnpInputFormatter.applyMask(edital!.idContratacaoPNCP)}',
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
            if (edital?.objetoCompra.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(
                edital!.objetoCompra,
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
                  fmt.format(ata.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ata.retificacao)
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
              onPressed: () => context.go('/ata/${ata.id}'),
            ),
          ],
        ),
        onTap: () => context.go('/ata/${ata.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Ata'),
        content: Text(
            'Deseja excluir a ata "${ata.codigoAta}"? Esta ação não pode ser desfeita.'),
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
      await ref.read(atasDaoProvider).deleteById(ata.id);
      ref.invalidate(atasDraftProvider);
      ref.invalidate(atasEnviadasProvider);
    }
  }
}
