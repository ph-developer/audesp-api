import 'package:audesp_api/shared/widgets/audesp_currency_field.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/estimativa_fornecedor_model.dart';
import '../models/estimativa_orcamento_model.dart';

/// Resultado do dialog de valor: null significa remover, double significa salvar.
Future<double?> showEstimativaValorDialog({
  required BuildContext context,
  required EstimativaFornecedor fornecedor,
  required EstimativaOrcamento? atual,
}) {
  final valorStr = atual != null ? doubleToBrString(atual.valorUnitario) : '';
  final valorCtrl = TextEditingController(text: valorStr);

  return showDialog<double?>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Valor - ${fornecedor.razaoSocial}'),
        content: AudespCurrencyField(
          controller: valorCtrl,
          autofocus: true,
          label: 'Valor Unitário (R\$)',
        ),
        actions: [
          if (atual != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1.0),
              child: const Text(
                'Remover Valor',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final vStr = valorCtrl.text
                  .replaceAll('.', '')
                  .replaceAll(',', '.');
              final v = double.tryParse(vStr);
              if (v != null) {
                Navigator.pop(ctx, v);
              } else if (valorCtrl.text.trim().isEmpty) {
                Navigator.pop(ctx, -1.0);
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  ).then((value) {
    valorCtrl.dispose();
    return value;
  });
}
