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
import '../../logs/domain/ultimo_envio.dart';
import '../../logs/envios_providers.dart';
import '../../logs/widgets/filtro_envio_dropdown.dart';
import '../../logs/widgets/ultimo_envio_chip.dart';
import '../edital_providers.dart'
    show editaisDraftProvider, editaisEnviadosProvider, editaisOcultosProvider;
import '../widgets/edital_ocultacao.dart';
import '../widgets/pcnp_input_formatter.dart';

class EditalPage extends ConsumerStatefulWidget {
  const EditalPage({super.key});

  @override
  ConsumerState<EditalPage> createState() => _EditalPageState();
}

class _EditalPageState extends ConsumerState<EditalPage> {
  String _statusFilter = 'draft';
  FiltroEnvio _filtroEnvio = FiltroEnvio.todos;
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
        title: const Text('Editais'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: AudespSegmentedButton<String>(
              width: 380,
              segments: const {
                'draft': 'Rascunhos',
                'sent': 'Enviados',
                'oculto': 'Ocultos',
              },
              icons: const {
                'draft': Icons.edit_note,
                'sent': Icons.check_circle_outline,
                'oculto': Icons.visibility_off_outlined,
              },
              selected: {_statusFilter},
              onSelectionChanged: (v) {
                setState(() => _statusFilter = v.first);
              },
            ),
          ),
          FiltroEnvioDropdown(
            value: _filtroEnvio,
            onChanged: (v) => setState(() => _filtroEnvio = v),
          ),
          const SizedBox(width: 8),
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
              ref.invalidate(editaisDraftProvider);
              ref.invalidate(editaisEnviadosProvider);
              ref.invalidate(editaisOcultosProvider);
              ref.invalidate(enviosProvider(EnviosEndpoint.edital));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: HoverExpandFab(
        heroTag: 'novoEdital',
        onPressed: () => context.go('/edital/new'),
        icon: Icons.add,
        tooltip: 'Novo Edital',
      ),
      body: _EditalList(
        status: _statusFilter,
        search: _searchCtrl.text,
        filtroEnvio: _filtroEnvio,
      ),
    );
  }
}

class _EditalList extends ConsumerWidget {
  final String status;
  final String search;
  final FiltroEnvio filtroEnvio;
  const _EditalList({
    required this.status,
    this.search = '',
    this.filtroEnvio = FiltroEnvio.todos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = switch (status) {
      'draft' => ref.watch(editaisDraftProvider),
      'oculto' => ref.watch(editaisOcultosProvider),
      _ => ref.watch(editaisEnviadosProvider),
    };
    final enviosAsync = ref.watch(enviosProvider(EnviosEndpoint.edital));
    final envios = enviosAsync.value ?? EnviosIndex.vazio;
    EnvioResumo? envioDe(Edital edital) => envios.ultimo(
      DescritorEnvio.edital(
        municipio: edital.municipio,
        entidade: edital.entidade,
        codigoEdital: edital.codigoEdital,
        retificacao: edital.retificacao,
      ),
    );

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (editais) {
        if (filtroEnvio != FiltroEnvio.todos && !enviosAsync.hasValue) {
          return enviosAsync.hasError
              ? Center(child: Text('Erro: ${enviosAsync.error}'))
              : const Center(child: CircularProgressIndicator());
        }
        final buscados = search.isEmpty
            ? editais
            : editais.where((e) {
                final searchable = [
                  e.codigoEdital,
                  e.idContratacaoPNCP,
                  e.objetoCompra,
                  e.modalidadeLabel,
                ].join(' ');
                return matchesLikeSearch(searchable, search);
              }).toList();
        final filtered = buscados
            .where((x) => filtroEnvio.aceita(envioDe(x)))
            .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: switch (status) {
              'draft' => Icons.article_outlined,
              'oculto' => Icons.visibility_off_outlined,
              _ => Icons.check_circle_outline,
            },
            message: search.isNotEmpty
                ? 'Nenhum resultado para "$search"'
                : filtroEnvio != FiltroEnvio.todos
                ? 'Nenhum resultado com status de envio "${filtroEnvio.rotulo}"'
                : switch (status) {
                    'draft' => 'Nenhum rascunho de edital',
                    'oculto' => 'Nenhum edital oculto',
                    _ => 'Nenhum edital enviado',
                  },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final edital = filtered[i];
            final isSent = edital.status == 'sent';
            final colorScheme = Theme.of(context).colorScheme;
            final fmt = DateFormat('dd/MM/yyyy HH:mm');
            final ultimoEnvio = envioDe(edital);

            return DocumentCard(
              icon: isSent ? Icons.check : Icons.edit_outlined,
              iconBackgroundColor: isSent
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              iconColor: isSent
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              title: [
                PcnpInputFormatter.applyMask(edital.idContratacaoPNCP),
                if (edital.modalidadeLabel.isNotEmpty &&
                    edital.numeroCompra.isNotEmpty &&
                    edital.anoCompra != 0)
                  '${edital.modalidadeLabel} ${edital.numeroCompra}/${edital.anoCompra}',
              ].join(' - '),
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
                        color: colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  ],
                  if (edital.oculto) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Oculto em ${DateFormat('dd/MM/yyyy').format(edital.ocultoEm!)}'
                      '${edital.motivoOcultacao == null ? '' : ': ${edital.motivoOcultacao}'}',
                      style: Theme.of(context).textTheme.bodySmall,
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
              chips: [
                if (edital.semPncp) StatusChip.semPncp(),
                if (edital.retificacao) StatusChip.retificacao(),
                if (ultimoEnvio != null) UltimoEnvioChip(ultimoEnvio),
              ],
              actions: [
                if (edital.oculto)
                  TextButton.icon(
                    onPressed: () => reexibirEdital(context, ref, edital),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Reexibir'),
                  ),
              ],
              onDelete: isSent
                  ? null
                  : () => _confirmDelete(context, ref, edital),
              onNavigate: () => context.go('/edital/${edital.id}'),
              onTap: () => context.go('/edital/${edital.id}'),
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
  Edital edital,
) async {
  final confirmed = await showAudespDeleteDialog(
    context: context,
    title: 'Excluir Edital',
    entityName: edital.codigoEdital,
    entityLabel: 'o edital',
  );
  if (confirmed == true) {
    try {
      await ref.read(editaisDaoProvider).deleteById(edital.id);
      ref.invalidate(editaisDraftProvider);
      ref.invalidate(editaisEnviadosProvider);
      ref.invalidate(editaisOcultosProvider);
    } catch (e) {
      if (!context.mounted) return;
      AudespSnackBar.error(context, 'Erro ao excluir: $e');
    }
  }
}
