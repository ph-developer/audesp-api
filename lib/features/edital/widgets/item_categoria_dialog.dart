import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_dialog.dart';
import '../domain/edital_rules.dart';

const _categorias = <int, String>{1: 'Bens Imóveis', 2: 'Bens Móveis'};

/// Diálogo para definir de uma vez a categoria dos itens de um edital de
/// leilão (Bens Imóveis ou Bens Móveis).
///
/// Retorna a categoria de cada item, na mesma ordem de [itens], ou null se
/// o usuário cancelou.
Future<List<int?>?> showItemCategoriaDialog(
  BuildContext context, {
  required int? modalidadeId,
  required List<Map<String, dynamic>> itens,
}) {
  return showAudespDialog<List<int?>>(
    context: context,
    size: DialogSize.large,
    builder: (_) =>
        _ItemCategoriaDialog(modalidadeId: modalidadeId, itens: itens),
  );
}

class _ItemCategoriaDialog extends StatefulWidget {
  final int? modalidadeId;
  final List<Map<String, dynamic>> itens;
  const _ItemCategoriaDialog({required this.modalidadeId, required this.itens});

  @override
  State<_ItemCategoriaDialog> createState() => _ItemCategoriaDialogState();
}

class _ItemCategoriaDialogState extends State<_ItemCategoriaDialog> {
  late final List<int?> _selecao = [
    for (final item in widget.itens)
      EditalRules.categoriaItem(
        modalidadeId: widget.modalidadeId,
        atual: item['itemCategoriaId'],
      ),
  ];

  void _aplicarATodos(int categoria) {
    setState(() => _selecao.fillRange(0, _selecao.length, categoria));
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _selecao.where((c) => c == null).length;
    return AlertDialog(
      title: const Text('Categoria dos Itens'),
      content: SizedBox(
        width: double.maxFinite,
        height: 460,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Aplicar a todos:'),
                const SizedBox(width: 12),
                for (final e in _categorias.entries) ...[
                  OutlinedButton(
                    onPressed: () => _aplicarATodos(e.key),
                    child: Text(e.value),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: widget.itens.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = widget.itens[index];
                  final label =
                      'Item ${item['numeroItem'] ?? index + 1} - '
                      '${item['descricao'] ?? ''}';
                  return SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: label,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SegmentedButton<int>(
                          emptySelectionAllowed: true,
                          showSelectedIcon: false,
                          segments: [
                            for (final e in _categorias.entries)
                              ButtonSegment(value: e.key, label: Text(e.value)),
                          ],
                          selected: {?_selecao[index]},
                          onSelectionChanged: (s) => setState(
                            () => _selecao[index] = s.isEmpty ? null : s.first,
                          ),
                        ),
                      ],
                    ),
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
                pendentes == 0
                    ? 'Todos os itens com categoria.'
                    : '$pendentes item(ns) sem categoria.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: pendentes == 0
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_selecao),
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
