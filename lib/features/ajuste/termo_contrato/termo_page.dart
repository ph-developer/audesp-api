import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import 'termo_providers.dart';

/// Lista de termos de contrato de um ajuste.
class TermoPage extends ConsumerWidget {
  final int ajusteId;
  const TermoPage({super.key, required this.ajusteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(termosByAjusteProvider(ajusteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos Aditivos de Contrato'),
        leading: BackButton(
          onPressed: () => context.go('/ajuste/$ajusteId'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ajuste/$ajusteId/termo/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Termo'),
      ),
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (termos) {
          if (termos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Nenhum termo aditivo cadastrado para este ajuste.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: termos.length,
            itemBuilder: (context, i) =>
                _TermoCard(termo: termos[i], ajusteId: ajusteId),
          );
        },
      ),
    );
  }
}

class _TermoCard extends ConsumerWidget {
  final TermosContratoData termo;
  final int ajusteId;
  const _TermoCard({required this.termo, required this.ajusteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSent = termo.status == 'sent';
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
            isSent ? Icons.check : Icons.description_outlined,
            color: isSent
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Termo: ${termo.codigoTermoContrato}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contrato: ${termo.codigoContrato}'),
            Text(
              'Cadastrado: ${fmt.format(termo.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (termo.retificacao)
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
                  context.go('/ajuste/$ajusteId/termo/${termo.id}'),
            ),
          ],
        ),
        onTap: () => context.go('/ajuste/$ajusteId/termo/${termo.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Termo de Contrato'),
        content: Text(
            'Deseja excluir o termo "${termo.codigoTermoContrato}"? Esta ação não pode ser desfeita.'),
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
      await ref.read(termosContratoDaoProvider).deleteById(termo.id);
    }
  }
}
