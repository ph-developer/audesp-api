import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/edital_domain.dart';

/// Diálogo para adicionar ou editar uma Publicação do Edital.
///
/// Retorna um `Map<String,dynamic>` com os campos preenchidos,
/// ou null se o usuário cancelou.
Future<Map<String, dynamic>?> showPublicacaoDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
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
  final _dateCtrl = TextEditingController();
  final _pncpCtrl = TextEditingController();
  final _outrosCtrl = TextEditingController();

  int? _veiculo;

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      // Converte yyyy-MM-dd armazenado no JSON para dd/MM/yyyy (exibição).
      final raw = ini['dataPublicacao'] as String? ?? '';
      _dateCtrl.text = raw.isEmpty
          ? ''
          : DateFormat('dd/MM/yyyy')
              .format(DateFormat('yyyy-MM-dd').parse(raw));
      _veiculo = ini['veiculoPublicacao'] as int?;
      _pncpCtrl.text = ini['idContratacaoPNCP'] as String? ?? '';
      _outrosCtrl.text = ini['veiculoPublicacaoNome'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _pncpCtrl.dispose();
    _outrosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2099),
    );
    if (picked != null) {
      _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    // Converte dd/MM/yyyy de volta para yyyy-MM-dd antes de retornar.
    String apiDate = '';
    try {
      final d = DateFormat('dd/MM/yyyy').parse(_dateCtrl.text.trim());
      apiDate = DateFormat('yyyy-MM-dd').format(d);
    } catch (_) {
      apiDate = _dateCtrl.text.trim();
    }
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
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Data de publicação
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data de Publicação *',
                  hintText: 'dd/MM/yyyy',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
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
