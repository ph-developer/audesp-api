import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_dropdown.dart';
import '../models/estimativa_lote_model.dart';

class TransferirItensMassaResult {
  final int loteDestinoIndex;
  final List<int> itensIndexes;

  TransferirItensMassaResult({
    required this.loteDestinoIndex,
    required this.itensIndexes,
  });
}

Future<TransferirItensMassaResult?> showEstimativaTransferirItensDialog({
  required BuildContext context,
  required List<EstimativaLote> lotes,
  required int loteOrigemIndex,
}) {
  return showDialog<TransferirItensMassaResult>(
    context: context,
    builder: (ctx) =>
        _TransferirItensDialog(lotes: lotes, loteOrigemIndex: loteOrigemIndex),
  );
}

class _TransferirItensDialog extends StatefulWidget {
  final List<EstimativaLote> lotes;
  final int loteOrigemIndex;

  const _TransferirItensDialog({
    required this.lotes,
    required this.loteOrigemIndex,
  });

  @override
  State<_TransferirItensDialog> createState() => _TransferirItensDialogState();
}

class _TransferirItensDialogState extends State<_TransferirItensDialog> {
  int? _loteDestinoIndex;
  late final List<bool> _selected;

  @override
  void initState() {
    super.initState();
    final loteOrigem = widget.lotes[widget.loteOrigemIndex];
    _selected = List.generate(loteOrigem.itens.length, (_) => false);
  }

  int get _selectedCount => _selected.where((v) => v).length;

  void _acceptAll() =>
      setState(() => _selected.fillRange(0, _selected.length, true));
  void _rejectAll() =>
      setState(() => _selected.fillRange(0, _selected.length, false));

  void _confirm() {
    if (_loteDestinoIndex == null || _selectedCount == 0) return;

    final selectedIndexes = <int>[];
    for (int i = 0; i < _selected.length; i++) {
      if (_selected[i]) selectedIndexes.add(i);
    }

    Navigator.pop(
      context,
      TransferirItensMassaResult(
        loteDestinoIndex: _loteDestinoIndex!,
        itensIndexes: selectedIndexes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loteOrigem = widget.lotes[widget.loteOrigemIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Map<int, String> lotesDisponiveis = {};
    for (int i = 0; i < widget.lotes.length; i++) {
      if (i != widget.loteOrigemIndex) {
        lotesDisponiveis[i] =
            'Lote ${widget.lotes[i].numero} - ${widget.lotes[i].descricao}';
      }
    }

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.drive_file_move_outline),
          SizedBox(width: 12),
          Expanded(child: Text('Transferir Itens em Massa')),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Origem: Lote ${loteOrigem.numero} - ${loteOrigem.descricao}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            if (lotesDisponiveis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Não há outros lotes disponíveis para transferência.',
                ),
              )
            else ...[
              AudespDropdown<int>(
                label: 'Lote de Destino *',
                value: _loteDestinoIndex,
                items: lotesDisponiveis,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _loteDestinoIndex = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selecione os itens para transferir (${loteOrigem.itens.length})',
                    style: theme.textTheme.titleSmall,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _acceptAll,
                        child: const Text('Todos'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _rejectAll,
                        child: const Text('Nenhum'),
                      ),
                    ],
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(60),
                      1: FlexColumnWidth(1),
                      2: FixedColumnWidth(48),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        children: [
                          _tableHeader('Item Nº'),
                          _tableHeader('Descrição'),
                          _tableHeader(''),
                        ],
                      ),
                      for (int i = 0; i < loteOrigem.itens.length; i++)
                        _buildRow(i, colorScheme),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$_selectedCount item(ns) selecionado(s) para transferência.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        if (lotesDisponiveis.isNotEmpty)
          FilledButton(
            onPressed: (_loteDestinoIndex == null || _selectedCount == 0)
                ? null
                : _confirm,
            child: const Text('Transferir'),
          ),
      ],
    );
  }

  TableRow _buildRow(int index, ColorScheme colorScheme) {
    final item = widget.lotes[widget.loteOrigemIndex].itens[index];
    final isSelected = _selected[index];

    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer.withAlpha(80) : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            '${item.numero}',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            item.descricao,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Checkbox(
          value: isSelected,
          onChanged: (v) => setState(() => _selected[index] = v ?? false),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}
