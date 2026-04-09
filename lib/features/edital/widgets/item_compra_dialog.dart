import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/edital_domain.dart';

/// Diálogo para adicionar ou editar um Item de Compra do Edital.
///
/// Retorna um `Map<String,dynamic>` com os campos preenchidos,
/// ou null se o usuário cancelou.
Future<Map<String, dynamic>?> showItemCompraDialog(
  BuildContext context, {
  required int numero,
  Map<String, dynamic>? initial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _ItemCompraDialog(numero: numero, initial: initial),
  );
}

class _ItemCompraDialog extends StatefulWidget {
  final int numero;
  final Map<String, dynamic>? initial;
  const _ItemCompraDialog({required this.numero, this.initial});

  @override
  State<_ItemCompraDialog> createState() => _ItemCompraDialogState();
}

class _ItemCompraDialogState extends State<_ItemCompraDialog> {
  final _formKey = GlobalKey<FormState>();

  String _materialOuServico = 'M';
  int? _tipoBeneficio;
  bool _incentivoBasico = false;
  bool _orcamentoSigiloso = false;
  int? _criterioJulgamento;
  int? _itemCategoria;

  final _descCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController();
  final _valorUnitCtrl = TextEditingController();
  final _valorTotalCtrl = TextEditingController();
  final _patrimonioCtrl = TextEditingController();
  final _registroImobCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _materialOuServico = ini['materialOuServico'] as String? ?? 'M';
      _tipoBeneficio = ini['tipoBeneficioId'] as int?;
      _incentivoBasico = ini['incentivoProdutivoBasico'] as bool? ?? false;
      _orcamentoSigiloso = ini['orcamentoSigiloso'] as bool? ?? false;
      _criterioJulgamento = ini['criterioJulgamentoId'] as int?;
      _itemCategoria = ini['itemCategoriaId'] as int?;
      _descCtrl.text = ini['descricao'] as String? ?? '';
      _qtdCtrl.text = (ini['quantidade'] ?? '').toString();
      _unidadeCtrl.text = ini['unidadeMedida'] as String? ?? '';
      _valorUnitCtrl.text = (ini['valorUnitarioEstimado'] ?? '').toString();
      _valorTotalCtrl.text = (ini['valorTotal'] ?? '').toString();
      _patrimonioCtrl.text = ini['patrimonio'] as String? ?? '';
      _registroImobCtrl.text =
          ini['codigoRegistroImobiliario'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtdCtrl.dispose();
    _unidadeCtrl.dispose();
    _valorUnitCtrl.dispose();
    _valorTotalCtrl.dispose();
    _patrimonioCtrl.dispose();
    _registroImobCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final result = <String, dynamic>{
      'numeroItem': widget.numero,
      'materialOuServico': _materialOuServico,
      'tipoBeneficioId': _tipoBeneficio,
      'incentivoProdutivoBasico': _incentivoBasico,
      'descricao': _descCtrl.text.trim(),
      'quantidade': double.parse(
          (double.tryParse(_qtdCtrl.text.trim()) ?? 0).toStringAsFixed(4)),
      'unidadeMedida': _unidadeCtrl.text.trim(),
      'orcamentoSigiloso': _orcamentoSigiloso,
      'valorUnitarioEstimado': double.parse(
          (double.tryParse(_valorUnitCtrl.text.trim()) ?? 0)
              .toStringAsFixed(4)),
      'valorTotal': double.parse(
          (double.tryParse(_valorTotalCtrl.text.trim()) ?? 0)
              .toStringAsFixed(4)),
      'criterioJulgamentoId': _criterioJulgamento,
      'itemCategoriaId': _itemCategoria,
    };
    if (_patrimonioCtrl.text.trim().isNotEmpty) {
      result['patrimonio'] = _patrimonioCtrl.text.trim();
    }
    if (_registroImobCtrl.text.trim().isNotEmpty) {
      result['codigoRegistroImobiliario'] = _registroImobCtrl.text.trim();
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Item ${widget.numero}'),
      scrollable: true,
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material ou Serviço
              Row(
                children: [
                  const Text('Material ou Serviço *'),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'M', label: Text('Material')),
                      ButtonSegment(value: 'S', label: Text('Serviço')),
                    ],
                    selected: {_materialOuServico},
                    onSelectionChanged: (s) =>
                        setState(() => _materialOuServico = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tipo de Benefício
              DropdownButtonFormField<int>(
                key: ValueKey('ben_$_tipoBeneficio'),
                initialValue: _tipoBeneficio,
                decoration:
                    const InputDecoration(labelText: 'Tipo de Benefício *'),
                items: kTipoBeneficio.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoBeneficio = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 8),
              // Switches
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Incentivo Produtivo Básico (PPB)'),
                value: _incentivoBasico,
                onChanged: (v) => setState(() => _incentivoBasico = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Orçamento Sigiloso'),
                value: _orcamentoSigiloso,
                onChanged: (v) => setState(() => _orcamentoSigiloso = v),
              ),
              const SizedBox(height: 8),
              // Descrição
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  counterText: '',
                ),
                maxLength: 2048,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              // Quantidade + Unidade (em linha)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtdCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Quantidade *'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (double.tryParse(v) == null) return 'Número inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _unidadeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Unidade de Medida *',
                        counterText: '',
                      ),
                      maxLength: 30,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Valores
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valorUnitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Valor Unitário Est. *',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (double.tryParse(v) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _valorTotalCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Valor Total *',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (double.tryParse(v) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Critério de Julgamento
              DropdownButtonFormField<int>(
                key: ValueKey('crit_$_criterioJulgamento'),
                initialValue: _criterioJulgamento,
                decoration: const InputDecoration(
                    labelText: 'Critério de Julgamento *'),
                items: kCriterioJulgamento.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _criterioJulgamento = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              // Categoria do Item
              DropdownButtonFormField<int>(
                key: ValueKey('cat_$_itemCategoria'),
                initialValue: _itemCategoria,
                decoration:
                    const InputDecoration(labelText: 'Categoria do Item *'),
                items: kItemCategoria.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _itemCategoria = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              // Patrimônio (opcional)
              TextFormField(
                controller: _patrimonioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Patrimônio (facultativo)',
                  counterText: '',
                ),
                maxLength: 255,
              ),
              const SizedBox(height: 12),
              // Código de Registro Imobiliário (opcional)
              TextFormField(
                controller: _registroImobCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código de Registro Imobiliário (facultativo)',
                  counterText: '',
                ),
                maxLength: 255,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
