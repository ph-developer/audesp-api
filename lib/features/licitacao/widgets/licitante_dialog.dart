import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/licitacao_domain.dart';

/// Exibe o diálogo para adicionar ou editar um licitante dentro de um item.
///
/// Retorna o mapa do licitante ou null se cancelado.
Future<Map<String, dynamic>?> showLicitanteDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _LicitanteDialog(initial: initial),
  );
}

class _LicitanteDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _LicitanteDialog({this.initial});

  @override
  State<_LicitanteDialog> createState() => _LicitanteDialogState();
}

class _LicitanteDialogState extends State<_LicitanteDialog> {
  final _formKey = GlobalKey<FormState>();

  String _tipoPessoa = 'PJ';
  final _niCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  int? _declaracaoME;
  final _valorCtrl = TextEditingController();
  int? _resultadoHabilitacao;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      _tipoPessoa = d['tipoPessoaId'] as String? ?? 'PJ';
      _niCtrl.text = d['niPessoa'] as String? ?? '';
      _nomeCtrl.text = d['nomeRazaoSocial'] as String? ?? '';
      _declaracaoME = d['declaracaoMEouEPP'] as int?;
      _valorCtrl.text = d['valor']?.toString() ?? '';
      _resultadoHabilitacao = d['resultadoHabilitacao'] as int?;
    }
  }

  @override
  void dispose() {
    _niCtrl.dispose();
    _nomeCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final map = <String, dynamic>{
      'tipoPessoaId': _tipoPessoa,
      'niPessoa': _niCtrl.text.trim(),
      'declaracaoMEouEPP': _declaracaoME!,
      'resultadoHabilitacao': _resultadoHabilitacao!,
    };
    if (_nomeCtrl.text.trim().isNotEmpty) {
      map['nomeRazaoSocial'] = _nomeCtrl.text.trim();
    }
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    if (valor != null) map['valor'] = valor;
    Navigator.of(context).pop(map);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Adicionar Licitante' : 'Editar Licitante'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tipo de pessoa
                DropdownButtonFormField<String>(
                  value: _tipoPessoa,
                  decoration: const InputDecoration(labelText: 'Tipo de Pessoa *'),
                  items: kTipoPessoa.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoPessoa = v!),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                // NI (CPF/CNPJ/identificação estrangeira)
                TextFormField(
                  controller: _niCtrl,
                  decoration: InputDecoration(
                    labelText: _tipoPessoa == 'PJ'
                        ? 'CNPJ *'
                        : _tipoPessoa == 'PF'
                            ? 'CPF *'
                            : 'Identificação Estrangeira *',
                    hintText: '3 a 30 caracteres',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  maxLength: 30,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obrigatório';
                    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Nome/Razão Social (opcional para PJ/PF; obrigatório para PE)
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: InputDecoration(
                    labelText: _tipoPessoa == 'PE'
                        ? 'Nome/Razão Social *'
                        : 'Nome/Razão Social',
                    hintText: '3 a 50 caracteres',
                  ),
                  maxLength: 50,
                  validator: (v) {
                    if (_tipoPessoa == 'PE' && (v == null || v.trim().length < 3)) {
                      return 'Obrigatório para pessoa estrangeira (mín. 3 caracteres)';
                    }
                    if (v != null && v.trim().isNotEmpty && v.trim().length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Declaração ME/EPP
                DropdownButtonFormField<int>(
                  value: _declaracaoME,
                  decoration: const InputDecoration(labelText: 'Declaração ME/EPP *'),
                  items: kDeclaracaoMEouEPP.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _declaracaoME = v),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                // Valor proposto (opcional)
                TextFormField(
                  controller: _valorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Valor Proposto (R\$)',
                    hintText: 'Ex.: 12345.55',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                      if (parsed == null) return 'Valor inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Resultado de habilitação
                DropdownButtonFormField<int>(
                  value: _resultadoHabilitacao,
                  decoration: const InputDecoration(labelText: 'Resultado de Habilitação *'),
                  items: kResultadoHabilitacao.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _resultadoHabilitacao = v),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Adicionar' : 'Salvar'),
        ),
      ],
    );
  }
}
