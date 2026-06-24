import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../estimativa_providers.dart';
import '../models/estimativa_model.dart';

Future<EstimativaModel?> showEstimativaImportDialog(BuildContext context) {
  return showDialog<EstimativaModel>(
    context: context,
    builder: (ctx) => const _EstimativaImportDialog(),
  );
}

class _EstimativaImportDialog extends ConsumerWidget {
  const _EstimativaImportDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            return ListView.builder(
              itemCount: estimativas.length,
              itemBuilder: (ctx, i) {
                final est = estimativas[i];
                final updateDate = DateTime.fromMillisecondsSinceEpoch(
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
