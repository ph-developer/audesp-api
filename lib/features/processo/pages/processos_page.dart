import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/models/edital.dart';
import '../../../core/database/models/user.dart';
import '../../../core/navigation/app_modules.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/auth_providers.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../domain/processo.dart';
import '../domain/processo_etapas.dart';
import '../domain/processo_rules.dart';
import '../processo_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(localSessionProvider);
    if (user == null) return const SizedBox.shrink();

    final processosAsync = ref.watch(processosProvider);
    final pendencias = ProcessoRules.pendenciasPara(
      user,
      processosAsync.value ?? const [],
    );
    final pendenciasPorEdital = <int, List<Pendencia>>{};
    for (final pendencia in pendencias) {
      (pendenciasPorEdital[pendencia.processo.edital.id] ??= []).add(pendencia);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processos'),
        actions: [
          AudespIconButton(
            icon: Icons.refresh,
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(processosProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 360,
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
                FilterChip(
                  label: Text('Minhas pendências (${pendencias.length})'),
                  selected: _minhasPendencias,
                  onSelected: (value) =>
                      setState(() => _minhasPendencias = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: processosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erro: $error')),
              data: (processos) {
                final filtered = processos.where((processo) {
                  return (!_minhasPendencias ||
                          pendenciasPorEdital.containsKey(
                            processo.edital.id,
                          )) &&
                      matchesLikeSearch(
                        _searchableEditalText(processo.edital),
                        _searchCtrl.text,
                      );
                }).toList();

                if (filtered.isEmpty) {
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
                                'Desligue "Minhas pendências" para ver todos os processos.',
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final processo = filtered[index];
                    return _ProcessoCard(
                      processo: processo,
                      user: user,
                      pendencias: pendenciasPorEdital[processo.edital.id] ?? [],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessoCard extends StatelessWidget {
  final Processo processo;
  final User user;
  final List<Pendencia> pendencias;

  const _ProcessoCard({
    required this.processo,
    required this.user,
    required this.pendencias,
  });

  @override
  Widget build(BuildContext context) {
    final edital = processo.edital;
    final estimativa = processo.estimativa;
    final etapas = ProcessoEtapas.de(processo, user);
    final theme = Theme.of(context);

    return SectionCard(
      title: _tituloEdital(edital),
      titleWidget: Text(
        _tituloEdital(edital),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      children: [
        if (edital.objetoCompra.isNotEmpty) ...[
          Text(
            edital.objetoCompra,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (estimativa != null) ...[
                ActionChip(
                  key: ValueKey('processo-${edital.id}-estimativa'),
                  avatar: const Icon(Icons.calculate_outlined, size: 18),
                  label: Text(
                    'Estimativa ${estimativa.numero}/${estimativa.ano}',
                  ),
                  onPressed:
                      canAccessLocation(user, '/estimativa/${estimativa.id}')
                      ? () => context.go('/estimativa/${estimativa.id}')
                      : null,
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
              for (var i = 0; i < etapas.length; i++) ...[
                if (i > 0)
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
        if (pendencias.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final pendencia in pendencias)
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(descricaoPendencia(pendencia)),
                  onPressed: () => context.go(rotaPendencia(pendencia)),
                ),
            ],
          ),
        ],
      ],
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
      SituacaoEtapa.bloqueada ||
      SituacaoEtapa.naoSeAplica => colors.onSurfaceVariant,
    };
    final situacao = switch (etapa.situacao) {
      SituacaoEtapa.enviada => 'Enviado',
      SituacaoEtapa.rascunho => 'Rascunho',
      SituacaoEtapa.aCriar => 'A criar',
      SituacaoEtapa.bloqueada => 'Bloqueado',
      SituacaoEtapa.naoSeAplica => '—',
    };
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: color.withAlpha(20),
        shape: StadiumBorder(
          side: BorderSide(
            color:
                etapa.situacao == SituacaoEtapa.bloqueada ||
                    etapa.situacao == SituacaoEtapa.naoSeAplica
                ? colors.outline
                : color.withAlpha(100),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(module.icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.label,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
              Text(
                etapa.quantidade > 1
                    ? '$situacao · ${etapa.quantidade}'
                    : situacao,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
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
    if (etapa.acoes.length == 1) {
      final acao = etapa.acoes.single;
      return Tooltip(
        message: acao.label,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.go(acao.route),
          child: content,
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
      child: content,
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
