import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_segmented_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hover_expand_fab.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../../edital/widgets/unlinked_editais_dialog.dart';
import '../ata_providers.dart';

class AtaPage extends ConsumerStatefulWidget {
  const AtaPage({super.key});

  @override
  ConsumerState<AtaPage> createState() => _AtaPageState();
}

class _AtaPageState extends ConsumerState<AtaPage> {
  String _statusFilter = 'draft';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atas de Registro de Preço'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: AudespSegmentedButton<String>(
              width: 260,
              segments: const {'draft': 'Rascunhos', 'sent': 'Enviadas'},
              icons: const {
                'draft': Icons.edit_note,
                'sent': Icons.check_circle_outline,
              },
              selected: {_statusFilter},
              onSelectionChanged: (v) {
                setState(() => _statusFilter = v.first);
              },
            ),
          ),
          SizedBox(
            width: 200,
            child: AudespTextField(
              label: 'Filtrar',
              controller: _searchCtrl,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : AudespIconButton(
                      tooltip: 'Limpar filtro',
                      icon: Icons.close,
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          AudespIconButton(
            icon: Icons.refresh,
            tooltip: 'Atualizar',
            onPressed: () {
              ref.invalidate(atasDraftProvider);
              ref.invalidate(atasEnviadasProvider);
              ref.invalidate(
                unlinkedEditaisProvider(UnlinkedEditaisTarget.ata),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          HoverExpandFab(
            heroTag: 'criarPorEdital',
            onPressed: () => _openUnlinkedEditaisDialog(context, ref),
            icon: Icons.playlist_add,
            tooltip: 'Criar por Edital',
          ),
          const SizedBox(height: 12),
          HoverExpandFab(
            heroTag: 'novaAta',
            onPressed: () => context.go('/ata/new'),
            icon: Icons.add,
            tooltip: 'Nova Ata',
          ),
        ],
      ),
      body: _AtaList(status: _statusFilter, search: _searchCtrl.text),
    );
  }
}

class _AtaList extends ConsumerWidget {
  final String status;
  final String search;
  const _AtaList({required this.status, this.search = ''});

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
        final filtered = search.isEmpty
            ? atas
            : atas.where((a) {
                final edital = editaisAsync.value?[a.editalId];
                final searchable = [
                  a.codigoAta,
                  a.codigoEdital,
                  edital?.idContratacaoPNCP ?? '',
                  edital?.objetoCompra ?? '',
                  edital?.modalidadeLabel ?? '',
                ].join(' ');
                return matchesLikeSearch(searchable, search);
              }).toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: status == 'draft'
                ? Icons.article_outlined
                : Icons.check_circle_outline,
            message: search.isNotEmpty
                ? 'Nenhum resultado para "$search"'
                : status == 'draft'
                ? 'Nenhum rascunho de ata'
                : 'Nenhuma ata enviada',
          );
        }
        return editaisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (editaisMap) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final ata = filtered[i];
                final edital = editaisMap[ata.editalId];
                final isSent = ata.status == 'sent';
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
                    PcnpInputFormatter.applyMask(ata.codigoAta),
                    if (ata.numeroAtaRegistroPreco.isNotEmpty &&
                        ata.anoAta != 0)
                      'Ata ${ata.numeroAtaRegistroPreco}/${ata.anoAta}',
                  ].join(' - '),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (edital != null &&
                          edital.modalidadeLabel.isNotEmpty &&
                          edital.numeroCompra.isNotEmpty &&
                          edital.anoCompra != 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${edital.modalidadeLabel} ${edital.numeroCompra}/${edital.anoCompra} - ${PcnpInputFormatter.applyMask(edital.idContratacaoPNCP)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withAlpha(140),
                              ),
                        ),
                      ],
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
                            fmt.format(ata.updatedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  chips: [if (ata.retificacao) StatusChip.retificacao()],
                  onDelete: isSent
                      ? null
                      : () => _confirmDelete(context, ref, ata),
                  onNavigate: () => context.go('/ata/${ata.id}'),
                  onTap: () => context.go('/ata/${ata.id}'),
                );
              },
            );
          },
        );
      },
    );
  }
}

Future<void> _openUnlinkedEditaisDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final edital = await showUnlinkedEditaisDialog(
    context: context,
    target: UnlinkedEditaisTarget.ata,
    title: 'Editais SRP sem ata',
    emptyMessage: 'Nenhum edital SRP enviado sem ata vinculada.',
  );
  if (edital == null || !context.mounted) return;
  context.go('/ata/new?editalId=${edital.id}');
}

final _editaisMapProvider = FutureProvider<Map<int, Edital>>((ref) async {
  final editais = await ref.watch(editaisDaoProvider).watchAll();
  return {for (final e in editais) e.id: e};
});

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Ata ata,
) async {
  final confirmed = await showAudespDeleteDialog(
    context: context,
    title: 'Excluir Ata',
    entityName: ata.codigoAta,
    entityLabel: 'a ata',
  );
  if (confirmed == true) {
    try {
      await ref.read(atasDaoProvider).deleteById(ata.id);
      ref.invalidate(atasDraftProvider);
      ref.invalidate(atasEnviadasProvider);
    } catch (e) {
      if (!context.mounted) return;
      AudespSnackBar.error(context, 'Erro ao excluir: $e');
    }
  }
}
