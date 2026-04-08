import 'package:fluent_ui/fluent_ui.dart';
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

  String? _validateForm() {
    final ni = _niCtrl.text.trim();
    if (ni.isEmpty || ni.length < 3) return 'NI obrigatório (mínimo 3 caracteres)';
    if (_tipoPessoa == 'PE' && _nomeCtrl.text.trim().length < 3) {
      return 'Nome/Razão Social obrigatório para pessoa estrangeira (mín. 3 caracteres)';
    }
    if (_declaracaoME == null) return 'Declaração ME/EPP obrigatória';
    if (_resultadoHabilitacao == null) return 'Resultado de Habilitação obrigatório';
    final v = _valorCtrl.text.trim();
    if (v.isNotEmpty && double.tryParse(v.replaceAll(',', '.')) == null) {
      return 'Valor inválido';
    }
    return null;
  }

  void _showError(String msg) {
    if (!mounted) return;
    displayInfoBar(context,
        builder: (ctx, close) => InfoBar(
              title: Text(msg),
              severity: InfoBarSeverity.error,
            ));
  }

  void _submit() {
    final error = _validateForm();
    if (error != null) {
      _showError(error);
      return;
    }
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
    final niLabel = _tipoPessoa == 'PJ'
        ? 'CNPJ *'
        : _tipoPessoa == 'PF'
            ? 'CPF *'
            : 'Identificação Estrangeira *';

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 500),
      title: Text(widget.initial == null ? 'Adicionar Licitante' : 'Editar Licitante'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoLabel(
              label: 'Tipo de Pessoa *',
              child: ComboBox<String>(
                value: _tipoPessoa,
                isExpanded: true,
                items: kTipoPessoa.entries
                    .map((e) => ComboBoxItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoPessoa = v!),
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: niLabel,
              child: TextBox(
                controller: _niCtrl,
                placeholder: '3 a 30 caracteres',
                maxLength: 30,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: _tipoPessoa == 'PE'
                  ? 'Nome/Razão Social *'
                  : 'Nome/Razão Social',
              child: TextBox(
                controller: _nomeCtrl,
                placeholder: '3 a 50 caracteres',
                maxLength: 50,
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Declaração ME/EPP *',
              child: ComboBox<int>(
                value: _declaracaoME,
                isExpanded: true,
                placeholder: const Text('Selecione'),
                items: kDeclaracaoMEouEPP.entries
                    .map((e) => ComboBoxItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _declaracaoME = v),
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Valor Proposto (R\$)',
              child: TextBox(
                controller: _valorCtrl,
                placeholder: 'Ex.: 12345.55',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Resultado de Habilitação *',
              child: ComboBox<int>(
                value: _resultadoHabilitacao,
                isExpanded: true,
                placeholder: const Text('Selecione'),
                items: kResultadoHabilitacao.entries
                    .map((e) => ComboBoxItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _resultadoHabilitacao = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
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
