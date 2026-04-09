import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../domain/edital_domain.dart';

/// Diálogo para adicionar ou editar uma Publicação do Edital.
///
/// Retorna um `Map<String,dynamic>` com os campos preenchidos,
/// ou null se o usuário cancelou.
Future<Map<String, dynamic>?> showPublicacaoDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showAudespDialog<Map<String, dynamic>>(
    context: context,
    size: DialogSize.medium,
    builder: (_) => _PublicacaoDialog(initial: initial),
  );
}

class _PublicacaoDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _PublicacaoDialog({this.initial});

  @override
  State<_PublicacaoDialog> createState() => _PublicacaoDialogState();
}

class _PublicacaoDialogState extends State<_PublicacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pncpCtrl = TextEditingController();
  final _outrosCtrl = TextEditingController();

  DateTime? _date;
  int? _veiculo;

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      final raw = ini['dataPublicacao'] as String? ?? '';
      _date = raw.isNotEmpty ? DateTime.tryParse(raw) : null;
      _veiculo = ini['veiculoPublicacao'] as int?;
      _pncpCtrl.text = ini['idContratacaoPNCP'] as String? ?? '';
      _outrosCtrl.text = ini['veiculoPublicacaoNome'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _pncpCtrl.dispose();
    _outrosCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final apiDate = _date != null ? _date!.toIso8601String().substring(0, 10) : '';
    final result = <String, dynamic>{
      'dataPublicacao': apiDate,
      'veiculoPublicacao': _veiculo,
    };
    if (_veiculo == 5) {
      result['idContratacaoPNCP'] = _pncpCtrl.text.trim();
    }
    if (_veiculo == 10) {
      result['veiculoPublicacaoNome'] = _outrosCtrl.text.trim();
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.initial == null ? 'Adicionar Publicação' : 'Editar Publicação'),
      content: SizedBox(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Data de publicação
              AudespDatePickerField(
                label: 'Data de Publicação *',
                value: _date,
                onChanged: (d) => setState(() => _date = d),
                validator: (d) => d == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              // Veículo de publicação
              DropdownButtonFormField<int>(
                key: ValueKey('veic_$_veiculo'),
                initialValue: _veiculo,
                decoration: const InputDecoration(
                    labelText: 'Veículo de Publicação *'),
                items: kVeiculosPublicacao.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _veiculo = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              // PNCP id (se veiculo = 5)
              if (_veiculo == 5) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pncpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID Contratação PNCP *',
                    hintText: '25 dígitos numéricos',
                    counterText: '',
                  ),
                  maxLength: 25,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (!RegExp(r'^[0-9]{25}$').hasMatch(v)) {
                      return 'Deve ter exatamente 25 dígitos numéricos';
                    }
                    return null;
                  },
                ),
              ],
              // Nome do veículo (se veiculo = 10)
              if (_veiculo == 10) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _outrosCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Veículo *',
                    counterText: '',
                  ),
                  maxLength: 100,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
              ],
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
