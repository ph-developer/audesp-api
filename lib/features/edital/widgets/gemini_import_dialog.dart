import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../core/services/gemini_service.dart';
import '../domain/edital_domain.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Campos extraídos pelo Gemini para o Edital
// ─────────────────────────────────────────────────────────────────────────────

const _kEditalFields = <GeminiField>[
  GeminiField(
    key: 'codigoEdital',
    label: 'Código do Edital',
    hint: 'até 25 caracteres',
  ),
  GeminiField(
    key: 'dataDocumento',
    label: 'Data do Edital',
    hint: 'formato dd/MM/yyyy',
  ),
  GeminiField(
    key: 'tipoInstrumentoConvocatorioId',
    label: 'Tipo de Instrumento Convocatório',
    hint: '1=Edital, 2=Aviso Contratação Direta, 3=Ato Contratação Direta, 4=Chamamento Público',
  ),
  GeminiField(
    key: 'modalidadeId',
    label: 'Modalidade',
    hint: '1=Leilão Eletrônico, 2=Diálogo Competitivo, 3=Concurso, 4=Concorrência Eletrônica, '
        '5=Concorrência Presencial, 6=Pregão Eletrônico, 7=Pregão Presencial, '
        '8=Dispensa, 9=Inexigibilidade, 12=Credenciamento, 13=Leilão Presencial, '
        '14=Inaplicabilidade, 997=RDC, 998=Convite, 999=Tomada de Preços',
  ),
  GeminiField(
    key: 'modoDisputaId',
    label: 'Modo de Disputa',
    hint: '1=Aberto, 2=Fechado, 3=Aberto-Fechado, 4=Dispensa com Disputa, 5=Não se aplica, 6=Fechado-Aberto',
  ),
  GeminiField(
    key: 'numeroCompra',
    label: 'Número da Compra',
    hint: 'número sequencial da compra',
  ),
  GeminiField(
    key: 'anoCompra',
    label: 'Ano da Compra',
    hint: 'formato YYYY',
  ),
  GeminiField(
    key: 'numeroProcesso',
    label: 'Número do Processo',
  ),
  GeminiField(
    key: 'objetoCompra',
    label: 'Objeto da Contratação',
    hint: 'descrição resumida do objeto',
  ),
  GeminiField(
    key: 'srp',
    label: 'SRP – Sistema de Registro de Preços',
    hint: 'true ou false',
  ),
  GeminiField(
    key: 'amparoLegalId',
    label: 'Amparo Legal',
    hint: 'código numérico do amparo legal',
  ),
  GeminiField(
    key: 'dataAberturaProposta',
    label: 'Data/Hora de Abertura das Propostas',
    hint: 'formato dd/MM/yyyy HH:mm',
  ),
  GeminiField(
    key: 'dataEncerramentoProposta',
    label: 'Data/Hora de Encerramento das Propostas',
    hint: 'formato dd/MM/yyyy HH:mm',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helper — converte valor bruto em descrição legível para a tabela de revisão
// ─────────────────────────────────────────────────────────────────────────────

String _displayValue(String key, String raw) {
  if (raw.isEmpty) return raw;
  switch (key) {
    case 'srp':
      if (raw.toLowerCase() == 'true') return 'Sim';
      if (raw.toLowerCase() == 'false') return 'Não';
      return raw;
    case 'tipoInstrumentoConvocatorioId':
      final id = int.tryParse(raw);
      return id != null ? (kTipoInstrumento[id] ?? raw) : raw;
    case 'modalidadeId':
      final id = int.tryParse(raw);
      return id != null ? (kModalidades[id] ?? raw) : raw;
    case 'modoDisputaId':
      final id = int.tryParse(raw);
      return id != null ? (kModoDisputa[id] ?? raw) : raw;
    case 'amparoLegalId':
      final id = int.tryParse(raw);
      return id != null ? (kAmparosLegais[id] ?? raw) : raw;
    default:
      return raw;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Função pública de entrada
// ─────────────────────────────────────────────────────────────────────────────

/// Exibe o fluxo completo de importação Gemini para o Edital:
/// 1. Chama o serviço com [pdfPath].
/// 2. Exibe o dialog de revisão com os valores sugeridos x atuais.
/// 3. Retorna um mapa com apenas os campos aceitos pelo usuário,
///    ou null se a importação foi cancelada.
///
/// [currentValues] é o estado atual do formulário (campo → valor String).
Future<Map<String, String>?> showGeminiImportDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String pdfPath,
  required Map<String, String> currentValues,
}) async {
  // Mostra progress enquanto chama a API
  final result = await showAudespDialog<GeminiExtractionResult?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.small,
    builder: (_) => _GeminiLoadingDialog(
      ref: ref,
      pdfPath: pdfPath,
    ),
  );

  if (result == null || !context.mounted) return null;

  // Exibe o dialog de revisão
  return showAudespDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.large,
    builder: (_) => _GeminiReviewDialog(
      fields: _kEditalFields,
      currentValues: currentValues,
      suggestedValues: result,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 1 — Progresso (Sugestão 4)
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiLoadingDialog extends StatefulWidget {
  final WidgetRef ref;
  final String pdfPath;

  const _GeminiLoadingDialog({
    required this.ref,
    required this.pdfPath,
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
      final result = await service.extractFromPdf(
        pdfPath: widget.pdfPath,
        fields: _kEditalFields,
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
          const Text('Analisando PDF...'),
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
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
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
                Text('O Gemini está lendo o documento e extraindo os campos do edital. Aguarde…'),
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

class _GeminiReviewDialog extends StatefulWidget {
  final List<GeminiField> fields;
  final Map<String, String> currentValues;
  final GeminiExtractionResult suggestedValues;

  const _GeminiReviewDialog({
    required this.fields,
    required this.currentValues,
    required this.suggestedValues,
  });

  @override
  State<_GeminiReviewDialog> createState() => _GeminiReviewDialogState();
}

class _GeminiReviewDialogState extends State<_GeminiReviewDialog> {
  late final Map<String, bool> _accepted;

  @override
  void initState() {
    super.initState();
    // Pré-seleciona campos onde o Gemini encontrou valor e o atual está vazio.
    _accepted = {
      for (final f in widget.fields)
        f.key: widget.suggestedValues[f.key] != null &&
            (widget.currentValues[f.key] ?? '').isEmpty,
    };
  }

  void _acceptAll() => setState(
        () => _accepted.updateAll(
          (k, _) => widget.suggestedValues[k] != null,
        ),
      );

  void _rejectAll() => setState(
        () => _accepted.updateAll((_, _) => false),
      );

  Map<String, String> _buildResult() {
    final result = <String, String>{};
    for (final entry in _accepted.entries) {
      if (entry.value) {
        final v = widget.suggestedValues[entry.key];
        if (v != null) result[entry.key] = v;
      }
    }
    return result;
  }

  int get _acceptedCount =>
      _accepted.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_fix_high),
          const SizedBox(width: 12),
          const Expanded(child: Text('Revisão da Importação')),
        ],
      ),
      content: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecione os campos que deseja substituir no formulário.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _acceptAll,
                  child: const Text('Selecionar tudo'),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _rejectAll,
                  child: const Text('Desmarcar tudo'),
                ),
              ],
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(3),
                    3: FixedColumnWidth(48),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      children: [
                        _tableHeader('Campo'),
                        _tableHeader('Valor Atual'),
                        _tableHeader('Sugestão Gemini'),
                        _tableHeader(''),
                      ],
                    ),
                    for (final field in widget.fields)
                      _buildRow(field, colorScheme),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$_acceptedCount campo(s) selecionado(s) para importação.',
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
              : () => Navigator.of(context).pop(_buildResult()),
          child: const Text('Aplicar Selecionados'),
        ),
      ],
    );
  }

  TableRow _buildRow(GeminiField field, ColorScheme colorScheme) {
    final current = widget.currentValues[field.key] ?? '';
    final suggested = widget.suggestedValues[field.key];
    final hasValue = suggested != null;
    final isAccepted = _accepted[field.key] ?? false;

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
            field.label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            current.isEmpty ? '—' : _displayValue(field.key, current),
            style: TextStyle(
              fontSize: 12,
              color: current.isEmpty ? colorScheme.outline : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            hasValue ? _displayValue(field.key, suggested) : '—',
            style: TextStyle(
              fontSize: 12,
              color: hasValue ? colorScheme.primary : colorScheme.outline,
              fontWeight: hasValue ? FontWeight.w500 : null,
            ),
          ),
        ),
        Checkbox(
          value: isAccepted,
          onChanged: hasValue
              ? (v) => setState(() => _accepted[field.key] = v ?? false)
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
