import 'package:flutter/material.dart';

import '../models/estimativa_lote_model.dart';
import '../models/estimativa_item_model.dart';
import 'estimativa_item_dialog.dart';
import 'package:intl/intl.dart';

Future<EstimativaLote?> showEstimativaLoteDialog({
  required BuildContext context,
  EstimativaLote? lote,
  required String calculoGlobal,
}) {
  return showDialog<EstimativaLote>(
    context: context,
    builder: (ctx) => _LoteDialog(lote: lote, calculoGlobal: calculoGlobal),
  );
}

class _LoteDialog extends StatefulWidget {
  final EstimativaLote? lote;
  final String calculoGlobal;

  const _LoteDialog({this.lote, required this.calculoGlobal});

  @override
  State<_LoteDialog> createState() => _LoteDialogState();
}

class _LoteDialogState extends State<_LoteDialog> {
  final _formKey = GlobalKey<FormState>();

  final _numeroCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  bool _exclusivoMeEpp = false;

  List<EstimativaItem> _itens = [];

  @override
  void initState() {
    super.initState();
    if (widget.lote != null) {
      final l = widget.lote!;
      _numeroCtrl.text = l.numero.toString();
      _descricaoCtrl.text = l.descricao;
      _exclusivoMeEpp = l.exclusivoMeEpp;
      _itens = List.from(l.itens);
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final result = EstimativaLote(
      numero: int.tryParse(_numeroCtrl.text.trim()) ?? 0,
      descricao: _descricaoCtrl.text.trim(),
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
                          TextFormField(
                            controller: _numeroCtrl,
                            decoration: const InputDecoration(labelText: 'Lote Nº *'),
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descricaoCtrl,
                            decoration: const InputDecoration(labelText: 'Descrição *'),
                            maxLines: 2,
                            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                          ),

                          const Spacer(),
                          Card(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Valor de Referência TOTAL do Lote:'),
                                  Text(
                                    fmt.format(dummyLote.getValorTotal(widget.calculoGlobal)),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                            Text('Itens do Lote', style: Theme.of(context).textTheme.titleMedium),
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
                              ? const Center(child: Text('Nenhum item adicionado ao lote.'))
                              : ListView.builder(
                                  itemCount: _itens.length,
                                  itemBuilder: (context, index) {
                                    final item = _itens[index];
                                    final isMensal = item.tipoFornecimento == 'mensal';
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        dense: true,
                                        title: Text('Item ${item.numero} - ${item.descricao}'),
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
                                                message: 'Menos de 3 orçamentos',
                                                child: Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 16),
                                              onPressed: () => _editItem(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 16),
                                              color: Colors.red,
                                              onPressed: () => setState(() => _itens.removeAt(index)),
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
            )
          ],
        ),
      ),
    );
  }
}
