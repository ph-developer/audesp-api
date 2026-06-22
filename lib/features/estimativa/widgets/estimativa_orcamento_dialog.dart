import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../models/estimativa_orcamento_model.dart';

Future<EstimativaOrcamento?> showEstimativaOrcamentoDialog({
  required BuildContext context,
  EstimativaOrcamento? orcamento,
}) {
  return showDialog<EstimativaOrcamento>(
    context: context,
    builder: (ctx) => _OrcamentoDialog(orcamento: orcamento),
  );
}

class _OrcamentoDialog extends StatefulWidget {
  final EstimativaOrcamento? orcamento;

  const _OrcamentoDialog({this.orcamento});

  @override
  State<_OrcamentoDialog> createState() => _OrcamentoDialogState();
}

class _OrcamentoDialogState extends State<_OrcamentoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _razaoSocialCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  DateTime? _data;
  final _valorUnitarioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.orcamento != null) {
      _razaoSocialCtrl.text = widget.orcamento!.razaoSocial;
      _cnpjCtrl.text = widget.orcamento!.cnpj;
      if (widget.orcamento!.data.isNotEmpty) {
        try {
          _data = DateFormat('yyyy-MM-dd').parse(widget.orcamento!.data);
        } catch (_) {}
      }
      _valorUnitarioCtrl.text = NumberFormat.currency(locale: 'pt_BR', symbol: '').format(widget.orcamento!.valorUnitario);
    }
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _cnpjCtrl.dispose();
    _valorUnitarioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe a data do orçamento.')));
      return;
    }

    final valStr = _valorUnitarioCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(valStr) ?? 0.0;

    final result = EstimativaOrcamento(
      razaoSocial: _razaoSocialCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim(),
      data: DateFormat('yyyy-MM-dd').format(_data!),
      valorUnitario: valor,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.orcamento == null ? 'Novo Orçamento' : 'Editar Orçamento'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _razaoSocialCtrl,
                  decoration: const InputDecoration(labelText: 'Razão Social *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cnpjCtrl,
                  decoration: const InputDecoration(labelText: 'CNPJ *'),
                  keyboardType: TextInputType.number,
                  // TODO: Add CNPJ Mask Formatter if available
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                AudespDatePickerField(
                  label: 'Data do Orçamento *',
                  value: _data,
                  onChanged: (d) => setState(() => _data = d),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorUnitarioCtrl,
                  decoration: const InputDecoration(labelText: 'Valor Unitário *', prefixText: 'R\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
