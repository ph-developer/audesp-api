import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../processo/domain/processo.dart';
import '../../processo/domain/processo_rules.dart';
import '../../processo/processo_providers.dart';
import 'pcnp_input_formatter.dart';

enum UnlinkedEditaisTarget { licitacao, ata, ajuste }

class UnlinkedEditaisData {
  final List<Edital> editais;
  final Map<int, int> linkedCounts;
  final Map<int, String> motivosBloqueio;

  const UnlinkedEditaisData({
    required this.editais,
    required this.linkedCounts,
    this.motivosBloqueio = const {},
  });
}

final unlinkedEditaisProvider = FutureProvider.autoDispose
    .family<UnlinkedEditaisData, UnlinkedEditaisTarget>((ref, target) async {
      if (target == UnlinkedEditaisTarget.licitacao) {
        final editaisEnviados = await ref
            .watch(editaisDaoProvider)
            .watchByStatus('sent');
        final processos = Processo.agrupar(
          editais: editaisEnviados,
          licitacoes: await ref.watch(licitacoesDaoProvider).watchAll(),
          atas: const [],
          ajustes: const [],
        );
        return UnlinkedEditaisData(
          editais: editaisEnviados,
          linkedCounts: {
            for (final processo in processos)
              processo.edital.id: processo.licitacoes.length,
          },
        );
      }

      final processos = await ref.watch(processosProvider.future);
      final opcoes = target == UnlinkedEditaisTarget.ata
          ? ProcessoRules.opcoesAta(processos)
          : ProcessoRules.opcoesAjuste(
              processos,
            ).where((o) => !o.processo.edital.isSrp).toList();

      return UnlinkedEditaisData(
        editais: opcoes.map((o) => o.processo.edital).toList(),
        linkedCounts: {
          for (final opcao in opcoes)
            opcao.processo.edital.id: target == UnlinkedEditaisTarget.ata
                ? opcao.processo.atas.length
                : opcao.processo.ajustes.length,
        },
        motivosBloqueio: {
          for (final opcao in opcoes)
            opcao.processo.edital.id: ?opcao.motivoBloqueio,
        },
      );
    });

Future<Edital?> showUnlinkedEditaisDialog({
  required BuildContext context,
  required UnlinkedEditaisTarget target,
  required String title,
  required String emptyMessage,
}) {
  return showAudespDialog<Edital>(
    context: context,
    size: DialogSize.large,
    builder: (_) => _UnlinkedEditaisDialog(
      target: target,
      title: title,
      emptyMessage: emptyMessage,
    ),
  );
}

class _UnlinkedEditaisDialog extends ConsumerStatefulWidget {
  final UnlinkedEditaisTarget target;
  final String title;
  final String emptyMessage;

  const _UnlinkedEditaisDialog({
    required this.target,
    required this.title,
    required this.emptyMessage,
  });

  @override
  ConsumerState<_UnlinkedEditaisDialog> createState() =>
      _UnlinkedEditaisDialogState();
}

class _UnlinkedEditaisDialogState
    extends ConsumerState<_UnlinkedEditaisDialog> {
  final _searchCtrl = TextEditingController();
  bool _exibirJaEnviados = false;
  bool _mostrarBloqueados = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(unlinkedEditaisProvider(widget.target));

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (data) {
            final showExibirJaEnviados =
                widget.target != UnlinkedEditaisTarget.licitacao;
            final canShowAll = showExibirJaEnviados && _exibirJaEnviados;

            final candidates = data.editais.where((e) {
              if (!canShowAll && (data.linkedCounts[e.id] ?? 0) > 0) {
                return false;
              }
              return _mostrarBloqueados ||
                  !data.motivosBloqueio.containsKey(e.id);
            }).toList();

            final filtered = candidates.where((edital) {
              return matchesLikeSearch(
                _searchableEditalText(edital),
                _searchCtrl.text,
              );
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
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
                    if (showExibirJaEnviados) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => setState(
                          () => _exibirJaEnviados = !_exibirJaEnviados,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _exibirJaEnviados,
                                onChanged: (v) => setState(
                                  () => _exibirJaEnviados = v ?? false,
                                ),
                              ),
                              const Text('Exibir já enviados'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => setState(
                          () => _mostrarBloqueados = !_mostrarBloqueados,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _mostrarBloqueados,
                                onChanged: (v) => setState(
                                  () => _mostrarBloqueados = v ?? false,
                                ),
                              ),
                              const Text('Mostrar bloqueados'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: candidates.isEmpty
                      ? Center(
                          child: Text(
                            canShowAll
                                ? 'Nenhum edital disponível.'
                                : widget.emptyMessage,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : filtered.isEmpty
                      ? const Center(
                          child: Text('Nenhum edital para este filtro.'),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final edital = filtered[index];
                            final compra = [
                              if (edital.modalidadeLabel.isNotEmpty)
                                edital.modalidadeLabel,
                              if (edital.numeroCompra.isNotEmpty &&
                                  edital.anoCompra != 0)
                                '${edital.numeroCompra}/${edital.anoCompra}',
                            ].join(' ');
                            final linkedCount =
                                data.linkedCounts[edital.id] ?? 0;
                            final motivoBloqueio =
                                data.motivosBloqueio[edital.id];

                            return ListTile(
                              enabled: motivoBloqueio == null,
                              leading: const Icon(Icons.article_outlined),
                              title: Text(
                                compra.isEmpty ? edital.dropdownLabel : compra,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  [
                                    PcnpInputFormatter.applyMask(
                                      edital.idContratacaoPNCP,
                                    ),
                                    if (edital.objetoCompra.isNotEmpty)
                                      edital.objetoCompra,
                                  ].join(' - '),
                                  ?motivoBloqueio,
                                ].join('\n'),
                                maxLines: motivoBloqueio == null ? 2 : 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: linkedCount > 0
                                  ? StatusChip(
                                      label:
                                          widget.target ==
                                              UnlinkedEditaisTarget.ata
                                          ? '$linkedCount ${linkedCount == 1 ? 'ata' : 'atas'}'
                                          : widget.target ==
                                                UnlinkedEditaisTarget.ajuste
                                          ? '$linkedCount ${linkedCount == 1 ? 'ajuste' : 'ajustes'}'
                                          : '$linkedCount ${linkedCount == 1 ? 'licitação' : 'licitações'}',
                                    )
                                  : null,
                              onTap: motivoBloqueio == null
                                  ? () => Navigator.of(context).pop(edital)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

String _searchableEditalText(Edital edital) {
  return [
    edital.modalidadeLabel,
    edital.numeroCompra,
    edital.anoCompra == 0 ? '' : edital.anoCompra.toString(),
    edital.codigoEdital,
    edital.idContratacaoPNCP,
    edital.dropdownLabel,
    edital.objetoCompra,
  ].join(' ');
}
