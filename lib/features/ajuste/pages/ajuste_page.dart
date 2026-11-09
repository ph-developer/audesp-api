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
import '../../../shared/widgets/barra_filtros.dart';
import '../../../core/utils/ordenacao_documentos.dart';
import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hover_expand_fab.dart';
import '../../../shared/widgets/ordenacao_selector.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../edital/widgets/filtro_modalidade_dropdown.dart';
import '../../pendencias/widgets/pendencias_modulo_list.dart';
import '../../pncp/pncp_providers.dart';
import '../../pncp/widgets/consultar_pncp_button.dart';
import '../../logs/domain/ultimo_envio.dart';
import '../../logs/envios_providers.dart';
import '../../logs/widgets/filtro_envio_dropdown.dart';
import '../../logs/widgets/ultimo_envio_chip.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../../edital/widgets/unlinked_editais_dialog.dart';
import '../../processo/processo_providers.dart';
import '../ajuste_providers.dart';

class AjustePage extends ConsumerStatefulWidget {
  const AjustePage({super.key});

  @override
  ConsumerState<AjustePage> createState() => _AjustePageState();
}

class _AjustePageState extends ConsumerState<AjustePage> {
  String _statusFilter = 'pendencias';
  FiltroEnvio _filtroEnvio = FiltroEnvio.todos;
  int? _modalidadeId;
  OrdenarPor _ordenarPor = OrdenarPor.data;
  bool _decrescente = true;
  bool _mostrarDispensados = false;
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
        title: Row(
          children: [
            Text('Ajustes (Contratos)'),
            const SizedBox(width: 16),
            Expanded(
              child: BarraFiltros(
                children: [
                  AudespSegmentedButton<String>(
                    width: 400,
                    segments: const {
                      'pendencias': 'Pendências',
                      'draft': 'Rascunhos',
                      'sent': 'Enviados',
                    },
                    icons: const {
                      'pendencias': Icons.pending_actions,
                      'draft': Icons.edit_note,
                      'sent': Icons.check_circle_outline,
                    },
                    selected: {_statusFilter},
                    onSelectionChanged: (v) {
                      setState(() => _statusFilter = v.first);
                    },
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
                  if (_statusFilter != 'pendencias')
                    FiltroModalidadeDropdown(
                      value: _modalidadeId,
                      onChanged: (v) => setState(() => _modalidadeId = v),
                    ),
                  if (_statusFilter != 'pendencias')
                    FiltroEnvioDropdown(
                      value: _filtroEnvio,
                      onChanged: (v) => setState(() => _filtroEnvio = v),
                    ),
                  if (_statusFilter != 'pendencias')
                    OrdenacaoSelector(
                      value: _ordenarPor,
                      decrescente: _decrescente,
                      onChanged: (v) => setState(() => _ordenarPor = v),
                      onSentidoChanged: (v) => setState(() => _decrescente = v),
                    ),
                  if (_statusFilter == 'pendencias')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _mostrarDispensados,
                          onChanged: (v) =>
                              setState(() => _mostrarDispensados = v),
                        ),
                        const Text('Mostrar dispensados'),
                      ],
                    ),
                  const ConsultarPncpButton(modulo: '/ajuste'),
                  AudespIconButton(
                    icon: Icons.refresh,
                    tooltip: 'Atualizar',
                    onPressed: () {
                      ref.invalidate(ajustesDraftProvider);
                      ref.invalidate(ajustesEnviadosProvider);
                      ref.invalidate(enviosProvider(EnviosEndpoint.ajuste));
                      ref.invalidate(documentosProcessoProvider);
                      ref.invalidate(pncpContratosProvider);
                      ref.invalidate(
                        unlinkedEditaisProvider(UnlinkedEditaisTarget.ajuste),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [SizedBox(width: 8)],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          HoverExpandFab(
            heroTag: 'criarPorEdital',
            onPressed: () => _openUnlinkedEditaisDialog(context, ref),
            icon: Icons.playlist_add,
            tooltip: 'Criar por Licitação',
          ),
          const SizedBox(height: 12),
          HoverExpandFab(
            heroTag: 'novoAjuste',
            onPressed: () => context.go('/ajuste/new'),
            icon: Icons.add,
            tooltip: 'Novo Ajuste',
          ),
        ],
      ),
      body: _statusFilter == 'pendencias'
          ? PendenciasModuloList(
              modulo: '/ajuste',
              search: _searchCtrl.text,
              mostrarDispensadas: _mostrarDispensados,
            )
          : _AjusteList(
              status: _statusFilter,
              search: _searchCtrl.text,
              filtroEnvio: _filtroEnvio,
              modalidadeId: _modalidadeId,
              ordenarPor: _ordenarPor,
              decrescente: _decrescente,
            ),
    );
  }
}

class _AjusteList extends ConsumerWidget {
  final String status;
  final String search;
  final FiltroEnvio filtroEnvio;
  final int? modalidadeId;
  final OrdenarPor ordenarPor;
  final bool decrescente;
  const _AjusteList({
    required this.status,
    this.search = '',
    this.filtroEnvio = FiltroEnvio.todos,
    this.modalidadeId,
    this.ordenarPor = OrdenarPor.data,
    this.decrescente = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(ajustesDraftProvider)
        : ref.watch(ajustesEnviadosProvider);

    final editaisAsync = ref.watch(_editaisMapProvider);
    final atasAsync = ref.watch(_atasMapProvider);
    final enviosAsync = ref.watch(enviosProvider(EnviosEndpoint.ajuste));
    final envios = enviosAsync.value ?? EnviosIndex.vazio;
    EnvioResumo? envioDe(Ajuste ajuste) => envios.ultimo(
      DescritorEnvio.ajuste(
        municipio: ajuste.municipio,
        entidade: ajuste.entidade,
        codigoEdital: ajuste.codigoEdital,
        codigoAta: ajuste.codigoAta,
        codigoContrato: ajuste.codigoContrato,
        retificacao: ajuste.retificacao,
      ),
    );

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (ajustes) {
        if (filtroEnvio != FiltroEnvio.todos && !enviosAsync.hasValue) {
          return enviosAsync.hasError
              ? Center(child: Text('Erro: ${enviosAsync.error}'))
              : const Center(child: CircularProgressIndicator());
        }
        if (modalidadeId != null && !editaisAsync.hasValue) {
          return editaisAsync.hasError
              ? Center(child: Text('Erro: ${editaisAsync.error}'))
              : const Center(child: CircularProgressIndicator());
        }
        final buscados = search.isEmpty
            ? ajustes
            : ajustes.where((a) {
                final edital = a.editalId == null
                    ? null
                    : editaisAsync.value?[a.editalId];
                final atasMap = atasAsync.value;
                final ata = atasMap != null && a.ataId != null
                    ? atasMap[a.ataId]
                    : null;
                final searchable = [
                  a.codigoContrato,
                  a.codigoEdital,
                  if (a.editalId == null)
                    'Adesão — ${PcnpInputFormatter.applyMask(a.codigoEdital)}',
                  a.codigoAta ?? '',
                  edital?.idContratacaoPNCP ?? '',
                  edital?.objetoCompra ?? '',
                  edital?.modalidadeLabel ?? '',
                  ata?.codigoAta ?? '',
                ].join(' ');
                return matchesLikeSearch(searchable, search);
              }).toList();
        final filtered = buscados
            .where(
              (x) =>
                  filtroEnvio.aceita(envioDe(x)) &&
                  (modalidadeId == null ||
                      (x.editalId == null
                              ? null
                              : editaisAsync
                                    .value?[x.editalId]
                                    ?.modalidadeId) ==
                          modalidadeId),
            )
            .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: status == 'draft'
                ? Icons.article_outlined
                : Icons.check_circle_outline,
            message: search.isNotEmpty
                ? 'Nenhum resultado para "$search"'
                : filtroEnvio != FiltroEnvio.todos || modalidadeId != null
                ? 'Nenhum resultado para os filtros selecionados'
                : status == 'draft'
                ? 'Nenhum rascunho de ajuste'
                : 'Nenhum ajuste enviado',
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
                final ordenados = ordenarDocumentos(
                  filtered,
                  por: ordenarPor,
                  decrescente: decrescente,
                  chave: (x) {
                    final edital = x.editalId == null
                        ? null
                        : editaisMap[x.editalId];
                    return ChaveOrdenacao(
                      data: x.updatedAt,
                      codigo: x.codigoContrato,
                      modalidade: edital?.modalidadeLabel ?? '',
                      numero: edital?.numeroCompra ?? '',
                      ano: edital?.anoCompra ?? 0,
                    );
                  },
                );
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: ordenados.length,
                  itemBuilder: (context, i) {
                    final ajuste = ordenados[i];
                    final edital = ajuste.editalId != null
                        ? editaisMap[ajuste.editalId]
                        : null;
                    final ata = ajuste.ataId != null
                        ? atasMap[ajuste.ataId]
                        : null;
                    final isSent = ajuste.status == 'sent';
                    final colorScheme = Theme.of(context).colorScheme;
                    final fmt = DateFormat('dd/MM/yyyy HH:mm');
                    final ultimoEnvio = envioDe(ajuste);

                    return DocumentCard(
                      icon: isSent ? Icons.check : Icons.edit_outlined,
                      iconBackgroundColor: isSent
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      iconColor: isSent
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      title: tituloAjuste(ajuste),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final parts = <String>[
                                if (ajuste.editalId == null)
                                  'Adesão — ${PcnpInputFormatter.applyMask(ajuste.codigoEdital)}',
                                if (edital != null &&
                                    edital.modalidadeLabel.isNotEmpty &&
                                    edital.numeroCompra.isNotEmpty &&
                                    edital.anoCompra != 0)
                                  '${edital.modalidadeLabel} ${edital.numeroCompra}/${edital.anoCompra} - ${PcnpInputFormatter.applyMask(edital.idContratacaoPNCP)}',
                                if (ajuste.codigoAta != null &&
                                    ata != null &&
                                    ata.numeroAtaRegistroPreco.isNotEmpty &&
                                    ata.anoAta != 0)
                                  'Ata ${ata.numeroAtaRegistroPreco}/${ata.anoAta} - ${PcnpInputFormatter.applyMask(ajuste.codigoAta!)}',
                              ];
                              if (parts.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  parts.join(' | '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface.withAlpha(
                                          140,
                                        ),
                                      ),
                                ),
                              );
                            },
                          ),
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
                                fmt.format(ajuste.updatedAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      chips: [
                        if (ajuste.retificacao) StatusChip.retificacao(),
                        if (ultimoEnvio != null) UltimoEnvioChip(ultimoEnvio),
                      ],
                      onDelete: isSent
                          ? null
                          : () => _confirmDelete(context, ref, ajuste),
                      onNavigate: () => context.go('/ajuste/${ajuste.id}'),
                      onTap: () => context.go('/ajuste/${ajuste.id}'),
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

Future<void> _openUnlinkedEditaisDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final edital = await showUnlinkedEditaisDialog(
    context: context,
    target: UnlinkedEditaisTarget.ajuste,
    title: 'Licitações sem ajuste',
    emptyMessage:
        'Nenhuma licitação enviada de edital sem SRP aguardando ajuste.',
  );
  if (edital == null || !context.mounted) return;
  context.go('/ajuste/new?editalId=${edital.id}');
}

final _editaisMapProvider = FutureProvider<Map<int, Edital>>((ref) async {
  final editais = await ref.watch(editaisDaoProvider).watchAll();
  return {for (final e in editais) e.id: e};
});

final _atasMapProvider = FutureProvider<Map<int, Ata>>((ref) async {
  final atas = await ref.watch(atasDaoProvider).watchAll();
  return {for (final a in atas) a.id: a};
});

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Ajuste ajuste,
) async {
  final confirmed = await showAudespDeleteDialog(
    context: context,
    title: 'Excluir Ajuste',
    entityName: ajuste.codigoContrato,
    entityLabel: 'o ajuste',
  );
  if (confirmed == true) {
    try {
      await ref.read(ajustesDaoProvider).deleteById(ajuste.id);
      ref.invalidate(documentosProcessoProvider);
      ref.invalidate(ajustesDraftProvider);
      ref.invalidate(ajustesEnviadosProvider);
    } catch (e) {
      if (!context.mounted) return;
      AudespSnackBar.error(context, 'Erro ao excluir: $e');
    }
  }
}
