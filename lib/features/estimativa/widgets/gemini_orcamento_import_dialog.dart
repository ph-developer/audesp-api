import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../core/services/gemini_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Função pública de entrada — Orçamento Único
// ─────────────────────────────────────────────────────────────────────────────

/// Exibe o fluxo completo de importação Gemini para um único orçamento:
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
// Função pública de entrada — Múltiplos Orçamentos
// ─────────────────────────────────────────────────────────────────────────────

/// Exibe o fluxo completo de importação Gemini para múltiplos orçamentos
/// extraídos de um único arquivo.
/// 1. Chama o serviço com [pdfPath] e a lista de [itensEstimativa].
/// 2. Exibe o dialog de revisão com abas (uma por empresa).
/// 3. Retorna uma lista de [GeminiOrcamentoResult] (apenas empresas com itens
///    aceitos) ou null se cancelado.
Future<List<GeminiOrcamentoResult>?> showGeminiMultiOrcamentoImportDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String pdfPath,
  required List<Map<String, dynamic>> itensEstimativa,
}) async {
  final results = await showAudespDialog<List<GeminiOrcamentoResult>?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.medium,
    builder: (_) => _GeminiMultiLoadingDialog(
      ref: ref,
      pdfPath: pdfPath,
      itensEstimativa: itensEstimativa,
    ),
  );

  if (results == null || results.isEmpty || !context.mounted) return null;

  return showAudespDialog<List<GeminiOrcamentoResult>?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.large,
    builder: (_) => _GeminiMultiOrcamentoReviewDialog(
      suggestedValues: results,
      itensEstimativa: itensEstimativa,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 1a — Progresso (único)
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
                Text(
                  'O Gemini está lendo o orçamento e buscando os itens da estimativa. Aguarde…',
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

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 1b — Progresso (múltiplos)
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiMultiLoadingDialog extends StatefulWidget {
  final WidgetRef ref;
  final String pdfPath;
  final List<Map<String, dynamic>> itensEstimativa;

  const _GeminiMultiLoadingDialog({
    required this.ref,
    required this.pdfPath,
    required this.itensEstimativa,
  });

  @override
  State<_GeminiMultiLoadingDialog> createState() =>
      _GeminiMultiLoadingDialogState();
}

class _GeminiMultiLoadingDialogState extends State<_GeminiMultiLoadingDialog> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final service = widget.ref.read(geminiServiceProvider);
      final result = await service.extractMultiOrcamentoFromFile(
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
          const Text('Analisando Orçamentos...'),
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
                  'O Gemini está lendo os orçamentos e buscando os itens da estimativa. Aguarde…',
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

// ─────────────────────────────────────────────────────────────────────────────
// Card reutilizável — Revisão dos campos de UMA empresa
// ─────────────────────────────────────────────────────────────────────────────

class _CompanyReviewCard extends StatefulWidget {
  final GeminiOrcamentoResult suggestedValues;
  final List<Map<String, dynamic>> itensEstimativa;
  final VoidCallback? onChanged;

  const _CompanyReviewCard({
    super.key,
    required this.suggestedValues,
    required this.itensEstimativa,
    this.onChanged,
  });

  @override
  State<_CompanyReviewCard> createState() => _CompanyReviewCardState();
}

class _CompanyReviewCardState extends State<_CompanyReviewCard> {
  final formKey = GlobalKey<FormState>();
  final _razaoSocialCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  DateTime? _data;

  late final Map<String, bool> _acceptedItems;

  @override
  void initState() {
    super.initState();
    _razaoSocialCtrl.text = widget.suggestedValues.razaoSocial ?? '';
    _cnpjCtrl.text =
        widget.suggestedValues.cnpj?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (widget.suggestedValues.data != null &&
        widget.suggestedValues.data!.isNotEmpty) {
      try {
        _data = DateFormat('dd/MM/yyyy').parse(widget.suggestedValues.data!);
      } catch (_) {}
    }

    _acceptedItems = {
      for (final item in widget.itensEstimativa)
        if (item['id'] != null &&
            widget.suggestedValues.itens.containsKey(item['id']))
          item['id'] as String: true,
    };
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _cnpjCtrl.dispose();
    super.dispose();
  }

  int get acceptedCount => _acceptedItems.values.where((v) => v).length;

  void _acceptAll() {
    setState(() => _acceptedItems.updateAll((k, v) => true));
    widget.onChanged?.call();
  }

  void _rejectAll() {
    setState(() => _acceptedItems.updateAll((k, v) => false));
    widget.onChanged?.call();
  }

  /// Retorna o [GeminiOrcamentoResult] apenas com os itens aceitos, ou null
  /// se o formulário for inválido.
  GeminiOrcamentoResult? buildResult() {
    if (!(formKey.currentState?.validate() ?? false)) return null;

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
      data: _data != null ? DateFormat('dd/MM/yyyy').format(_data!) : null,
      itens: acceptedMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Fornecedor e Data do Orçamento (Edite se necessário)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Form(
          key: formKey,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: AudespTextField(
                  label: 'Razão Social',
                  controller: _razaoSocialCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AudespTextField(
                  label: 'CNPJ',
                  controller: _cnpjCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AudespDatePickerField(
                  label: 'Data *',
                  value: _data,
                  onChanged: (d) => setState(() => _data = d),
                  validator: (d) => d == null ? 'Obrigatório' : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Text('Itens Encontrados no PDF', style: theme.textTheme.titleSmall),
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
                  if (item['id'] != null &&
                      widget.suggestedValues.itens.containsKey(item['id']))
                    _buildRow(item, colorScheme),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$acceptedCount item(ns) selecionado(s) para importação.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  TableRow _buildRow(Map<String, dynamic> item, ColorScheme colorScheme) {
    final id = item['id'] as String?;
    final desc = item['descricao'] as String? ?? '';
    final suggested = id != null ? widget.suggestedValues.itens[id] : null;
    final hasValue = suggested != null;
    final isAccepted = id != null && (_acceptedItems[id] ?? false);

    return TableRow(
      decoration: BoxDecoration(
        color: isAccepted ? colorScheme.primaryContainer.withAlpha(80) : null,
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
            hasValue ? formatBRL(suggested) : '—',
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
              ? (v) {
                  setState(() => _acceptedItems[id] = v ?? false);
                  widget.onChanged?.call();
                }
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

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 2a — Revisão (único)
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiOrcamentoReviewDialog extends StatefulWidget {
  final GeminiOrcamentoResult suggestedValues;
  final List<Map<String, dynamic>> itensEstimativa;

  const _GeminiOrcamentoReviewDialog({
    required this.suggestedValues,
    required this.itensEstimativa,
  });

  @override
  State<_GeminiOrcamentoReviewDialog> createState() =>
      _GeminiOrcamentoReviewDialogState();
}

class _GeminiOrcamentoReviewDialogState
    extends State<_GeminiOrcamentoReviewDialog> {
  final _cardKey = GlobalKey<_CompanyReviewCardState>();

  int get _acceptedCount {
    final state = _cardKey.currentState;
    if (state != null) return state.acceptedCount;

    int count = 0;
    for (final item in widget.itensEstimativa) {
      if (item['id'] != null &&
          widget.suggestedValues.itens.containsKey(item['id'])) {
        count++;
      }
    }
    return count;
  }

  void _onCardChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
        child: _CompanyReviewCard(
          key: _cardKey,
          suggestedValues: widget.suggestedValues,
          itensEstimativa: widget.itensEstimativa,
          onChanged: _onCardChanged,
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
                  final result = _cardKey.currentState?.buildResult();
                  if (result != null) {
                    Navigator.of(context).pop(result);
                  }
                },
          child: const Text('Importar Valores'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 2b — Revisão (múltiplos, com abas)
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiMultiOrcamentoReviewDialog extends StatefulWidget {
  final List<GeminiOrcamentoResult> suggestedValues;
  final List<Map<String, dynamic>> itensEstimativa;

  const _GeminiMultiOrcamentoReviewDialog({
    required this.suggestedValues,
    required this.itensEstimativa,
  });

  @override
  State<_GeminiMultiOrcamentoReviewDialog> createState() =>
      _GeminiMultiOrcamentoReviewDialogState();
}

class _GeminiMultiOrcamentoReviewDialogState
    extends State<_GeminiMultiOrcamentoReviewDialog> {
  late final List<GlobalKey<_CompanyReviewCardState>> _cardKeys;

  @override
  void initState() {
    super.initState();
    _cardKeys = List.generate(
      widget.suggestedValues.length,
      (_) => GlobalKey<_CompanyReviewCardState>(),
    );
  }

  void _onCardChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalCompanies = widget.suggestedValues.length;
    final tabLabels = List.generate(totalCompanies, (i) {
      final empresa = widget.suggestedValues[i];
      return empresa.razaoSocial?.isNotEmpty == true
          ? empresa.razaoSocial!
          : 'Orçamento ${i + 1}';
    });

    const tabWidth = 200.0;

    final childrenWidgets = List.generate(totalCompanies, (i) {
      return SingleChildScrollView(
        child: _CompanyReviewCard(
          key: _cardKeys[i],
          suggestedValues: widget.suggestedValues[i],
          itensEstimativa: widget.itensEstimativa,
          onChanged: _onCardChanged,
        ),
      );
    });

    return DefaultTabController(
      length: totalCompanies,
      child: Builder(
        builder: (tabCtx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_fix_high),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Revisão da Importação de Orçamentos'),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: List.generate(totalCompanies, (i) {
                    return SizedBox(
                      width: tabWidth,
                      child: Tab(
                        child: Text(
                          tabLabels[i],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: AnimatedBuilder(
                    animation: DefaultTabController.of(tabCtx),
                    builder: (context, _) {
                      return IndexedStack(
                        index: DefaultTabController.of(tabCtx).index,
                        children: childrenWidgets,
                      );
                    },
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
              onPressed: _totalAcceptedCount > 0
                  ? () {
                      final results = <GeminiOrcamentoResult>[];
                      for (final key in _cardKeys) {
                        final state = key.currentState;
                        if (state != null) {
                          final result = state.buildResult();
                          if (result != null && result.itens.isNotEmpty) {
                            results.add(result);
                          }
                        }
                      }
                      if (results.isNotEmpty) {
                        Navigator.of(context).pop(results);
                      }
                    }
                  : null,
              child: Text(
                'Importar Valores Selecionados ($totalCompanies empresa(s))',
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _totalAcceptedCount {
    var count = 0;
    for (int i = 0; i < _cardKeys.length; i++) {
      final state = _cardKeys[i].currentState;
      if (state != null) {
        count += state.acceptedCount;
      } else {
        final suggested = widget.suggestedValues[i];
        for (final item in widget.itensEstimativa) {
          if (item['id'] != null && suggested.itens.containsKey(item['id'])) {
            count++;
          }
        }
      }
    }
    return count;
  }
}
