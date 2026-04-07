import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
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
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: ajustes.length,
          itemBuilder: (context, i) => _AjusteCard(ajuste: ajustes[i]),
        );
      },
    );
  }
}

class _AjusteCard extends ConsumerWidget {
  final Ajuste ajuste;
  const _AjusteCard({required this.ajuste});

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
          'Contrato: ${ajuste.codigoContrato}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edital: ${ajuste.codigoEdital}'),
            if (ajuste.codigoAta != null)
              Text('Ata: ${ajuste.codigoAta}'),
            Text(
              'Município: ${ajuste.municipio}  |  Entidade: ${ajuste.entidade}',
            ),
            Text(
              'Atualizado: ${fmt.format(ajuste.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
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
      builder: (_) => AlertDialog(
        title: const Text('Excluir Ajuste'),
        content: Text(
            'Deseja excluir o ajuste "${ajuste.codigoContrato}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(ajustesDaoProvider).deleteById(ajuste.id);
    }
  }
}

