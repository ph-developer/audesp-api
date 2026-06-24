import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  late final TextEditingController _dataCtrl;

  @override
  void initState() {
    super.initState();
    _razaoSocialCtrl = TextEditingController(
      text: widget.fornecedor?.razaoSocial,
    );
    _cnpjCtrl = TextEditingController(text: widget.fornecedor?.cnpj);
    _dataCtrl = TextEditingController(text: widget.fornecedor?.data);
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _cnpjCtrl.dispose();
    _dataCtrl.dispose();
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
            TextField(
              controller: _razaoSocialCtrl,
              decoration: const InputDecoration(labelText: 'Razão Social'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cnpjCtrl,
              decoration: const InputDecoration(
                labelText: 'CPF/CNPJ (apenas números)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dataCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Data do Orçamento',
                hintText: 'DD/MM/AAAA',
                suffixIcon: Icon(Icons.calendar_today),
              ),
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

  Future<void> _pickDate() async {
    DateTime initialDate = DateTime.now();
    try {
      if (_dataCtrl.text.isNotEmpty) {
        initialDate = DateFormat('dd/MM/yyyy').parseLoose(_dataCtrl.text);
      }
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dataCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _save() {
    if (_razaoSocialCtrl.text.trim().isEmpty) return;

    final result = EstimativaFornecedor(
      id: widget.fornecedor?.id,
      razaoSocial: _razaoSocialCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim(),
      data: _dataCtrl.text.trim(),
    );
    Navigator.pop(context, FornecedorDialogResult.save(result));
  }
}
