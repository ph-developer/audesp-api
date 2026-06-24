import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';

import 'package:intl/intl.dart';

import '../../edital/domain/edital_domain.dart';
import '../models/estimativa_lote_model.dart';
import '../models/estimativa_item_model.dart';
import 'estimativa_item_dialog.dart';

Future<EstimativaLote?> showEstimativaLoteDialog({
  required BuildContext context,
  EstimativaLote? lote,
  required String calculoGlobal,
  int? nextNumero,
}) {
  return showDialog<EstimativaLote>(
    context: context,
    builder: (ctx) => _LoteDialog(
      lote: lote,
      calculoGlobal: calculoGlobal,
      nextNumero: nextNumero,
    ),
  );
}

class _LoteDialog extends StatefulWidget {
  final EstimativaLote? lote;
  final String calculoGlobal;
  final int? nextNumero;

  const _LoteDialog({this.lote, required this.calculoGlobal, this.nextNumero});

  @override
  State<_LoteDialog> createState() => _LoteDialogState();
}

class _LoteDialogState extends State<_LoteDialog> {
  final _formKey = GlobalKey<FormState>();

  final _numeroCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _quantidadeCtrl = TextEditingController(text: '1.0');
  final _unidadeCtrl = TextEditingController(text: 'UN');
  String _materialOuServico = 'M';
  int? _itemCategoriaId;
  bool _exclusivoMeEpp = false;

  List<EstimativaItem> _itens = [];

  @override
  void initState() {
    super.initState();
    if (widget.lote != null) {
      final l = widget.lote!;
      _numeroCtrl.text = l.numero.toString();
      _descricaoCtrl.text = l.descricao;
      _quantidadeCtrl.text = doubleToBrString(l.quantidade);
      _unidadeCtrl.text = l.unidade;
      _materialOuServico = l.materialOuServico;
      _itemCategoriaId = l.itemCategoriaId;
      _exclusivoMeEpp = l.exclusivoMeEpp;
      _itens = List.from(l.itens);
    } else if (widget.nextNumero != null) {
      _numeroCtrl.text = widget.nextNumero.toString();
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _descricaoCtrl.dispose();
    _quantidadeCtrl.dispose();
    _unidadeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = EstimativaLote(
      numero: int.tryParse(_numeroCtrl.text.trim()) ?? 0,
      descricao: _descricaoCtrl.text.trim(),
      quantidade:
          double.tryParse(_quantidadeCtrl.text.trim().replaceAll(',', '.')) ??
          1.0,
      unidade: _unidadeCtrl.text.trim().toUpperCase(),
      materialOuServico: _materialOuServico,
      itemCategoriaId: _itemCategoriaId,
      exclusivoMeEpp: _exclusivoMeEpp,
      itens: _itens,
    );

    Navigator.pop(context, result);
  }

  Future<void> _addItem() async {
    final res = await showEstimativaItemDialog(
      context: context,
      estimativaTipo: 'lote',
      calculoGlobal: widget.calculoGlobal,
      nextNumero: _itens.length + 1,
    );
    if (res != null) {
      setState(() {
        _itens.add(res);
      });
    }
  }

  Future<void> _editItem(int index) async {
    final res = await showEstimativaItemDialog(
      context: context,
      item: _itens[index],
      estimativaTipo: 'lote',
      calculoGlobal: widget.calculoGlobal,
    );
    if (res != null) {
      setState(() {
        _itens[index] = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final dummyLote = EstimativaLote(
      numero: 0,
      descricao: '',
      exclusivoMeEpp: _exclusivoMeEpp,
      itens: _itens,
    );

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              widget.lote == null ? 'Novo Lote' : 'Editar Lote',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado Esquerdo: Formulário do Lote
                  Expanded(
                    flex: 1,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AudespTextField(
                            label: 'Lote Nº',
                            controller: _numeroCtrl,
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          AudespTextField(
                            label: 'Descrição *',
                            controller: _descricaoCtrl,
                            maxLines: 2,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Obrigatório' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AudespNumberField(
                                  label: 'Quantidade *',
                                  controller: _quantidadeCtrl,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Obrigatório'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: AudespTextField(
                                  label: 'Unidade *',
                                  controller: _unidadeCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Obrigatório'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AudespDropdown<String>(
                            label: 'Material/Serviço *',
                            value: _materialOuServico,
                            items: const {'M': 'Material', 'S': 'Serviço'},
                            onChanged: (v) =>
                                setState(() => _materialOuServico = v!),
                            validator: (v) => v == null ? 'Obrigatório' : null,
                          ),
                          const SizedBox(height: 12),
                          AudespDropdown<int>(
                            label: 'Categoria do Lote *',
                            value: _itemCategoriaId,
                            items: kItemCategoria,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _itemCategoriaId = v);
                              }
                            },
                            validator: (v) => v == null ? 'Obrigatório' : null,
                          ),

                          const Spacer(),
                          Card(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Valor de Referência do Lote'),
                                  Text(
                                    fmt.format(
                                      dummyLote.getValorTotal(
                                        widget.calculoGlobal,
                                      ),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Lado Direito: Itens do Lote
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Itens do Lote',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Adicionar Item'),
                            ),
                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: _itens.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhum item adicionado ao lote.',
                                  ),
                                )
                              : ReorderableListView.builder(
                                  buildDefaultDragHandles: false,
                                  itemCount: _itens.length,
                                  onReorderItem: (oldIndex, newIndex) {
                                    setState(() {
                                      final item = _itens.removeAt(oldIndex);
                                      _itens.insert(newIndex, item);
                                      for (int i = 0; i < _itens.length; i++) {
                                        _itens[i] = _itens[i].copyWith(
                                          numero: i + 1,
                                        );
                                      }
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final item = _itens[index];
                                    final isMensal =
                                        item.tipoFornecimento == 'mensal';
                                    return Card(
                                      key: ValueKey(item.numero),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        dense: true,
                                        title: Text(
                                          'Item ${item.numero} - ${item.descricao}',
                                        ),
                                        subtitle: Text(
                                          '${item.quantidade} ${item.unidade} | '
                                          '${isMensal ? "Mensal (${item.quantidadeMeses}m)" : "Única"} | '
                                          'Total: ${fmt.format(item.getValorTotal(widget.calculoGlobal))}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (item.orcamentos.length < 3)
                                              const Tooltip(
                                                message:
                                                    'Menos de 3 orçamentos',
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Icon(
                                                    Icons.warning_amber,
                                                    color: Colors.amber,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 16,
                                              ),
                                              onPressed: () => _editItem(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 16,
                                              ),
                                              color: Colors.red,
                                              onPressed: () => setState(
                                                () => _itens.removeAt(index),
                                              ),
                                            ),
                                            ReorderableDragStartListener(
                                              index: index,
                                              child: const MouseRegion(
                                                cursor: SystemMouseCursors.move,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                                  child: Icon(
                                                    Icons.drag_handle,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Salvar Lote'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
