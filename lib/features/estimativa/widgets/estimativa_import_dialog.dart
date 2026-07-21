import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../estimativa_providers.dart';
import '../models/estimativa_model.dart';

Future<EstimativaModel?> showEstimativaImportDialog(BuildContext context) {
  return showAudespDialog<EstimativaModel>(
    context: context,
    size: DialogSize.medium,
    builder: (_) => const _EstimativaImportDialog(),
  );
}

class _EstimativaImportDialog extends ConsumerStatefulWidget {
  const _EstimativaImportDialog();

  @override
  ConsumerState<_EstimativaImportDialog> createState() =>
      _EstimativaImportDialogState();
}

class _EstimativaImportDialogState
    extends ConsumerState<_EstimativaImportDialog> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(estimativasListProvider);

    return AlertDialog(
      title: const Text('Importar de Estimativa'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: stream.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (estimativas) {
            if (estimativas.isEmpty) {
              return const Center(
                child: Text('Nenhuma estimativa encontrada.'),
              );
            }

            final fmt = DateFormat('dd/MM/yyyy HH:mm');
            final currencyFmt = NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
            );
            final filtered = estimativas.where((estimativa) {
              final searchable = [
                'Estimativa ${estimativa.numero}/${estimativa.ano}',
                estimativa.objeto,
                estimativa.tipoEstimativa == 'lote' ? 'Por Lote' : 'Por Item',
                currencyFmt.format(estimativa.valorTotalGlobal),
              ].join(' ');
              return matchesLikeSearch(searchable, _searchCtrl.text);
            }).toList();

            return Column(
              children: [
                AudespTextField(
                  label: 'Filtrar',
                  controller: _searchCtrl,
                  autofocus: true,
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
                          child: Text('Nenhuma estimativa para este filtro.'),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final est = filtered[i];
                            final updateDate =
                                DateTime.fromMillisecondsSinceEpoch(
                                  est.updatedAt * 1000,
                                );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  'Estimativa ${est.numero}/${est.ano} - ${est.objeto}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Tipo: ${est.tipoEstimativa == "lote" ? "Por Lote" : "Por Item"} | '
                                  'Valor Total: ${currencyFmt.format(est.valorTotalGlobal)}\n'
                                  'Atualizado em: ${fmt.format(updateDate)}',
                                ),
                                isThreeLine: true,
                                onTap: () => Navigator.pop(context, est),
                              ),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
