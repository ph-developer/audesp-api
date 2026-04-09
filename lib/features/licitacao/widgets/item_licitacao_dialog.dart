import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../domain/licitacao_domain.dart';
import 'licitante_dialog.dart';

/// Exibe o diálogo para adicionar ou editar um item de licitação.
///
/// Retorna o mapa do item ou null se cancelado.
Future<Map<String, dynamic>?> showItemLicitacaoDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showAudespDialog<Map<String, dynamic>>(
    context: context,
    size: DialogSize.large,
    builder: (_) => _ItemLicitacaoDialog(initial: initial),
  );
}

class _ItemLicitacaoDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _ItemLicitacaoDialog({this.initial});

  @override
  State<_ItemLicitacaoDialog> createState() => _ItemLicitacaoDialogState();
}

class _ItemLicitacaoDialogState extends State<_ItemLicitacaoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _numeroItemCtrl = TextEditingController();
  int? _tipoOrcamento;
  final _valorCtrl = TextEditingController();
  DateTime? _dataOrcamento;
  int? _situacaoCompraItemId;
  DateTime? _dataSituacao;
  String? _tipoValor;
  int? _tipoProposta;

  List<Map<String, dynamic>> _licitantes = [];

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      _numeroItemCtrl.text = d['numeroItem']?.toString() ?? '';
      _tipoOrcamento = d['tipoOrcamento'] as int?;
      _valorCtrl.text = d['valor']?.toString() ?? '';
      _dataOrcamento = DateTime.tryParse(d['dataOrcamento'] as String? ?? '');
      _situacaoCompraItemId = d['situacaoCompraItemId'] != null
          ? (d['situacaoCompraItemId'] as num).toInt()
          : null;
      _dataSituacao = DateTime.tryParse(d['dataSituacaoItem'] as String? ?? '');
      _tipoValor = d['tipoValor'] as String?;
      _tipoProposta = d['tipoProposta'] != null
          ? (d['tipoProposta'] as num).toInt()
          : null;
      _licitantes = (d['licitantes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  @override
  void dispose() {
    _numeroItemCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  // ── Licitantes ────────────────────────────────────────────────────────────

  Future<void> _addLicitante() async {
    final result = await showLicitanteDialog(context);
    if (result != null) {
      setState(() => _licitantes.add(result));
    }
  }

  Future<void> _editLicitante(int index) async {
    final result = await showLicitanteDialog(context, initial: _licitantes[index]);
    if (result != null) {
      setState(() => _licitantes[index] = result);
    }
  }

  void _removeLicitante(int index) {
    setState(() => _licitantes.removeAt(index));
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_licitantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um licitante.')),
      );
      return;
    }
    final map = <String, dynamic>{
      'numeroItem': int.parse(_numeroItemCtrl.text.trim()),
      'tipoOrcamento': _tipoOrcamento!,
      'situacaoCompraItemId': _situacaoCompraItemId!,
      'dataSituacaoItem': _dataSituacao != null
          ? _dataSituacao!.toIso8601String().substring(0, 10)
          : '',
      'tipoValor': _tipoValor!,
      'tipoProposta': _tipoProposta!,
      'licitantes': _licitantes,
    };
    final valor = double.tryParse(_valorCtrl.text.trim().replaceAll(',', '.'));
    if (valor != null) map['valor'] = valor;
    if (_dataOrcamento != null) {
      map['dataOrcamento'] = _dataOrcamento!.toIso8601String().substring(0, 10);
    }
    Navigator.of(context).pop(map);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Adicionar Item' : 'Editar Item'),
      content: SizedBox(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dados do item ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _numeroItemCtrl,
                        decoration: const InputDecoration(labelText: 'Nº do Item *'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        initialValue: _tipoOrcamento,
                        decoration: const InputDecoration(labelText: 'Tipo de Orçamento *'),
                        items: kTipoOrcamento.entries
                            .map((e) =>
                                DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _tipoOrcamento = v),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valorCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Valor Médio dos Orçamentos (R\$)', hintText: 'Ex.: 12345.00'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                        ],
                        validator: (v) {
                          if (_tipoOrcamento != null &&
                              _tipoOrcamento != 0 &&
                              (v == null || v.trim().isEmpty)) {
                            return 'Obrigatório para o tipo de orçamento selecionado';
                          }
                          if (v != null && v.trim().isNotEmpty) {
                            if (double.tryParse(v.trim().replaceAll(',', '.')) == null) {
                              return 'Valor inválido';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AudespDatePickerField(
                        label: 'Data do Orçamento',
                        value: _dataOrcamento,
                        onChanged: (d) => setState(() => _dataOrcamento = d),
                        validator: (d) {
                          if (_tipoOrcamento != null &&
                              _tipoOrcamento != 0 &&
                              d == null) {
                            return 'Obrigatória para o tipo de orçamento selecionado';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _situacaoCompraItemId,
                        decoration:
                            const InputDecoration(labelText: 'Situação do Item *'),
                        items: kSituacaoCompraItem.entries
                            .map((e) =>
                                DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _situacaoCompraItemId = v),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AudespDatePickerField(
                        label: 'Data da Situação *',
                        value: _dataSituacao,
                        onChanged: (d) => setState(() => _dataSituacao = d),
                        validator: (d) => d == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoValor,
                        decoration: const InputDecoration(labelText: 'Tipo de Valor *'),
                        items: kTipoValor.entries
                            .map((e) =>
                                DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _tipoValor = v),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        initialValue: _tipoProposta,
                        decoration: const InputDecoration(labelText: 'Tipo de Proposta *'),
                        items: kTipoProposta.entries
                            .map((e) =>
                                DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _tipoProposta = v),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Licitantes ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Licitantes (${_licitantes.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Adicionar'),
                      onPressed: _addLicitante,
                    ),
                  ],
                ),
                if (_licitantes.isNotEmpty)
                  ...List.generate(_licitantes.length, (i) {
                    final l = _licitantes[i];
                    final tipo = l['tipoPessoaId'] as String? ?? '';
                    final ni = l['niPessoa'] as String? ?? '';
                    final nome = l['nomeRazaoSocial'] as String? ?? '';
                    final resultado = l['resultadoHabilitacao'] as int?;
                    return Card(
                      margin: const EdgeInsets.only(top: 4),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(tipo, style: const TextStyle(fontSize: 9)),
                        ),
                        title: Text(nome.isNotEmpty ? nome : ni),
                        subtitle: Text(
                          '${tipo != 'PE' ? ni : ''}  ${resultado != null ? kResultadoHabilitacao[resultado] ?? '' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              onPressed: () => _editLicitante(i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              onPressed: () => _removeLicitante(i),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Nenhum licitante adicionado.',
                      textAlign: TextAlign.center,
                    ),
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
          child: Text(widget.initial == null ? 'Adicionar Item' : 'Salvar Item'),
        ),
      ],
    );
  }
}
