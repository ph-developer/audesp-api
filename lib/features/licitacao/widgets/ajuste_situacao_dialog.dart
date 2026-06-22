import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../domain/licitacao_domain.dart';

/// Abre o diálogo de ajuste em lote da situação e data dos itens.
///
/// Recebe [itens]: a lista de itens da licitação.
///
/// Retorna uma `List<Map<String, dynamic>>` com os itens atualizados,
/// ou null se cancelado.
Future<List<Map<String, dynamic>>?> showAjusteSituacaoDialog(
  BuildContext context,
  List<Map<String, dynamic>> itens,
) {
  return showAudespDialog<List<Map<String, dynamic>>>(
    context: context,
    size: DialogSize.large,
    builder: (_) => _AjusteSituacaoDialog(itens: itens),
  );
}

class _AjusteSituacaoDialog extends StatefulWidget {
  final List<Map<String, dynamic>> itens;
  const _AjusteSituacaoDialog({required this.itens});

  @override
  State<_AjusteSituacaoDialog> createState() => _AjusteSituacaoDialogState();
}

class _AjusteSituacaoDialogState extends State<_AjusteSituacaoDialog> {
  late List<Map<String, dynamic>> _itens;
  final Set<int> _selectedIndices = {};

  int? _batchSituacao;
  DateTime? _batchData;

  @override
  void initState() {
    super.initState();
    // Deep copy dos itens principais (somente os campos que vamos alterar)
    _itens = widget.itens.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _submit() {
    // Validar se todos têm situação e data se necessário,
    // mas a validação principal ocorre no envio.
    Navigator.of(context).pop(_itens);
  }

  void _applyBatch() {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos um item para aplicar.'),
        ),
      );
      return;
    }
    if (_batchSituacao == null && _batchData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma situação ou data para aplicar.'),
        ),
      );
      return;
    }

    setState(() {
      for (final i in _selectedIndices) {
        if (_batchSituacao != null) {
          _itens[i]['situacaoCompraItemId'] = _batchSituacao;
        }
        if (_batchData != null) {
          _itens[i]['dataSituacaoItem'] = _batchData!
              .toIso8601String()
              .substring(0, 10);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aplicado aos itens selecionados.')),
    );
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.addAll(List.generate(_itens.length, (i) => i));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _itens.isNotEmpty && _selectedIndices.length == _itens.length;
    final someSelected = _selectedIndices.isNotEmpty && !allSelected;

    return AlertDialog(
      title: const Text('Ajustar Situação dos Itens'),
      content: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajuste a situação e a data dos itens. Você pode alterar individualmente ou selecionar múltiplos e aplicar em lote.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // Batch Controls
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aplicação em Lote',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          key: ValueKey(_batchSituacao),
                          isExpanded: true,
                          initialValue: _batchSituacao,
                          decoration: const InputDecoration(
                            labelText: 'Nova Situação',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: kSituacaoCompraItem.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _batchSituacao = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: AudespDatePickerField(
                          label: 'Nova Data',
                          value: _batchData,
                          onChanged: (d) => setState(() => _batchData = d),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: _applyBatch,
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: allSelected ? true : (someSelected ? null : false),
                  tristate: true,
                  onChanged: _toggleSelectAll,
                ),
                const Text(
                  'Selecionar Todos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('${_selectedIndices.length} selecionado(s)'),
              ],
            ),
            const Divider(height: 1),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _itens.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = _itens[i];
                    final situacaoId = item['situacaoCompraItemId'] as int?;
                    final dataStr = item['dataSituacaoItem'] as String? ?? '';
                    final dataVal = DateTime.tryParse(dataStr);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _selectedIndices.contains(i),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedIndices.add(i);
                                } else {
                                  _selectedIndices.remove(i);
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Item ${item['numeroItem']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              key: ValueKey(situacaoId),
                              isExpanded: true,
                              initialValue: situacaoId,
                              decoration: const InputDecoration(
                                labelText: 'Situação',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: kSituacaoCompraItem.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => item['situacaoCompraItemId'] = v,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: AudespDatePickerField(
                              label: 'Data',
                              value: dataVal,
                              onChanged: (d) => setState(
                                () => item['dataSituacaoItem'] = d != null
                                    ? d.toIso8601String().substring(0, 10)
                                    : '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar Alterações'),
        ),
      ],
    );
  }
}
