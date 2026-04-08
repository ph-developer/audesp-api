import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../domain/edital_domain.dart';

/// Diálogo para adicionar ou editar um Item de Compra do Edital.
///
/// Retorna um `Map<String,dynamic>` com os campos preenchidos,
/// ou null se o usuário cancelou.
Future<Map<String, dynamic>?> showItemCompraDialog(
  BuildContext context, {
  required int numero,
  Map<String, dynamic>? initial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _ItemCompraDialog(numero: numero, initial: initial),
  );
}

class _ItemCompraDialog extends StatefulWidget {
  final int numero;
  final Map<String, dynamic>? initial;
  const _ItemCompraDialog({required this.numero, this.initial});

  @override
  State<_ItemCompraDialog> createState() => _ItemCompraDialogState();
}

class _ItemCompraDialogState extends State<_ItemCompraDialog> {
  String _materialOuServico = 'M';
  int? _tipoBeneficio;
  bool _incentivoBasico = false;
  bool _orcamentoSigiloso = false;
  int? _criterioJulgamento;
  int? _itemCategoria;

  final _descCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController();
  final _valorUnitCtrl = TextEditingController();
  final _valorTotalCtrl = TextEditingController();
  final _patrimonioCtrl = TextEditingController();
  final _registroImobCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _materialOuServico = ini['materialOuServico'] as String? ?? 'M';
      _tipoBeneficio = ini['tipoBeneficioId'] as int?;
      _incentivoBasico = ini['incentivoProdutivoBasico'] as bool? ?? false;
      _orcamentoSigiloso = ini['orcamentoSigiloso'] as bool? ?? false;
      _criterioJulgamento = ini['criterioJulgamentoId'] as int?;
      _itemCategoria = ini['itemCategoriaId'] as int?;
      _descCtrl.text = ini['descricao'] as String? ?? '';
      _qtdCtrl.text = (ini['quantidade'] ?? '').toString();
      _unidadeCtrl.text = ini['unidadeMedida'] as String? ?? '';
      _valorUnitCtrl.text = (ini['valorUnitarioEstimado'] ?? '').toString();
      _valorTotalCtrl.text = (ini['valorTotal'] ?? '').toString();
      _patrimonioCtrl.text = ini['patrimonio'] as String? ?? '';
      _registroImobCtrl.text =
          ini['codigoRegistroImobiliario'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtdCtrl.dispose();
    _unidadeCtrl.dispose();
    _valorUnitCtrl.dispose();
    _valorTotalCtrl.dispose();
    _patrimonioCtrl.dispose();
    _registroImobCtrl.dispose();
    super.dispose();
  }

  String? _validateForm() {
    if (_tipoBeneficio == null) return 'Tipo de Benefício é obrigatório.';
    if (_descCtrl.text.trim().isEmpty) return 'Descrição é obrigatória.';
    if (_qtdCtrl.text.trim().isEmpty ||
        double.tryParse(_qtdCtrl.text.trim()) == null) {
      return 'Quantidade inválida.';
    }
    if (_unidadeCtrl.text.trim().isEmpty) {
      return 'Unidade de Medida é obrigatória.';
    }
    if (_valorUnitCtrl.text.trim().isEmpty ||
        double.tryParse(_valorUnitCtrl.text.trim()) == null) {
      return 'Valor Unitário inválido.';
    }
    if (_valorTotalCtrl.text.trim().isEmpty ||
        double.tryParse(_valorTotalCtrl.text.trim()) == null) {
      return 'Valor Total inválido.';
    }
    if (_criterioJulgamento == null) {
      return 'Critério de Julgamento é obrigatório.';
    }
    if (_itemCategoria == null) return 'Categoria do Item é obrigatória.';
    return null;
  }

  void _confirm() {
    final err = _validateForm();
    if (err != null) {
      displayInfoBar(context,
          builder: (ctx, close) =>
              InfoBar(title: Text(err), severity: InfoBarSeverity.error));
      return;
    }
    final result = <String, dynamic>{
      'numeroItem': widget.numero,
      'materialOuServico': _materialOuServico,
      'tipoBeneficioId': _tipoBeneficio,
      'incentivoProdutivoBasico': _incentivoBasico,
      'descricao': _descCtrl.text.trim(),
      'quantidade': double.tryParse(_qtdCtrl.text.trim()) ?? 0,
      'unidadeMedida': _unidadeCtrl.text.trim(),
      'orcamentoSigiloso': _orcamentoSigiloso,
      'valorUnitarioEstimado':
          double.tryParse(_valorUnitCtrl.text.trim()) ?? 0,
      'valorTotal': double.tryParse(_valorTotalCtrl.text.trim()) ?? 0,
      'criterioJulgamentoId': _criterioJulgamento,
      'itemCategoriaId': _itemCategoria,
    };
    if (_patrimonioCtrl.text.trim().isNotEmpty) {
      result['patrimonio'] = _patrimonioCtrl.text.trim();
    }
    if (_registroImobCtrl.text.trim().isNotEmpty) {
      result['codigoRegistroImobiliario'] = _registroImobCtrl.text.trim();
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('Item ${widget.numero}'),
      constraints: const BoxConstraints(maxWidth: 600),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material ou Serviço
            const Text('Material ou Serviço *'),
            const SizedBox(height: 6),
            Row(
              children: [
                _materialOuServico == 'M'
                    ? FilledButton(
                        onPressed: null,
                        child: const Text('Material'),
                      )
                    : Button(
                        onPressed: () =>
                            setState(() => _materialOuServico = 'M'),
                        child: const Text('Material'),
                      ),
                const SizedBox(width: 8),
                _materialOuServico == 'S'
                    ? FilledButton(
                        onPressed: null,
                        child: const Text('Serviço'),
                      )
                    : Button(
                        onPressed: () =>
                            setState(() => _materialOuServico = 'S'),
                        child: const Text('Serviço'),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            // Tipo de Benefício
            InfoLabel(
              label: 'Tipo de Benefício *',
              child: ComboBox<int>(
                value: _tipoBeneficio,
                placeholder: const Text('Selecione...'),
                isExpanded: true,
                items: kTipoBeneficio.entries
                    .map((e) =>
                        ComboBoxItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoBeneficio = v),
              ),
            ),
            const SizedBox(height: 8),
            // Switches
            ToggleSwitch(
              checked: _incentivoBasico,
              onChanged: (v) => setState(() => _incentivoBasico = v),
              content: const Text('Incentivo Produtivo Básico (PPB)'),
            ),
            const SizedBox(height: 6),
            ToggleSwitch(
              checked: _orcamentoSigiloso,
              onChanged: (v) => setState(() => _orcamentoSigiloso = v),
              content: const Text('Orçamento Sigiloso'),
            ),
            const SizedBox(height: 12),
            // Descrição
            InfoLabel(
              label: 'Descrição *',
              child: TextBox(
                controller: _descCtrl,
                maxLength: 2048,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            // Quantidade + Unidade
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: InfoLabel(
                    label: 'Quantidade *',
                    child: TextBox(
                      controller: _qtdCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: InfoLabel(
                    label: 'Unidade de Medida *',
                    child: TextBox(
                      controller: _unidadeCtrl,
                      maxLength: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Valores
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InfoLabel(
                    label: 'Valor Unitário Est. *',
                    child: TextBox(
                      controller: _valorUnitCtrl,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('R\$'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoLabel(
                    label: 'Valor Total *',
                    child: TextBox(
                      controller: _valorTotalCtrl,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('R\$'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Critério de Julgamento
            InfoLabel(
              label: 'Critério de Julgamento *',
              child: ComboBox<int>(
                value: _criterioJulgamento,
                placeholder: const Text('Selecione...'),
                isExpanded: true,
                items: kCriterioJulgamento.entries
                    .map((e) =>
                        ComboBoxItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _criterioJulgamento = v),
              ),
            ),
            const SizedBox(height: 12),
            // Categoria do Item
            InfoLabel(
              label: 'Categoria do Item *',
              child: ComboBox<int>(
                value: _itemCategoria,
                placeholder: const Text('Selecione...'),
                isExpanded: true,
                items: kItemCategoria.entries
                    .map((e) =>
                        ComboBoxItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _itemCategoria = v),
              ),
            ),
            const SizedBox(height: 12),
            // Patrimônio (opcional)
            InfoLabel(
              label: 'Patrimônio (facultativo)',
              child: TextBox(controller: _patrimonioCtrl, maxLength: 255),
            ),
            const SizedBox(height: 12),
            // Código de Registro Imobiliário (opcional)
            InfoLabel(
              label: 'Código de Registro Imobiliário (facultativo)',
              child:
                  TextBox(controller: _registroImobCtrl, maxLength: 255),
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
          onPressed: _confirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
