import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hover_expand_fab.dart';
import '../estimativa_providers.dart';
import '../models/estimativa_model.dart';

class EstimativasListPage extends ConsumerStatefulWidget {
  const EstimativasListPage({super.key});

  @override
  ConsumerState<EstimativasListPage> createState() =>
      _EstimativasListPageState();
}

class _EstimativasListPageState extends ConsumerState<EstimativasListPage> {
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
        title: const Text('Estimativas'),
        actions: [
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
              ref.invalidate(estimativasListProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: HoverExpandFab(
        heroTag: 'novaEstimativa',
        onPressed: () => context.go('/estimativa/new'),
        icon: Icons.add,
        tooltip: 'Nova Estimativa',
      ),
      body: _EstimativaList(search: _searchCtrl.text),
    );
  }
}

class _EstimativaList extends ConsumerWidget {
  final String search;
  const _EstimativaList({this.search = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(estimativasListProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (estimativas) {
        final filtered = search.isEmpty
            ? estimativas
            : estimativas.where((e) {
                final searchable = [
                  'Estimativa ${e.numero}/${e.ano}',
                  e.objeto,
                ].join(' ');
                return matchesLikeSearch(searchable, search);
              }).toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.calculate_outlined,
            message: search.isNotEmpty
                ? 'Nenhum resultado para "$search"'
                : 'Nenhuma estimativa cadastrada',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final estimativa = filtered[i];
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
