import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_currency_field.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_segmented_button.dart';
import '../../../shared/widgets/audesp_field_row.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_spacing.dart';
import '../../../shared/widgets/audesp_text_field.dart';
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
  return showAudespDialog<Map<String, dynamic>>(
    context: context,
    size: DialogSize.large,
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
  final _formKey = GlobalKey<FormState>();

  String _materialOuServico = 'M';
  int? _tipoBeneficio;
  bool _incentivoBasico = false;
  bool _orcamentoSigiloso = false;
  int? _itemCategoria;

  final _descCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController();
  final _valorUnitCtrl = TextEditingController();
  final _valorTotalCtrl = TextEditingController();
  final _patrimonioCtrl = TextEditingController();
  final _registroImobCtrl = TextEditingController();

  void _recalcularTotal() {
    final qtd = parseBrCurrencyOrNull(_qtdCtrl.text);
    final unit = parseBrCurrencyOrNull(_valorUnitCtrl.text);
    if (qtd != null && unit != null) {
      _valorTotalCtrl.text = doubleToBrString(qtd * unit);
    } else {
      _valorTotalCtrl.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _qtdCtrl.addListener(_recalcularTotal);
    _valorUnitCtrl.addListener(_recalcularTotal);
    final ini = widget.initial;
    if (ini != null) {
      _materialOuServico = ini['materialOuServico'] as String? ?? 'M';
      _tipoBeneficio = ini['tipoBeneficioId'] as int?;
      _incentivoBasico = ini['incentivoProdutivoBasico'] as bool? ?? false;
      _orcamentoSigiloso = ini['orcamentoSigiloso'] as bool? ?? false;
      _itemCategoria = ini['itemCategoriaId'] as int?;
      _descCtrl.text = ini['descricao'] as String? ?? '';
      _qtdCtrl.text = doubleToBrString(ini['quantidade']);
      _unidadeCtrl.text = ini['unidadeMedida'] as String? ?? '';
      _valorUnitCtrl.text = doubleToBrString(ini['valorUnitarioEstimado']);
      _valorTotalCtrl.text = doubleToBrString(ini['valorTotal']);
      _patrimonioCtrl.text = ini['patrimonio'] as String? ?? '';
      _registroImobCtrl.text =
          ini['codigoRegistroImobiliario'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _qtdCtrl.removeListener(_recalcularTotal);
    _valorUnitCtrl.removeListener(_recalcularTotal);
    _descCtrl.dispose();
    _qtdCtrl.dispose();
    _unidadeCtrl.dispose();
    _valorUnitCtrl.dispose();
    _valorTotalCtrl.dispose();
    _patrimonioCtrl.dispose();
    _registroImobCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final result = <String, dynamic>{
      'numeroItem': widget.numero,
      'materialOuServico': _materialOuServico,
      'tipoBeneficioId': _tipoBeneficio,
      'incentivoProdutivoBasico': _incentivoBasico,
      'descricao': _descCtrl.text.trim(),
      'quantidade': double.parse(
        parseBrCurrency(_qtdCtrl.text.trim()).toStringAsFixed(4),
      ),
      'unidadeMedida': _unidadeCtrl.text.trim(),
      'orcamentoSigiloso': _orcamentoSigiloso,
      'valorUnitarioEstimado': double.parse(
        parseBrCurrency(_valorUnitCtrl.text.trim()).toStringAsFixed(4),
      ),
      'valorTotal': double.parse(
        parseBrCurrency(_valorTotalCtrl.text.trim()).toStringAsFixed(4),
      ),
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
    return AlertDialog(
      title: Text('Item ${widget.numero}'),
      scrollable: true,
      content: SizedBox(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material ou Serviço
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AudespSegmentedButton<String>(
                    segments: const {'M': 'Material', 'S': 'Serviço'},
                    selected: {_materialOuServico},
                    onSelectionChanged: (s) =>
                        setState(() => _materialOuServico = s.first),
                  ),
                ],
              ),
              AudespSpacing.verticalMd,
              // Tipo de Benefício
              AudespDropdown<int>(
                label: 'Tipo de Benefício *',
                value: _tipoBeneficio,
                items: kTipoBeneficio,
                onChanged: (v) => setState(() => _tipoBeneficio = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              AudespSpacing.verticalSm,
              // Switches
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    child: AudespCheckbox(
                      label: 'Incentivo Produtivo Básico (PPB)',
                      value: _incentivoBasico,
                      onChanged: (v) => setState(() => _incentivoBasico = v),
                    ),
                  ),
                  AudespFieldRowItem(
                    child: AudespCheckbox(
                      label: 'Orçamento Sigiloso',
                      value: _orcamentoSigiloso,
                      onChanged: (v) => setState(() => _orcamentoSigiloso = v),
                    ),
                  ),
                ],
              ),
              AudespSpacing.verticalSm,
              // Descrição
              AudespTextField(
                label: 'Descrição *',
                controller: _descCtrl,
                maxLength: 2048,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              AudespSpacing.verticalMd,
              // Quantidade + Unidade (em linha)
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    flex: 2,
                    child: AudespNumberField(
                      label: 'Quantidade *',
                      controller: _qtdCtrl,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (parseBrCurrencyOrNull(v) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  AudespFieldRowItem(
                    flex: 2,
                    child: AudespTextField(
                      label: 'Unidade de Medida *',
                      controller: _unidadeCtrl,
                      maxLength: 30,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              AudespSpacing.verticalMd,
              // Valores
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    child: AudespCurrencyField(
                      label: 'Valor Unitário Estimado *',
                      controller: _valorUnitCtrl,
                    ),
                  ),
                  AudespFieldRowItem(
                    child: AudespCurrencyField(
                      label: 'Valor Total Estimado *',
                      controller: _valorTotalCtrl,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              AudespSpacing.verticalMd,
              // Categoria do Item
              AudespDropdown<int>(
                label: 'Categoria do Item *',
                value: _itemCategoria,
                items: kItemCategoria,
                onChanged: (v) => setState(() => _itemCategoria = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              AudespSpacing.verticalMd,
              // Patrimônio (opcional)
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    flex: 2,
                    child: AudespTextField(
                      label: 'Patrimônio',
                      controller: _patrimonioCtrl,
                      maxLength: 255,
                    ),
                  ),
                  // Código de Registro Imobiliário (opcional)
                  AudespFieldRowItem(
                    flex: 2,
                    child: AudespTextField(
                      label: 'Registro Imobiliário',
                      controller: _registroImobCtrl,
                      maxLength: 255,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Confirmar')),
      ],
    );
  }
}
