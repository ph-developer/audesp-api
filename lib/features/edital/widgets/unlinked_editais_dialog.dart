import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import 'pcnp_input_formatter.dart';

enum UnlinkedEditaisTarget { licitacao, ata, ajuste }

final unlinkedEditaisProvider = FutureProvider.autoDispose
    .family<List<Edital>, UnlinkedEditaisTarget>((ref, target) async {
      final editais = await ref.watch(editaisDaoProvider).watchAll();

      switch (target) {
        case UnlinkedEditaisTarget.licitacao:
          final licitacoes = await ref.watch(licitacoesDaoProvider).watchAll();
          final linkedIds = licitacoes.map((l) => l.editalId).toSet();
          return editais.where((e) => !linkedIds.contains(e.id)).toList();
        case UnlinkedEditaisTarget.ata:
          final atas = await ref.watch(atasDaoProvider).watchAll();
          final linkedIds = atas.map((a) => a.editalId).toSet();
          return editais
              .where((e) => e.isSrp && !linkedIds.contains(e.id))
              .toList();
        case UnlinkedEditaisTarget.ajuste:
          final ajustes = await ref.watch(ajustesDaoProvider).watchAll();
          final linkedIds = ajustes.map((a) => a.editalId).toSet();
          return editais
              .where((e) => !e.isSrp && !linkedIds.contains(e.id))
              .toList();
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editaisAsync = ref.watch(unlinkedEditaisProvider(widget.target));

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: editaisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (editais) {
            if (editais.isEmpty) {
              return Center(child: Text(widget.emptyMessage));
            }

            final filtered = editais.where((edital) {
              return matchesLikeSearch(
                _searchableEditalText(edital),
                _searchCtrl.text,
              );
            }).toList();

            return Column(
              children: [
                AudespTextField(
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
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
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
