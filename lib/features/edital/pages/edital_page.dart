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
import '../../../shared/widgets/mostrar_dispensadas_button.dart';
import '../../../shared/widgets/barra_filtros.dart';
import '../../../core/utils/ordenacao_documentos.dart';
import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hover_expand_fab.dart';
import '../../../shared/widgets/ordenacao_selector.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/filtro_modalidade_dropdown.dart';
import '../../pendencias/widgets/pendencias_modulo_list.dart';
import '../../logs/domain/ultimo_envio.dart';
import '../../logs/envios_providers.dart';
import '../../logs/widgets/filtro_envio_dropdown.dart';
import '../../logs/widgets/ultimo_envio_chip.dart';
import '../edital_providers.dart'
    show editaisDraftProvider, editaisEnviadosProvider;
import '../../../core/navigation/app_modules.dart';
import '../../../shared/widgets/ufesp_indicador.dart';
import '../../auth/auth_providers.dart';
import '../../pncp/pncp_providers.dart';
import '../../pncp/widgets/consultar_pncp_button.dart';
import '../../processo/domain/ufesp_rules.dart';
import '../../processo/processo_providers.dart';

class EditalPage extends ConsumerStatefulWidget {
  const EditalPage({super.key});

  @override
  ConsumerState<EditalPage> createState() => _EditalPageState();
}

class _EditalPageState extends ConsumerState<EditalPage> {
  String _statusFilter = 'pendencias';
  bool _mostrarDispensadas = false;
  FiltroEnvio _filtroEnvio = FiltroEnvio.todos;
  int? _modalidadeId;
  OrdenarPor _ordenarPor = OrdenarPor.data;
  bool _decrescente = true;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(localSessionProvider);
    final podeCriar = user != null && canAccessLocation(user, '/edital/new');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Editais'),
            const SizedBox(width: 16),
            Expanded(
              child: BarraFiltros(
                children: [
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
                  if (_statusFilter == 'pendencias' && podeCriar)
                    MostrarDispensadasButton(
                      value: _mostrarDispensadas,
                      onChanged: (v) => setState(() => _mostrarDispensadas = v),
                    ),
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
                  const ConsultarPncpButton(),
                  AudespIconButton(
                    icon: Icons.refresh,
                    tooltip: 'Atualizar',
                    onPressed: () {
                      ref.invalidate(documentosProcessoProvider);
                      ref.invalidate(pncpComprasProvider);
                      ref.invalidate(editaisDraftProvider);
                      ref.invalidate(editaisEnviadosProvider);
                      ref.invalidate(enviosProvider(EnviosEndpoint.edital));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [SizedBox(width: 8)],
      ),
      floatingActionButton: !podeCriar
          ? null
          : HoverExpandFab(
              heroTag: 'novoEdital',
              onPressed: () => context.go('/edital/new'),
              icon: Icons.add,
              tooltip: 'Novo Edital',
            ),
      body: _statusFilter == 'pendencias'
          ? PendenciasModuloList(
              modulo: '/edital',
              search: _searchCtrl.text,
              mostrarDispensadas: _mostrarDispensadas,
            )
          : _EditalList(
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

class _EditalList extends ConsumerWidget {
  final String status;
  final String search;
  final FiltroEnvio filtroEnvio;
  final int? modalidadeId;
  final OrdenarPor ordenarPor;
  final bool decrescente;
  const _EditalList({
    required this.status,
    this.search = '',
    this.filtroEnvio = FiltroEnvio.todos,
    this.modalidadeId,
    this.ordenarPor = OrdenarPor.data,
    this.decrescente = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ufesp = ref.watch(ufespConfigProvider).value ?? const UfespConfig();
    final stream = status == 'draft'
        ? ref.watch(editaisDraftProvider)
        : ref.watch(editaisEnviadosProvider);
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
            .where(
              (x) =>
                  filtroEnvio.aceita(envioDe(x)) &&
                  (modalidadeId == null || (x.modalidadeId) == modalidadeId),
            )
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
                : filtroEnvio != FiltroEnvio.todos || modalidadeId != null
                ? 'Nenhum resultado para os filtros selecionados'
                : switch (status) {
                    'draft' => 'Nenhum rascunho de edital',
                    'oculto' => 'Nenhum edital oculto',
                    _ => 'Nenhum edital enviado',
                  },
          );
        }
        final ordenados = ordenarDocumentos(
          filtered,
          por: ordenarPor,
          decrescente: decrescente,
          chave: (x) => ChaveOrdenacao(
            data: x.updatedAt,
            codigo: x.idContratacaoPNCP,
            modalidade: x.modalidadeLabel,
            numero: x.numeroCompra,
            ano: x.anoCompra,
          ),
        );
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: ordenados.length,
          itemBuilder: (context, i) {
            final edital = ordenados[i];
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
              title: tituloEdital(edital),
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
                UfespIndicador(
                  valorEstimado: edital.valorTotalEstimado,
                  config: ufesp,
                ),
                if (edital.semPncp) StatusChip.semPncp(),
                if (edital.retificacao) StatusChip.retificacao(),
                if (ultimoEnvio != null) UltimoEnvioChip(ultimoEnvio),
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
      ref.invalidate(documentosProcessoProvider);
      ref.invalidate(editaisDraftProvider);
      ref.invalidate(editaisEnviadosProvider);
    } catch (e) {
      if (!context.mounted) return;
      AudespSnackBar.error(context, 'Erro ao excluir: $e');
    }
  }
}
