import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../core/services/gemini_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Função pública de entrada
// ─────────────────────────────────────────────────────────────────────────────

/// Exibe o fluxo completo de importação Gemini para o Orçamento:
/// 1. Chama o serviço com [pdfPath] e a lista de [itensEstimativa].
/// 2. Exibe o dialog de revisão para Razão Social, CNPJ, Data e valores dos itens.
/// 3. Retorna um [GeminiOrcamentoResult] modificado com os campos aceitos/editados,
///    ou null se a importação foi cancelada.
Future<GeminiOrcamentoResult?> showGeminiOrcamentoImportDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String pdfPath,
  required List<Map<String, dynamic>> itensEstimativa,
}) async {
  // Mostra progress enquanto chama a API
  final result = await showAudespDialog<GeminiOrcamentoResult?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.medium,
    builder: (_) => _GeminiLoadingDialog(
      ref: ref,
      pdfPath: pdfPath,
      itensEstimativa: itensEstimativa,
    ),
  );

  if (result == null || !context.mounted) return null;

  // Exibe o dialog de revisão
  return showAudespDialog<GeminiOrcamentoResult?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.large,
    builder: (_) => _GeminiOrcamentoReviewDialog(
      suggestedValues: result,
      itensEstimativa: itensEstimativa,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 1 — Progresso
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiLoadingDialog extends StatefulWidget {
  final WidgetRef ref;
  final String pdfPath;
  final List<Map<String, dynamic>> itensEstimativa;

  const _GeminiLoadingDialog({
    required this.ref,
    required this.pdfPath,
    required this.itensEstimativa,
  });

  @override
  State<_GeminiLoadingDialog> createState() => _GeminiLoadingDialogState();
}

class _GeminiLoadingDialogState extends State<_GeminiLoadingDialog> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final service = widget.ref.read(geminiServiceProvider);
      final result = await service.extractOrcamentoFromFile(
        filePath: widget.pdfPath,
        itensEstimativa: widget.itensEstimativa,
      );
      if (mounted) Navigator.of(context).pop(result);
    } on GeminiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_fix_high),
          const SizedBox(width: 12),
          const Text('Analisando Orçamento...'),
        ],
      ),
      content: _errorMessage != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SizedBox(height: 8),
                LinearProgressIndicator(),
                SizedBox(height: 16),
                Text('O Gemini está lendo o orçamento e buscando os itens da estimativa. Aguarde…'),
              ],
            ),
      actions: [
        if (_errorMessage != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Fechar'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 2 — Revisão dos campos sugeridos
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiOrcamentoReviewDialog extends StatefulWidget {
  final GeminiOrcamentoResult suggestedValues;
  final List<Map<String, dynamic>> itensEstimativa;

  const _GeminiOrcamentoReviewDialog({
    required this.suggestedValues,
    required this.itensEstimativa,
  });

  @override
  State<_GeminiOrcamentoReviewDialog> createState() => _GeminiOrcamentoReviewDialogState();
}

class _GeminiOrcamentoReviewDialogState extends State<_GeminiOrcamentoReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _razaoSocialCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();

  late final Map<String, bool> _acceptedItems;

  @override
  void initState() {
    super.initState();
    _razaoSocialCtrl.text = widget.suggestedValues.razaoSocial ?? '';
    _cnpjCtrl.text = widget.suggestedValues.cnpj?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    _dataCtrl.text = widget.suggestedValues.data ?? '';

    // Pré-seleciona todos os itens que tiveram valor retornado.
    _acceptedItems = {
      for (final item in widget.itensEstimativa)
        if (item['id'] != null && widget.suggestedValues.itens.containsKey(item['id']))
          item['id'] as String: true,
    };
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _cnpjCtrl.dispose();
    _dataCtrl.dispose();
    super.dispose();
  }

  void _acceptAll() => setState(
        () => _acceptedItems.updateAll((k, v) => true),
      );

  void _rejectAll() => setState(
        () => _acceptedItems.updateAll((k, v) => false),
      );

  int get _acceptedCount => _acceptedItems.values.where((v) => v).length;

  GeminiOrcamentoResult _buildResult() {
    final acceptedMap = <String, double>{};
    for (final entry in _acceptedItems.entries) {
      if (entry.value) {
        final val = widget.suggestedValues.itens[entry.key];
        if (val != null) {
          acceptedMap[entry.key] = val;
        }
      }
    }

    return GeminiOrcamentoResult(
      razaoSocial: _razaoSocialCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim(),
      data: _dataCtrl.text.trim(),
      itens: acceptedMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_fix_high),
          const SizedBox(width: 12),
          const Expanded(child: Text('Revisão da Importação de Orçamento')),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fornecedor e Data do Orçamento (Edite se necessário)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _razaoSocialCtrl,
                      decoration: const InputDecoration(labelText: 'Razão Social', isDense: true),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cnpjCtrl,
                      decoration: const InputDecoration(labelText: 'CNPJ', isDense: true),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _dataCtrl,
                      readOnly: true,
                      onTap: () async {
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
                      },
                      decoration: const InputDecoration(
                        labelText: 'Data (dd/MM/yyyy)', 
                        isDense: true,
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              'Itens Encontrados no PDF',
              style: theme.textTheme.titleSmall,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _acceptAll,
                  child: const Text('Selecionar todos'),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _rejectAll,
                  child: const Text('Desmarcar todos'),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(2),
                    2: FixedColumnWidth(48),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      children: [
                        _tableHeader('Item da Estimativa'),
                        _tableHeader('V. Unitário (Sugerido)'),
                        _tableHeader(''),
                      ],
                    ),
                    for (final item in widget.itensEstimativa)
                      if (item['id'] != null && widget.suggestedValues.itens.containsKey(item['id']))
                        _buildRow(item, colorScheme, fmt),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$_acceptedCount item(ns) selecionado(s) para importação.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _acceptedCount == 0
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(_buildResult());
                  }
                },
          child: const Text('Importar Valores'),
        ),
      ],
    );
  }

  TableRow _buildRow(Map<String, dynamic> item, ColorScheme colorScheme, NumberFormat fmt) {
    final id = item['id'] as String?;
    final desc = item['descricao'] as String? ?? '';
    final suggested = id != null ? widget.suggestedValues.itens[id] : null;
    final hasValue = suggested != null;
    final isAccepted = id != null && (_acceptedItems[id] ?? false);

    return TableRow(
      decoration: BoxDecoration(
        color: isAccepted
            ? colorScheme.primaryContainer.withAlpha(80)
            : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            id != null ? '$id - $desc' : desc,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            hasValue ? fmt.format(suggested) : '—',
            style: TextStyle(
              fontSize: 12,
              color: hasValue ? colorScheme.primary : colorScheme.outline,
              fontWeight: hasValue ? FontWeight.w500 : null,
            ),
          ),
        ),
        Checkbox(
          value: isAccepted,
          onChanged: hasValue && id != null
              ? (v) => setState(() => _acceptedItems[id] = v ?? false)
              : null,
        ),
      ],
    );
  }

  static Widget _tableHeader(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
}
