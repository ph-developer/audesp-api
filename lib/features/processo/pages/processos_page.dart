import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/edital.dart';
import '../../../core/database/models/pncp_compra.dart';
import '../../../core/database/models/user.dart';
import '../../../core/navigation/app_modules.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_segmented_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/auth_providers.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../../pncp/domain/pncp_pendencias.dart';
import '../../pncp/pncp_providers.dart';
import '../../pncp/widgets/pncp_compra_card.dart';
import '../domain/processo.dart';
import '../domain/processo_etapas.dart';
import '../domain/processo_rules.dart';
import '../domain/ufesp_rules.dart';
import '../processo_providers.dart';
import '../widgets/ufesp_indicador.dart';

class ProcessosPage extends ConsumerStatefulWidget {
  const ProcessosPage({super.key});

  @override
  ConsumerState<ProcessosPage> createState() => _ProcessosPageState();
}

class _ProcessosPageState extends ConsumerState<ProcessosPage> {
  final _searchCtrl = TextEditingController();
  bool _minhasPendencias = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _consultarPncp() async {
    try {
      final novas = await ref.read(pncpConsultaProvider.notifier).consultar();
      if (!mounted || novas == null) return;
      AudespSnackBar.success(
        context,
        novas == 0
            ? 'Consulta ao PNCP concluída. Nenhuma compra nova.'
            : 'Consulta ao PNCP concluída. $novas compra(s) nova(s).',
      );
    } catch (e) {
      if (mounted) AudespSnackBar.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(localSessionProvider);
    if (user == null) return const SizedBox.shrink();

    final processosAsync = ref.watch(processosProvider);
    final pendencias = ProcessoRules.pendenciasPara(
      user,
      processosAsync.value ?? const [],
    );
    final editaisComPendencia = {
      for (final pendencia in pendencias) pendencia.processo.edital.id,
    };
    // Compras do PNCP sem edital só interessam a quem pode criar o edital.
    final podeEdital = canAccessLocation(user, '/edital/new');
    final ufesp = ref.watch(ufespConfigProvider).value ?? const UfespConfig();
    final pncpConfig = ref.watch(pncpConfigProvider).value;
    final consultaPncp = ref.watch(pncpConsultaProvider);
    final pncpOculto = ref.watch(pncpSecaoOcultaProvider);
    final comprasPncp = podeEdital
        ? ref.watch(pncpComprasProvider).value ?? const <PncpCompra>[]
        : const <PncpCompra>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: AudespSegmentedButton<bool>(
              segments: {true: 'Pendências', false: 'Todos'},
              icons: const {true: Icons.pending_actions, false: Icons.list_alt},
              selected: {_minhasPendencias},
              onSelectionChanged: (v) {
                setState(() => _minhasPendencias = v.first);
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
                      icon: Icons.close,
                      tooltip: 'Limpar filtro',
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (podeEdital && pncpConfig?.configurado == true)
            consultaPncp.executando
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : consultaPncp.erro != null
                ? AudespIconButton(
                    icon: Icons.sync_problem,
                    color: Theme.of(context).colorScheme.error,
                    tooltip:
                        'A última consulta ao PNCP falhou: ${consultaPncp.erro}\n'
                        'Clique para tentar de novo.',
                    onPressed: _consultarPncp,
                  )
                : AudespIconButton(
                    icon: Icons.travel_explore,
                    tooltip: pncpConfig!.ultimaConsultaEm == null
                        ? 'Consultar PNCP'
                        : 'Consultar PNCP (última consulta: '
                              '${DateFormat('dd/MM/yyyy HH:mm').format(pncpConfig.ultimaConsultaEm!)})',
                    onPressed: _consultarPncp,
                  ),
          AudespIconButton(
            icon: Icons.refresh,
            tooltip: 'Atualizar',
            onPressed: () {
              ref.invalidate(processosProvider);
              ref.invalidate(pncpComprasProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: processosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erro: $error')),
              data: (processos) {
                final editais = processos.map((p) => p.edital).toList();
                bool buscaCompra(PncpCompra compra) => matchesLikeSearch(
                  [
                    tituloPncpCompra(compra),
                    compra.numeroControle,
                    compra.objeto,
                  ].join(' '),
                  _searchCtrl.text,
                );
                final pncpPendentes = PncpPendencias.semEdital(
                  comprasPncp,
                  editais,
                ).where(buscaCompra).toList();
                final pncpDispensadas = _minhasPendencias
                    ? const <PncpCompra>[]
                    : PncpPendencias.dispensadas(
                        comprasPncp,
                        editais,
                      ).where(buscaCompra).toList();
                final filtered = processos.where((processo) {
                  return (!_minhasPendencias ||
                          editaisComPendencia.contains(processo.edital.id)) &&
                      matchesLikeSearch(
                        _searchableEditalText(processo.edital),
                        _searchCtrl.text,
                      );
                }).toList();

                if (filtered.isEmpty &&
                    pncpPendentes.isEmpty &&
                    pncpDispensadas.isEmpty) {
                  return _minhasPendencias
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EmptyState(
                                icon: Icons.task_alt,
                                message: 'Nenhuma pendência para você.',
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Selecione "Todos" para ver todos os processos.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : const EmptyState(
                          icon: Icons.account_tree_outlined,
                          message: 'Nenhum processo encontrado.',
                        );
                }

                final itens = <Widget>[
                  if (pncpPendentes.isNotEmpty) ...[
                    _TituloGrupo(
                      icon: Icons.travel_explore,
                      texto:
                          'No PNCP, sem edital no sistema (${pncpPendentes.length})',
                      expandido: !pncpOculto,
                      onToggle: () =>
                          ref.read(pncpSecaoOcultaProvider.notifier).alternar(),
                    ),
                    if (!pncpOculto)
                      for (final compra in pncpPendentes)
                        PncpCompraCard(compra: compra, ufesp: ufesp),
                  ],
                  if (pncpDispensadas.isNotEmpty)
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.block),
                      title: Text(
                        'Compras do PNCP dispensadas (${pncpDispensadas.length})',
                      ),
                      children: [
                        for (final compra in pncpDispensadas)
                          PncpCompraCard(compra: compra, ufesp: ufesp),
                      ],
                    ),
                  if (filtered.isNotEmpty &&
                      (pncpPendentes.isNotEmpty || pncpDispensadas.isNotEmpty))
                    const _TituloGrupo(
                      icon: Icons.account_tree_outlined,
                      texto: 'Processos',
                    ),
                  for (final processo in filtered)
                    _ProcessoCard(processo: processo, user: user, ufesp: ufesp),
                ];

                // Os cards já trazem o espaçamento inferior.
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: itens.length,
                  itemBuilder: (context, index) => itens[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  final IconData icon;
  final String texto;

  /// Com [onToggle], o título vira um botão para ocultar ou mostrar o grupo.
  final bool expandido;
  final VoidCallback? onToggle;

  const _TituloGrupo({
    required this.icon,
    required this.texto,
    this.expandido = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final conteudo = Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            texto,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
          if (onToggle != null) ...[
            const SizedBox(width: 4),
            Icon(
              expandido ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: color,
            ),
          ],
        ],
      ),
    );
    if (onToggle == null) return conteudo;
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: expandido ? 'Ocultar' : 'Mostrar',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onToggle,
          child: conteudo,
        ),
      ),
    );
  }
}

class _ProcessoCard extends StatelessWidget {
  final Processo processo;
  final User user;
  final UfespConfig ufesp;

  const _ProcessoCard({
    required this.processo,
    required this.user,
    required this.ufesp,
  });

  @override
  Widget build(BuildContext context) {
    final edital = processo.edital;
    final estimativa = processo.estimativa;
    final etapas = ProcessoEtapas.de(processo, user);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DocumentCard(
      icon: Icons.account_tree_outlined,
      iconBackgroundColor: colors.surfaceContainerHighest,
      iconColor: colors.onSurfaceVariant,
      title: _tituloEdital(edital),
      chips: [
        UfespIndicador(valorEstimado: edital.valorTotalEstimado, config: ufesp),
      ],
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (edital.objetoCompra.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              edital.objetoCompra,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withAlpha(140),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (estimativa != null) ...[
                  ActionChip(
                    key: ValueKey('processo-${edital.id}-estimativa'),
                    avatar: const Icon(Icons.calculate_outlined, size: 16),
                    label: Text(
                      'Estimativa ${estimativa.numero}/${estimativa.ano}',
                    ),
                    labelStyle: theme.textTheme.labelLarge,
                    shape: const StadiumBorder(),
                    visualDensity: const VisualDensity(
                      horizontal: -2,
                      vertical: -4,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed:
                        canAccessLocation(user, '/estimativa/${estimativa.id}')
                        ? () => context.go('/estimativa/${estimativa.id}')
                        : null,
                  ),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
                for (var i = 0; i < etapas.length; i++) ...[
                  if (i > 0)
                    Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                  _EtapaChip(
                    key: ValueKey(
                      'processo-${edital.id}-etapa-${etapas[i].tipo.name}',
                    ),
                    etapa: etapas[i],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EtapaChip extends StatelessWidget {
  final EtapaProcesso etapa;

  const _EtapaChip({super.key, required this.etapa});

  @override
  Widget build(BuildContext context) {
    final module = kAppModules.firstWhere(
      (module) => module.route == '/${etapa.tipo.name}',
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = switch (etapa.situacao) {
      SituacaoEtapa.enviada => colors.primary,
      SituacaoEtapa.rascunho => colors.tertiary,
      SituacaoEtapa.aCriar => colors.secondary,
      SituacaoEtapa.bloqueada => colors.onSurfaceVariant,
    };
    final situacao = switch (etapa.situacao) {
      SituacaoEtapa.enviada => 'Enviado',
      SituacaoEtapa.rascunho => 'Rascunho',
      SituacaoEtapa.aCriar => 'A criar',
      SituacaoEtapa.bloqueada => 'Bloqueado',
    };
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: ShapeDecoration(
        color: color.withAlpha(20),
        shape: StadiumBorder(
          side: BorderSide(
            color: etapa.situacao == SituacaoEtapa.bloqueada
                ? colors.outline
                : color.withAlpha(100),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(module.icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            module.label,
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          Text(
            etapa.quantidade > 1 ? '$situacao · ${etapa.quantidade}' : situacao,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withAlpha(200),
            ),
          ),
        ],
      ),
    );

    if (etapa.acoes.isEmpty) {
      final chip = MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: content,
      );
      return etapa.motivoBloqueio == null
          ? chip
          : Tooltip(message: etapa.motivoBloqueio!, child: chip);
    }
    final clicavel = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: content,
    );
    if (etapa.acoes.length == 1) {
      final acao = etapa.acoes.single;
      return Tooltip(
        message: acao.label,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.go(acao.route),
          child: clicavel,
        ),
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Ações de ${module.label}',
      onSelected: (route) => context.go(route),
      itemBuilder: (context) => [
        for (final acao in etapa.acoes)
          PopupMenuItem(value: acao.route, child: Text(acao.label)),
      ],
      child: clicavel,
    );
  }
}

String _codigoEdital(Edital edital) => edital.semPncp
    ? edital.codigoEdital
    : PcnpInputFormatter.applyMask(edital.idContratacaoPNCP);

String _tituloEdital(Edital edital) => [
  _codigoEdital(edital),
  [
    if (edital.modalidadeLabel.isNotEmpty) edital.modalidadeLabel,
    if (edital.numeroCompra.isNotEmpty && edital.anoCompra != 0)
      '${edital.numeroCompra}/${edital.anoCompra}',
  ].where((part) => part.isNotEmpty).join(' '),
].where((part) => part.isNotEmpty).join(' - ');

String _searchableEditalText(Edital edital) => [
  _tituloEdital(edital),
  edital.modalidadeLabel,
  edital.numeroCompra,
  edital.anoCompra == 0 ? '' : '${edital.anoCompra}',
  edital.codigoEdital,
  edital.idContratacaoPNCP,
  edital.dropdownLabel,
  edital.objetoCompra,
].join(' ');
