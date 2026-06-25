import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../models/estimativa_fornecedor_model.dart';

enum FornecedorDialogAction { cancel, delete }

class FornecedorDialogResult {
  final EstimativaFornecedor? fornecedor;
  final FornecedorDialogAction? action;

  const FornecedorDialogResult.save(this.fornecedor) : action = null;
  const FornecedorDialogResult(this.action) : fornecedor = null;

  bool get isCancel => action == FornecedorDialogAction.cancel;
  bool get isDelete => action == FornecedorDialogAction.delete;
  bool get isSave => fornecedor != null;
}

Future<FornecedorDialogResult?> showEstimativaFornecedorDialog({
  required BuildContext context,
  EstimativaFornecedor? fornecedor,
}) {
  return showDialog<FornecedorDialogResult>(
    context: context,
    builder: (ctx) => _FornecedorDialog(fornecedor: fornecedor),
  );
}

class _FornecedorDialog extends StatefulWidget {
  final EstimativaFornecedor? fornecedor;

  const _FornecedorDialog({this.fornecedor});

  @override
  State<_FornecedorDialog> createState() => _FornecedorDialogState();
}

class _FornecedorDialogState extends State<_FornecedorDialog> {
  late final TextEditingController _razaoSocialCtrl;
  late final TextEditingController _cnpjCtrl;
  DateTime? _data;

  @override
  void initState() {
    super.initState();
    _razaoSocialCtrl = TextEditingController(
      text: widget.fornecedor?.razaoSocial,
    );
    _cnpjCtrl = TextEditingController(text: widget.fornecedor?.cnpj);
    if (widget.fornecedor?.data != null &&
        widget.fornecedor!.data.isNotEmpty) {
      try {
        _data = DateFormat('dd/MM/yyyy').parse(widget.fornecedor!.data);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _cnpjCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.fornecedor != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Fornecedor' : 'Incluir Fornecedor'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AudespTextField(
              label: 'Razão Social',
              controller: _razaoSocialCtrl,
            ),
            const SizedBox(height: 12),
            AudespCpfCnpjField(
              label: 'CPF/CNPJ (apenas números)',
              controller: _cnpjCtrl,
            ),
            const SizedBox(height: 12),
            AudespDatePickerField(
              label: 'Data do Orçamento',
              value: _data,
              onChanged: (d) => setState(() => _data = d),
            ),
          ],
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const FornecedorDialogResult(FornecedorDialogAction.delete),
            ),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const FornecedorDialogResult(FornecedorDialogAction.cancel),
          ),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }

  void _save() {
    if (_razaoSocialCtrl.text.trim().isEmpty) return;

    final result = EstimativaFornecedor(
      id: widget.fornecedor?.id,
      razaoSocial: _razaoSocialCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim(),
      data: _data != null ? DateFormat('dd/MM/yyyy').format(_data!) : '',
    );
    Navigator.pop(context, FornecedorDialogResult.save(result));
  }
}
