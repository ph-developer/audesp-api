import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../edital/domain/edital_domain.dart';

import '../models/estimativa_item_model.dart';
import '../models/estimativa_orcamento_model.dart';
import 'estimativa_orcamento_dialog.dart';

Future<EstimativaItem?> showEstimativaItemDialog({
  required BuildContext context,
  EstimativaItem? item,
  required String estimativaTipo, // 'item' ou 'lote'
  required String calculoGlobal,
}) {
  return showDialog<EstimativaItem>(
    context: context,
    builder: (ctx) => _ItemDialog(item: item, estimativaTipo: estimativaTipo, calculoGlobal: calculoGlobal),
  );
}

class _ItemDialog extends StatefulWidget {
  final EstimativaItem? item;
  final String estimativaTipo;
  final String calculoGlobal;

  const _ItemDialog({this.item, required this.estimativaTipo, required this.calculoGlobal});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final _numeroCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController();
  final _quantidadeCtrl = TextEditingController();
  final _quantidadeMesesCtrl = TextEditingController();

  String _tipoFornecimento = 'unica';
  String _materialOuServico = 'M';
  int? _itemCategoriaId;
  bool _exclusivoMeEpp = false;

  List<EstimativaOrcamento> _orcamentos = [];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final i = widget.item!;
      _numeroCtrl.text = i.numero.toString();
      _descricaoCtrl.text = i.descricao;
      _unidadeCtrl.text = i.unidade;
      _quantidadeCtrl.text = i.quantidade.toString();
      _tipoFornecimento = i.tipoFornecimento;
      _materialOuServico = i.materialOuServico;
      _itemCategoriaId = i.itemCategoriaId;
      _quantidadeMesesCtrl.text = i.quantidadeMeses.toString();
      _exclusivoMeEpp = i.exclusivoMeEpp;
      _orcamentos = List.from(i.orcamentos);
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _descricaoCtrl.dispose();
    _unidadeCtrl.dispose();
    _quantidadeCtrl.dispose();
    _quantidadeMesesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final result = EstimativaItem(
      numero: int.tryParse(_numeroCtrl.text.trim()) ?? 0,
      descricao: _descricaoCtrl.text.trim(),
      unidade: _unidadeCtrl.text.trim(),
      quantidade: double.tryParse(_quantidadeCtrl.text.trim().replaceAll(',', '.')) ?? 0.0,
      tipoFornecimento: _tipoFornecimento,
      quantidadeMeses: int.tryParse(_quantidadeMesesCtrl.text.trim()) ?? 1,
      materialOuServico: _materialOuServico,
      itemCategoriaId: _itemCategoriaId,
      exclusivoMeEpp: _exclusivoMeEpp,
      orcamentos: _orcamentos,
    );

    Navigator.pop(context, result);
  }

  Future<void> _addOrcamento() async {
    final res = await showEstimativaOrcamentoDialog(context: context);
    if (res != null) {
      setState(() {
        _orcamentos.add(res);
      });
    }
  }

  Future<void> _editOrcamento(int index) async {
    final res = await showEstimativaOrcamentoDialog(context: context, orcamento: _orcamentos[index]);
    if (res != null) {
      setState(() {
        _orcamentos[index] = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMensal = _tipoFornecimento == 'mensal';
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    // Calcula na hora para visualização
    final dummyItem = EstimativaItem(
      numero: 0,
      descricao: '',
      unidade: '',
      quantidade: double.tryParse(_quantidadeCtrl.text.trim().replaceAll(',', '.')) ?? 0.0,
      tipoFornecimento: _tipoFornecimento,
      quantidadeMeses: int.tryParse(_quantidadeMesesCtrl.text.trim()) ?? 1,
      orcamentos: _orcamentos,
    );

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              widget.item == null ? 'Novo Item' : 'Editar Item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado Esquerdo: Formulário
                  Expanded(
                    flex: 1,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _numeroCtrl,
                                    decoration: const InputDecoration(labelText: 'Item Nº *'),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _descricaoCtrl,
                                    decoration: const InputDecoration(labelText: 'Descrição *'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _unidadeCtrl,
                                    decoration: const InputDecoration(labelText: 'Unidade *', hintText: 'UN, M2, KG...'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _tipoFornecimento,
                                    decoration: const InputDecoration(labelText: 'Fornecimento *'),
                                    items: const [
                                      DropdownMenuItem(value: 'unica', child: Text('Compra Única')),
                                      DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setState(() => _tipoFornecimento = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantidadeCtrl,
                                    decoration: InputDecoration(
                                      labelText: isMensal ? 'Qtd (Mensal) *' : 'Quantidade *',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (_) => setState((){}),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantidadeMesesCtrl,
                                    enabled: isMensal,
                                    decoration: const InputDecoration(labelText: 'Meses *'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState((){}),
                                    validator: (v) => (isMensal && (v == null || v.isEmpty)) ? 'Obrigatório' : null,
                                  ),
                                ),
                              ],
                            ),

                            if (widget.estimativaTipo == 'item') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _materialOuServico,
                                      decoration: const InputDecoration(labelText: 'Material/Serviço *'),
                                      items: const [
                                        DropdownMenuItem(value: 'M', child: Text('Material')),
                                        DropdownMenuItem(value: 'S', child: Text('Serviço')),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) setState(() => _materialOuServico = v);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _itemCategoriaId,
                                      decoration: const InputDecoration(labelText: 'Categoria do Item *'),
                                      items: kItemCategoria.entries.map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      )).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _itemCategoriaId = v);
                                      },
                                      validator: (v) => v == null ? 'Obrigatório' : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),
                            Card(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('V. Referência Unitário:'),
                                        Text(fmt.format(dummyItem.getValorReferenciaUnitario(widget.calculoGlobal))),
                                      ],
                                    ),
                                    if (isMensal)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('V. Referência Mensal:'),
                                          Text(fmt.format(dummyItem.getValorMensal(widget.calculoGlobal))),
                                        ],
                                      ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('V. Referência TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(fmt.format(dummyItem.getValorTotal(widget.calculoGlobal)), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Lado Direito: Orçamentos
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Orçamentos', style: Theme.of(context).textTheme.titleMedium),
                            TextButton.icon(
                              onPressed: _addOrcamento,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Adicionar'),
                            ),
                          ],
                        ),
                        if (_orcamentos.length < 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: Colors.amber.shade100,
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('Menos de 3 orçamentos cadastrados.', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        const Divider(),
                        Expanded(
                          child: _orcamentos.isEmpty
                              ? const Center(child: Text('Nenhum orçamento adicionado.'))
                              : ListView.builder(
                                  itemCount: _orcamentos.length,
                                  itemBuilder: (context, index) {
                                    final o = _orcamentos[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        dense: true,
                                        title: Text(o.razaoSocial),
                                        subtitle: Text('${o.cnpj}  |  ${fmt.format(o.valorUnitario)}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 16),
                                              onPressed: () => _editOrcamento(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 16),
                                              color: Colors.red,
                                              onPressed: () => setState(() => _orcamentos.removeAt(index)),
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
                  child: const Text('Salvar Item'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
