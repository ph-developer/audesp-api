import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../ajuste_providers.dart';

class AjustePage extends ConsumerWidget {
  const AjustePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajustes (Contratos)'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rascunhos'),
              Tab(text: 'Enviados'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/ajuste/new'),
          icon: const Icon(Icons.add),
          label: const Text('Novo Ajuste'),
        ),
        body: const TabBarView(
          children: [
            _AjusteList(status: 'draft'),
            _AjusteList(status: 'sent'),
          ],
        ),
      ),
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'draft'
                      ? Icons.article_outlined
                      : Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'draft'
                      ? 'Nenhum rascunho de ajuste'
                      : 'Nenhum ajuste enviado',
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
            return atasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (atasMap) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: ajustes.length,
                  itemBuilder: (context, i) {
                    final ajuste = ajustes[i];
                    return _AjusteCard(
                      ajuste: ajuste,
                      edital: editaisMap[ajuste.editalId],
                      ata: ajuste.ataId != null ? atasMap[ajuste.ataId] : null,
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

class _AjusteCard extends ConsumerWidget {
  final Ajuste ajuste;
  final Edital? edital;
  final Ata? ata;
  const _AjusteCard({required this.ajuste, this.edital, this.ata});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSent = ajuste.status == 'sent';
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
            PcnpInputFormatter.applyMask(ajuste.codigoContrato),
            if (ajuste.numeroContratoEmpenho.isNotEmpty && ajuste.anoContrato != 0)
              'Ajuste ${ajuste.numeroContratoEmpenho}/${ajuste.anoContrato}',
          ].join(' - '),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(builder: (context) {
              final parts = <String>[
                if (edital != null &&
                    edital!.modalidadeLabel.isNotEmpty &&
                    edital!.numeroCompra.isNotEmpty &&
                    edital!.anoCompra != 0)
                  '${edital!.modalidadeLabel} ${edital!.numeroCompra}/${edital!.anoCompra} - ${PcnpInputFormatter.applyMask(edital!.idContratacaoPNCP)}',
                if (ajuste.codigoAta != null &&
                    ata != null &&
                    ata!.numeroAtaRegistroPreco.isNotEmpty &&
                    ata!.anoAta != 0)
                  'Ata ${ata!.numeroAtaRegistroPreco}/${ata!.anoAta} - ${PcnpInputFormatter.applyMask(ajuste.codigoAta!)}',
              ];
              if (parts.isEmpty) return const SizedBox.shrink();
              return Text(
                parts.join(' | '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }),
            if (edital?.objetoCompra.isNotEmpty == true)
              Text(
                edital!.objetoCompra,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'Atualizado em ${fmt.format(ajuste.updatedAt)}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ajuste.retificacao)
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
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir',
                onPressed: () => _confirmDelete(context, ref),
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'Abrir',
              onPressed: () => context.go('/ajuste/${ajuste.id}'),
            ),
          ],
        ),
        onTap: () => context.go('/ajuste/${ajuste.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Ajuste'),
        content: Text(
            'Deseja excluir o ajuste "${ajuste.codigoContrato}"? Esta ação não pode ser desfeita.'),
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
      await ref.read(ajustesDaoProvider).deleteById(ajuste.id);
      ref.invalidate(ajustesDraftProvider);
      ref.invalidate(ajustesEnviadosProvider);
    }
  }
}
