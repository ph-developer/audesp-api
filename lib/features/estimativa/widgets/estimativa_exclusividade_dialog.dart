import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_checkbox.dart';
import '../models/estimativa_item_model.dart';
import '../models/estimativa_lote_model.dart';

class EstimativaExclusividadeResult {
  final List<EstimativaItem> itens;
  final List<EstimativaLote> lotes;

  const EstimativaExclusividadeResult({
    required this.itens,
    required this.lotes,
  });
}

Future<EstimativaExclusividadeResult?> showEstimativaExclusividadeDialog({
  required BuildContext context,
  required String tipoEstimativa,
  required List<EstimativaItem> itens,
  required List<EstimativaLote> lotes,
}) {
  final isLote = tipoEstimativa == 'lote';
  final tempItens = itens.map((i) => i.copyWith()).toList();
  final tempLotes = lotes.map((l) => l.copyWith()).toList();

  return showDialog<EstimativaExclusividadeResult>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Selecionar ${isLote ? 'Lotes' : 'Itens'} Exclusivos'),
            content: SizedBox(
              width: 400,
              child: isLote
                  ? tempLotes.isEmpty
                        ? const Text('Nenhum lote adicionado.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: tempLotes.length,
                            itemBuilder: (context, index) {
                              final lote = tempLotes[index];
                              return AudespCheckbox(
                                label:
                                    'Lote ${lote.numero} - ${lote.descricao}',
                                value: lote.exclusivoMeEpp,
                                onChanged: (v) {
                                  setModalState(() {
                                    tempLotes[index] = lote.copyWith(
                                      exclusivoMeEpp: v ?? false,
                                    );
                                  });
                                },
                              );
                            },
                          )
                  : tempItens.isEmpty
                  ? const Text('Nenhum item adicionado.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: tempItens.length,
                      itemBuilder: (context, index) {
                        final item = tempItens[index];
                        return AudespCheckbox(
                          label: 'Item ${item.numero} - ${item.descricao}',
                          value: item.exclusivoMeEpp,
                          onChanged: (v) {
                            setModalState(() {
                              tempItens[index] = item.copyWith(
                                exclusivoMeEpp: v ?? false,
                              );
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  EstimativaExclusividadeResult(
                    itens: tempItens,
                    lotes: tempLotes,
                  ),
                ),
                child: const Text('Concluído'),
              ),
            ],
          );
        },
      );
    },
  );
}
