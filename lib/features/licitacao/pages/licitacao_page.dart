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
import '../licitacao_providers.dart';

class LicitacaoPage extends ConsumerStatefulWidget {
  const LicitacaoPage({super.key});

  @override
  ConsumerState<LicitacaoPage> createState() => _LicitacaoPageState();
}

class _LicitacaoPageState extends ConsumerState<LicitacaoPage> {
  String _statusFilter = 'draft';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licitações'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: SizedBox(
              width: 160,
              child: AudespDropdown<String>.items(
                label: 'Status',
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(
                    value: 'draft',
                    child: Text('Rascunhos', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'sent',
                    child: Text('Enviadas', overflow: TextOverflow.ellipsis),
                  ),
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
              ref.invalidate(licitacoesDraftProvider);
              ref.invalidate(licitacoesEnviadasProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/licitacao/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Licitação'),
      ),
      body: _LicitacaoList(status: _statusFilter),
    );
  }
}

class _LicitacaoList extends ConsumerWidget {
  final String status;
  const _LicitacaoList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(licitacoesDraftProvider)
        : ref.watch(licitacoesEnviadasProvider);

    final editaisAsync = ref.watch(_editaisMapProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (licitacoes) {
        if (licitacoes.isEmpty) {
          return EmptyState(
            icon: status == 'draft'
                ? Icons.article_outlined
                : Icons.check_circle_outline,
            message: status == 'draft'
                ? 'Nenhum rascunho de licitação'
                : 'Nenhuma licitação enviada',
          );
        }
        return editaisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (editaisMap) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: licitacoes.length,
              itemBuilder: (context, i) {
                final licitacao = licitacoes[i];
                final edital = editaisMap[licitacao.editalId];
                final isSent = licitacao.status == 'sent';
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
                    PcnpInputFormatter.applyMask(
                      edital?.idContratacaoPNCP ?? licitacao.codigoEdital,
                    ),
                    if (edital != null &&
                        edital.modalidadeLabel.isNotEmpty &&
                        edital.numeroCompra.isNotEmpty &&
                        edital.anoCompra != 0)
                      '${edital.modalidadeLabel} ${edital.numeroCompra}/${edital.anoCompra}',
                  ].join(' - '),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (edital?.objetoCompra.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          edital!.objetoCompra,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                            fmt.format(licitacao.updatedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  chips: [
                    if (licitacao.retificacao)
                      Chip(
                        label: const Text('Retificação'),
                        backgroundColor: colorScheme.tertiaryContainer,
                        labelStyle: TextStyle(
                          color: colorScheme.onTertiaryContainer,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                  onDelete: isSent
                      ? null
                      : () => _confirmDelete(context, ref, licitacao),
                  onNavigate: () => context.go('/licitacao/${licitacao.id}'),
                  onTap: () => context.go('/licitacao/${licitacao.id}'),
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

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Licitacoe licitacao,
) async {
  final confirmed = await showAudespDeleteDialog(
    context: context,
    title: 'Excluir Licitação',
    entityName: licitacao.codigoEdital,
    entityLabel: 'a licitação do edital',
  );
  if (confirmed == true) {
    try {
      await ref.read(licitacoesDaoProvider).deleteById(licitacao.id);
      ref.invalidate(licitacoesDraftProvider);
      ref.invalidate(licitacoesEnviadasProvider);
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
