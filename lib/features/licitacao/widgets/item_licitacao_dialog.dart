import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../domain/licitacao_domain.dart';
import 'licitante_dialog.dart';

/// Exibe o diálogo para adicionar ou editar um item de licitação.
///
/// Retorna o mapa do item ou null se cancelado.
Future<Map<String, dynamic>?> showItemLicitacaoDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
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
      final dataOrca = d['dataOrcamento'] as String?;
      if (dataOrca != null && dataOrca.isNotEmpty) {
        try {
          _dataOrcamento = DateFormat('yyyy-MM-dd').parse(dataOrca);
        } catch (_) {}
      }
      _situacaoCompraItemId = d['situacaoCompraItemId'] != null
          ? (d['situacaoCompraItemId'] as num).toInt()
          : null;
      final dataSit = d['dataSituacaoItem'] as String?;
      if (dataSit != null && dataSit.isNotEmpty) {
        try {
          _dataSituacao = DateFormat('yyyy-MM-dd').parse(dataSit);
        } catch (_) {}
      }
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

  // ── Validation ───────────────────────────────────────────────────────────

  String? _validateForm() {
    if (_numeroItemCtrl.text.trim().isEmpty) return 'Nº do Item obrigatório';
    if (_tipoOrcamento == null) return 'Tipo de Orçamento obrigatório';
    if (_situacaoCompraItemId == null) return 'Situação do Item obrigatória';
    if (_dataSituacao == null) return 'Data da Situação obrigatória';
    if (_tipoValor == null) return 'Tipo de Valor obrigatório';
    if (_tipoProposta == null) return 'Tipo de Proposta obrigatório';
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

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    final error = _validateForm();
    if (error != null) {
      _showError(error);
      return;
    }
    if (_licitantes.isEmpty) {
      _showError('Adicione pelo menos um licitante.');
      return;
    }
    final map = <String, dynamic>{
      'numeroItem': int.parse(_numeroItemCtrl.text.trim()),
      'tipoOrcamento': _tipoOrcamento!,
      'situacaoCompraItemId': _situacaoCompraItemId!,
      'dataSituacaoItem': DateFormat('yyyy-MM-dd').format(_dataSituacao!),
      'tipoValor': _tipoValor!,
      'tipoProposta': _tipoProposta!,
      'licitantes': _licitantes,
    };
    final valor = double.tryParse(_valorCtrl.text.trim().replaceAll(',', '.'));
    if (valor != null) map['valor'] = valor;
    if (_dataOrcamento != null) {
      map['dataOrcamento'] = DateFormat('yyyy-MM-dd').format(_dataOrcamento!);
    }
    Navigator.of(context).pop(map);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600),
      title: Text(widget.initial == null ? 'Adicionar Item' : 'Editar Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dados do item ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: InfoLabel(
                    label: 'Nº do Item *',
                    child: TextBox(
                      controller: _numeroItemCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: InfoLabel(
                    label: 'Tipo de Orçamento *',
                    child: ComboBox<int>(
                      value: _tipoOrcamento,
                      isExpanded: true,
                      placeholder: const Text('Selecione'),
                      items: kTipoOrcamento.entries
                          .map((e) =>
                              ComboBoxItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _tipoOrcamento = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: InfoLabel(
                    label: 'Valor (R\$)',
                    child: TextBox(
                      controller: _valorCtrl,
                      placeholder: 'Ex.: 12345.00',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoLabel(
                    label: 'Data do Orçamento',
                    child: DatePicker(
                      selected: _dataOrcamento,
                      onChanged: (v) => setState(() => _dataOrcamento = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: InfoLabel(
                    label: 'Situação do Item *',
                    child: ComboBox<int>(
                      value: _situacaoCompraItemId,
                      isExpanded: true,
                      placeholder: const Text('Selecione'),
                      items: kSituacaoCompraItem.entries
                          .map((e) =>
                              ComboBoxItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _situacaoCompraItemId = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InfoLabel(
                    label: 'Data da Situação *',
                    child: DatePicker(
                      selected: _dataSituacao,
                      onChanged: (v) => setState(() => _dataSituacao = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: InfoLabel(
                    label: 'Tipo de Valor *',
                    child: ComboBox<String>(
                      value: _tipoValor,
                      isExpanded: true,
                      placeholder: const Text('Selecione'),
                      items: kTipoValor.entries
                          .map((e) =>
                              ComboBoxItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _tipoValor = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoLabel(
                    label: 'Tipo de Proposta *',
                    child: ComboBox<int>(
                      value: _tipoProposta,
                      isExpanded: true,
                      placeholder: const Text('Selecione'),
                      items: kTipoProposta.entries
                          .map((e) =>
                              ComboBoxItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _tipoProposta = v),
                    ),
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
                  style: theme.typography.bodyStrong,
                ),
                Button(
                  onPressed: _addLicitante,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.add, size: 12),
                      SizedBox(width: 6),
                      Text('Adicionar'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_licitantes.isNotEmpty)
              ...List.generate(_licitantes.length, (i) {
                final l = _licitantes[i];
                final tipo = l['tipoPessoaId'] as String? ?? '';
                final ni = l['niPessoa'] as String? ?? '';
                final nome = l['nomeRazaoSocial'] as String? ?? '';
                final resultado = l['resultadoHabilitacao'] as int?;
                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.resources.controlFillColorDefault,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.accentColor.lighter,
                        ),
                        alignment: Alignment.center,
                        child: Text(tipo,
                            style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nome.isNotEmpty ? nome : ni,
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              '${tipo != 'PE' ? ni : ''}  ${resultado != null ? kResultadoHabilitacao[resultado] ?? '' : ''}'
                                  .trim(),
                              style: theme.typography.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(FluentIcons.edit, size: 14),
                        onPressed: () => _editLicitante(i),
                      ),
                      IconButton(
                        icon: const Icon(FluentIcons.delete, size: 14),
                        onPressed: () => _removeLicitante(i),
                      ),
                    ],
                  ),
                );
              })
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.resources.controlFillColorDefault,
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
      actions: [
        Button(
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
