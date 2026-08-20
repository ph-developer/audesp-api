import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/status_chip.dart';
import 'pcnp_input_formatter.dart';

enum UnlinkedEditaisTarget { licitacao, ata, ajuste }

class UnlinkedEditaisData {
  final List<Edital> editais;
  final Map<int, int> linkedCounts;

  const UnlinkedEditaisData({
    required this.editais,
    required this.linkedCounts,
  });
}

final unlinkedEditaisProvider = FutureProvider.autoDispose
    .family<UnlinkedEditaisData, UnlinkedEditaisTarget>((ref, target) async {
      final editaisEnviados =
          await ref.watch(editaisDaoProvider).watchByStatus('sent');

      final linkedCounts = <int, int>{};

      switch (target) {
        case UnlinkedEditaisTarget.licitacao:
          final licitacoes = await ref.watch(licitacoesDaoProvider).watchAll();
          for (final l in licitacoes) {
            linkedCounts[l.editalId] = (linkedCounts[l.editalId] ?? 0) + 1;
          }
          return UnlinkedEditaisData(
            editais: editaisEnviados,
            linkedCounts: linkedCounts,
          );
        case UnlinkedEditaisTarget.ata:
          final atas = await ref.watch(atasDaoProvider).watchAll();
          for (final a in atas) {
            linkedCounts[a.editalId] = (linkedCounts[a.editalId] ?? 0) + 1;
          }
          return UnlinkedEditaisData(
            editais: editaisEnviados.where((e) => e.isSrp).toList(),
            linkedCounts: linkedCounts,
          );
        case UnlinkedEditaisTarget.ajuste:
          final ajustes = await ref.watch(ajustesDaoProvider).watchAll();
          for (final a in ajustes) {
            linkedCounts[a.editalId] = (linkedCounts[a.editalId] ?? 0) + 1;
          }
          return UnlinkedEditaisData(
            editais: editaisEnviados.where((e) => !e.isSrp).toList(),
            linkedCounts: linkedCounts,
          );
      }
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

            final candidates = canShowAll
                ? data.editais
                : data.editais
                    .where((e) => (data.linkedCounts[e.id] ?? 0) == 0)
                    .toList();

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

                            return ListTile(
                              leading: const Icon(Icons.article_outlined),
                              title: Text(
                                compra.isEmpty ? edital.dropdownLabel : compra,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  PcnpInputFormatter.applyMask(
                                    edital.idContratacaoPNCP,
                                  ),
                                  if (edital.objetoCompra.isNotEmpty)
                                    edital.objetoCompra,
                                ].join(' - '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: linkedCount > 0
                                  ? StatusChip(
                                      label: widget.target ==
                                              UnlinkedEditaisTarget.ata
                                          ? '$linkedCount ${linkedCount == 1 ? 'ata' : 'atas'}'
                                          : widget.target ==
                                                  UnlinkedEditaisTarget.ajuste
                                              ? '$linkedCount ${linkedCount == 1 ? 'ajuste' : 'ajustes'}'
                                              : '$linkedCount ${linkedCount == 1 ? 'licitação' : 'licitações'}',
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(edital),
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

