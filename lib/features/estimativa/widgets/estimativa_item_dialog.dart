import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';

import '../../edital/domain/edital_domain.dart';

import '../models/estimativa_item_model.dart';
import '../models/estimativa_orcamento_model.dart';

Future<EstimativaItem?> showEstimativaItemDialog({
  required BuildContext context,
  EstimativaItem? item,
  required String estimativaTipo, // 'item' ou 'lote'
  required String calculoGlobal,
  int? nextNumero,
}) {
  return showDialog<EstimativaItem>(
    context: context,
    builder: (ctx) => _ItemDialog(
      item: item,
      estimativaTipo: estimativaTipo,
      calculoGlobal: calculoGlobal,
      nextNumero: nextNumero,
    ),
  );
}

class _ItemDialog extends StatefulWidget {
  final EstimativaItem? item;
  final String estimativaTipo;
  final String calculoGlobal;
  final int? nextNumero;

  const _ItemDialog({
    this.item,
    required this.estimativaTipo,
    required this.calculoGlobal,
    this.nextNumero,
  });

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
      _quantidadeCtrl.text = doubleToBrString(i.quantidade);
      _tipoFornecimento = i.tipoFornecimento;
      _materialOuServico = i.materialOuServico;
      _itemCategoriaId = i.itemCategoriaId;
      _quantidadeMesesCtrl.text = i.quantidadeMeses.toString();
      _exclusivoMeEpp = i.exclusivoMeEpp;
      _orcamentos = List.from(i.orcamentos);
    } else if (widget.nextNumero != null) {
      _numeroCtrl.text = widget.nextNumero.toString();
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
      quantidade:
          double.tryParse(_quantidadeCtrl.text.trim().replaceAll(',', '.')) ??
          0.0,
      tipoFornecimento: _tipoFornecimento,
      quantidadeMeses: _tipoFornecimento == 'mensal'
          ? (int.tryParse(_quantidadeMesesCtrl.text.trim()) ?? 12)
          : 1,
      materialOuServico: _materialOuServico,
      itemCategoriaId: _itemCategoriaId,
      exclusivoMeEpp: _exclusivoMeEpp,
      orcamentos: _orcamentos,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isMensal = _tipoFornecimento == 'mensal';
    final labelQtd = _tipoFornecimento == 'mensal'
        ? 'Quantidade Mensal *'
        : _tipoFornecimento == 'anual'
        ? 'Quantidade Anual *'
        : 'Quantidade *';

    return Dialog(
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.item == null
                  ? 'Novo Item ${widget.nextNumero != null ? '(nº ${widget.nextNumero})' : ''}'
                  : 'Editar Item nº ${widget.item!.numero}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AudespDropdown<String>(
                              label: 'Fornecimento *',
                              value: _tipoFornecimento,
                              items: const {
                                'unica': 'Compra Única',
                                'mensal': 'Mensal',
                                'anual': 'Anual',
                              },
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _tipoFornecimento = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AudespDropdown<String>(
                              label: 'Material/Serviço *',
                              value: _materialOuServico,
                              items: const {'M': 'Material', 'S': 'Serviço'},
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _materialOuServico = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AudespDropdown<int>(
                              label: 'Categoria do Item *',
                              value: _itemCategoriaId,
                              items: kItemCategoria,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _itemCategoriaId = v);
                                }
                              },
                              validator: (v) =>
                                  v == null ? 'Obrigatório' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AudespNumberField(
                              label: labelQtd,
                              controller: _quantidadeCtrl,
                              onChanged: (_) => setState(() {}),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AudespTextField(
                              label: 'Unidade *',
                              controller: _unidadeCtrl,
                              hintText: 'UN, M2...',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AudespNumberField(
                              label: 'Meses *',
                              controller: _quantidadeMesesCtrl,
                              enabled: isMensal,
                              decimals: false,
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  (isMensal && (v == null || v.isEmpty))
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AudespTextField(
                        label: 'Descrição *',
                        controller: _descricaoCtrl,
                        maxLines: 3,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Obrigatório' : null,
                      ),
                    ],
                  ),
                ),
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
            ),
          ],
        ),
      ),
    );
  }
}
