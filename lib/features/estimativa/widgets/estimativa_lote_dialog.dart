import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';

import '../../edital/domain/edital_domain.dart';
import '../models/estimativa_lote_model.dart';
import '../models/estimativa_item_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.lote == null ? 'Novo Lote' : 'Editar Lote',
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
                              textCapitalization: TextCapitalization.characters,
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
