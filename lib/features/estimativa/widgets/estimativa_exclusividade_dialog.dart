import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../domain/estimativa_exclusividade_resumo.dart';
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
  required String calculoGlobal,
  required int casasDecimais,
  required List<String> desclassificadosIds,
}) {
  final isLote = tipoEstimativa == 'lote';
  final tempItens = itens.map((i) => i.copyWith()).toList();
  final tempLotes = lotes.map((l) => l.copyWith()).toList();

  return showAudespDialog<EstimativaExclusividadeResult>(
    context: context,
    size: DialogSize.large,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final valores = isLote
              ? tempLotes
                    .map(
                      (lote) => lote.getValorTotal(
                        calculoGlobal,
                        casasDecimais: casasDecimais,
                        desclassificadosIds: desclassificadosIds,
                      ),
                    )
                    .toList()
              : tempItens
                    .map(
                      (item) => item.getValorTotal(
                        calculoGlobal,
                        casasDecimais: casasDecimais,
                        desclassificadosIds: desclassificadosIds,
                      ),
                    )
                    .toList();
          final resumo = EstimativaExclusividadeResumo.calcular(
            List.generate(
              valores.length,
              (index) => (
                valor: valores[index],
                selecionado: isLote
                    ? tempLotes[index].exclusivoMeEpp
                    : tempItens[index].exclusivoMeEpp,
              ),
            ),
          );

          return AlertDialog(
            title: Text('Selecionar ${isLote ? 'Lotes' : 'Itens'} Exclusivos'),
            content: SizedBox(
              width: double.maxFinite,
              height: 460,
              child: valores.isEmpty
                  ? Text('Nenhum ${isLote ? 'lote' : 'item'} adicionado.')
                  : Column(
                      children: [
                        _buildHeader(isLote),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            itemCount: valores.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final selecionado = isLote
                                  ? tempLotes[index].exclusivoMeEpp
                                  : tempItens[index].exclusivoMeEpp;
                              final numero = isLote
                                  ? tempLotes[index].numero
                                  : tempItens[index].numero;
                              final descricao = isLote
                                  ? tempLotes[index].descricao
                                  : tempItens[index].descricao;
                              final valor = valores[index];
                              final percentual = percentualDoTotal(
                                valor,
                                resumo.valorTotal,
                              );

                              return _buildRow(
                                label:
                                    '${isLote ? 'Lote' : 'Item'} $numero - $descricao',
                                selecionado: selecionado,
                                valor: formatBRL(
                                  valor,
                                  casasDecimais: casasDecimais,
                                ),
                                percentual:
                                    '${percentual.toStringAsFixed(2)}%',
                                onChanged: (value) {
                                  setModalState(() {
                                    if (isLote) {
                                      tempLotes[index] = tempLotes[index]
                                          .copyWith(exclusivoMeEpp: value);
                                    } else {
                                      tempItens[index] = tempItens[index]
                                          .copyWith(exclusivoMeEpp: value);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              SizedBox(
                width: double.maxFinite,
                child: Row(
                  children: [
                    Text(
                      'Selecionado: ${formatBRL(resumo.valorSelecionado, casasDecimais: casasDecimais)} '
                      '(${resumo.percentualSelecionado.toStringAsFixed(2)}%)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
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
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildHeader(bool isLote) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Text(
            isLote ? 'Lote' : 'Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(
          width: 150,
          child: Text(
            'Valor',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(
          width: 110,
          child: Text(
            '% do total',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRow({
  required String label,
  required bool selecionado,
  required String valor,
  required String percentual,
  required ValueChanged<bool> onChanged,
}) {
  return SizedBox(
    height: 52,
    child: Row(
      children: [
        SizedBox(
          width: 48,
          child: Checkbox(
            value: selecionado,
            onChanged: (value) => onChanged(value ?? false),
          ),
        ),
        Expanded(
          child: Tooltip(
            message: label,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        SizedBox(
          width: 150,
          child: Text(valor, textAlign: TextAlign.right),
        ),
        SizedBox(
          width: 110,
          child: Text(percentual, textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}
