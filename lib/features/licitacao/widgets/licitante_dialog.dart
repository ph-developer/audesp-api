import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../domain/licitacao_domain.dart';

/// Exibe o diálogo para adicionar ou editar um licitante dentro de um item.
///
/// Retorna o mapa do licitante ou null se cancelado.
Future<Map<String, dynamic>?> showLicitanteDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showAudespDialog<Map<String, dynamic>>(
    context: context,
    size: DialogSize.medium,
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
      _valorCtrl.text = doubleToBrString(d['valor']);
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
      'niPessoa': _niCtrl.text.replaceAll(RegExp(r'\D'), ''),
      'declaracaoMEouEPP': _declaracaoME!,
      'resultadoHabilitacao': _resultadoHabilitacao!,
    };
    if (_nomeCtrl.text.trim().isNotEmpty) {
      map['nomeRazaoSocial'] = _nomeCtrl.text.trim();
    }
    final valor = parseBrCurrencyOrNull(_valorCtrl.text);
    if (valor != null) {
      map['valor'] = double.parse(valor.toStringAsFixed(4));
    }
    Navigator.of(context).pop(map);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Adicionar Licitante' : 'Editar Licitante',
      ),
      content: SizedBox(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tipo de pessoa
                AudespDropdown<String>(
                  label: 'Tipo de Pessoa *',
                  value: _tipoPessoa,
                  items: kTipoPessoa,
                  onChanged: (v) => setState(() => _tipoPessoa = v!),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                // NI (CPF/CNPJ/identificação estrangeira)
                AudespTextField(
                  label: _tipoPessoa == 'PJ'
                      ? 'CNPJ *'
                      : _tipoPessoa == 'PF'
                      ? 'CPF *'
                      : 'Identificação Estrangeira *',
                  controller: _niCtrl,
                  hintText: '3 a 30 caracteres',
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
                AudespTextField(
                  label: _tipoPessoa == 'PE'
                      ? 'Nome/Razão Social *'
                      : 'Nome/Razão Social',
                  controller: _nomeCtrl,
                  hintText: '3 a 50 caracteres',
                  maxLength: 50,
                  validator: (v) {
                    if (_tipoPessoa == 'PE' &&
                        (v == null || v.trim().length < 3)) {
                      return 'Obrigatório para pessoa estrangeira (mín. 3 caracteres)';
                    }
                    if (v != null &&
                        v.trim().isNotEmpty &&
                        v.trim().length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Declaração ME/EPP
                AudespDropdown<int>(
                  label: 'Declaração ME/EPP *',
                  value: _declaracaoME,
                  items: kDeclaracaoMEouEPP,
                  onChanged: (v) => setState(() => _declaracaoME = v),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                // Valor proposto (obrigatório para habilitados 1 e 2)
                AudespNumberField(
                  label:
                      (_resultadoHabilitacao == 1 || _resultadoHabilitacao == 2)
                      ? 'Valor Proposto (R\$) *'
                      : 'Valor Proposto (R\$)',
                  controller: _valorCtrl,
                  hintText: 'Ex.: 12345.55',
                  validator: (v) {
                    if ((_resultadoHabilitacao == 1 ||
                            _resultadoHabilitacao == 2) &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Obrigatório para classificados (resultado 1 ou 2)';
                    }
                    if (v != null && v.trim().isNotEmpty) {
                      final parsed = parseBrCurrencyOrNull(v.trim());
                      if (parsed == null) return 'Valor inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Resultado de habilitação
                AudespDropdown<int>(
                  label: 'Resultado de Habilitação *',
                  value: _resultadoHabilitacao,
                  items: kResultadoHabilitacao,
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
