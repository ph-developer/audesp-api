import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/services/gemini_service.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../models/estimativa_item_model.dart';

Future<List<EstimativaItem>?> showGeminiItensImportDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String pdfPath,
  required int nextNumero,
}) async {
  final extractedItens =
      await showAudespDialog<List<GeminiEstimativaItemResult>?>(
        context: context,
        barrierDismissible: false,
        size: DialogSize.medium,
        builder: (_) => _GeminiLoadingItensDialog(ref: ref, pdfPath: pdfPath),
      );

  if (extractedItens == null || extractedItens.isEmpty || !context.mounted) {
    return null;
  }

  return showGeminiItensReviewDialog(
    context: context,
    extractedItens: extractedItens,
    nextNumero: nextNumero,
  );
}

Future<List<EstimativaItem>?> showGeminiItensReviewDialog({
  required BuildContext context,
  required List<GeminiEstimativaItemResult> extractedItens,
  required int nextNumero,
}) async {
  return showAudespDialog<List<EstimativaItem>?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.large,
    builder: (_) => _GeminiItensReviewDialog(
      extractedItens: extractedItens,
      nextNumero: nextNumero,
    ),
  );
}

class _GeminiLoadingItensDialog extends StatefulWidget {
  final WidgetRef ref;
  final String pdfPath;

  const _GeminiLoadingItensDialog({required this.ref, required this.pdfPath});

  @override
  State<_GeminiLoadingItensDialog> createState() =>
      _GeminiLoadingItensDialogState();
}

class _GeminiLoadingItensDialogState extends State<_GeminiLoadingItensDialog> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final service = widget.ref.read(geminiServiceProvider);
      final result = await service.extractItensEstimativaFromFile(
        filePath: widget.pdfPath,
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
        children: const [
          Icon(Icons.auto_fix_high),
          SizedBox(width: 12),
          Text('Analisando Documento...'),
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
                Text(
                  'O Gemini está lendo o documento e extraindo a lista de itens. Aguarde…',
                ),
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

class _GeminiItensReviewDialog extends StatefulWidget {
  final List<GeminiEstimativaItemResult> extractedItens;
  final int nextNumero;

  const _GeminiItensReviewDialog({
    required this.extractedItens,
    required this.nextNumero,
  });

  @override
  State<_GeminiItensReviewDialog> createState() =>
      _GeminiItensReviewDialogState();
}

class _GeminiItensReviewDialogState extends State<_GeminiItensReviewDialog> {
  late final List<bool> _selected;

  String _tipoFornecimento = 'unica';
  final _quantidadeMesesCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _selected = List.generate(widget.extractedItens.length, (_) => true);
  }

  @override
  void dispose() {
    _quantidadeMesesCtrl.dispose();
    super.dispose();
  }

  int get _selectedCount => _selected.where((v) => v).length;

  void _acceptAll() =>
      setState(() => _selected.fillRange(0, _selected.length, true));
  void _rejectAll() =>
      setState(() => _selected.fillRange(0, _selected.length, false));

  List<EstimativaItem>? _buildResult() {
    if (_tipoFornecimento == 'mensal') {
      final meses = int.tryParse(_quantidadeMesesCtrl.text.trim()) ?? 0;
      if (meses <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantidade de meses inválida.')),
        );
        return null;
      }
    }

    final results = <EstimativaItem>[];
    int currentNum = widget.nextNumero;

    final meses = int.tryParse(_quantidadeMesesCtrl.text.trim()) ?? 1;

    for (int i = 0; i < widget.extractedItens.length; i++) {
      if (_selected[i]) {
        final item = widget.extractedItens[i];
        results.add(
          EstimativaItem(
            numero: currentNum++,
            descricao: item.descricao,
            quantidade: item.quantidade,
            unidade: item.unidade,
            materialOuServico: item.materialOuServico,
            itemCategoriaId: item.itemCategoriaId,
            tipoFornecimento: _tipoFornecimento,
            quantidadeMeses: meses,
          ),
        );
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.auto_fix_high),
          SizedBox(width: 12),
          Expanded(child: Text('Revisão da Importação de Itens')),
        ],
      ),
      content: SizedBox(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Configuração Geral dos Itens Importados',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AudespDropdown<String>(
                    label: 'Tipo de Fornecimento',
                    value: _tipoFornecimento,
                    items: const {
                      'unica': 'Entrega Única',
                      'mensal': 'Entrega Mensal',
                    },
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _tipoFornecimento = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (_tipoFornecimento == 'mensal')
                  Expanded(
                    child: AudespTextField(
                      label: 'Quantidade de Meses *',
                      controller: _quantidadeMesesCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Itens Identificados no PDF (${widget.extractedItens.length})',
                  style: theme.textTheme.titleSmall,
                ),
                Row(
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
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(5),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FixedColumnWidth(70),
                    4: FixedColumnWidth(80),
                    5: FixedColumnWidth(48),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      children: [
                        _tableHeader('Descrição'),
                        _tableHeader('Quant.'),
                        _tableHeader('Unid.'),
                        _tableHeader('Tipo'),
                        _tableHeader('Categoria'),
                        _tableHeader(''),
                      ],
                    ),
                    for (int i = 0; i < widget.extractedItens.length; i++)
                      _buildRow(i, colorScheme),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$_selectedCount item(ns) selecionado(s) para importação.',
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
          onPressed: _selectedCount == 0
              ? null
              : () {
                  final result = _buildResult();
                  if (result != null) {
                    Navigator.of(context).pop(result);
                  }
                },
          child: const Text('Importar Selecionados'),
        ),
      ],
    );
  }

  TableRow _buildRow(int index, ColorScheme colorScheme) {
    final item = widget.extractedItens[index];
    final isAccepted = _selected[index];
    final tipoStr = item.materialOuServico == 'M' ? 'Material' : 'Serviço';

    String catStr = 'Não se aplica';
    if (item.itemCategoriaId == 1) {
      catStr = 'Bens Imóveis';
    } else if (item.itemCategoriaId == 2) {
      catStr = 'Bens Móveis';
    }

    return TableRow(
      decoration: BoxDecoration(
        color: isAccepted ? colorScheme.primaryContainer.withAlpha(80) : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(item.descricao, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            formatNumberBR(item.quantidade),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(item.unidade, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(tipoStr, style: const TextStyle(fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(catStr, style: const TextStyle(fontSize: 11)),
        ),
        Checkbox(
          value: isAccepted,
          onChanged: (v) => setState(() => _selected[index] = v ?? false),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}
