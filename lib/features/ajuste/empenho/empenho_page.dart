import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import 'empenho_providers.dart';

/// Lista de empenhos de contrato de um ajuste.
class EmpenhoPage extends ConsumerWidget {
  final int ajusteId;
  const EmpenhoPage({super.key, required this.ajusteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(empenhosByAjusteProvider(ajusteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empenhos de Contrato'),
        leading: BackButton(
          onPressed: () => context.go('/ajuste/$ajusteId'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/ajuste/$ajusteId/empenho/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Empenho'),
      ),
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (empenhos) {
          if (empenhos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('Nenhum empenho cadastrado para este ajuste.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: empenhos.length,
            itemBuilder: (context, i) =>
                _EmpenhoCard(empenho: empenhos[i], ajusteId: ajusteId),
          );
        },
      ),
    );
  }
}

class _EmpenhoCard extends ConsumerWidget {
  final Empenho empenho;
  final int ajusteId;
  const _EmpenhoCard({required this.empenho, required this.ajusteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSent = empenho.status == 'sent';
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
            isSent ? Icons.check : Icons.receipt_long_outlined,
            color: isSent
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Empenho: ${empenho.numeroEmpenho}/${empenho.anoEmpenho}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contrato: ${empenho.codigoContrato}'),
            Text(
              'Cadastrado: ${fmt.format(empenho.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (empenho.retificacao)
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
              onPressed: () =>
                  context.go('/ajuste/$ajusteId/empenho/${empenho.id}'),
            ),
          ],
        ),
        onTap: () =>
            context.go('/ajuste/$ajusteId/empenho/${empenho.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Empenho'),
        content: Text(
            'Deseja excluir o empenho "${empenho.numeroEmpenho}/${empenho.anoEmpenho}"? Esta ação não pode ser desfeita.'),
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
      await ref.read(empenhosDaoProvider).deleteById(empenho.id);
    }
  }
}
