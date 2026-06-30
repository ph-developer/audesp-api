import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../core/services/gemini_service.dart';
import '../domain/licitacao_domain.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Campos extraídos pelo Gemini para a Licitação (Fase 5)
// ─────────────────────────────────────────────────────────────────────────────

final kLicitacaoGeminiFields = <GeminiField>[
  GeminiField(
    key: 'tipoNatureza',
    label: 'Tipo de Natureza',
    hint:
        '1=Normal (padrão), 2=Concessão/permissão de uso (Lei 14.133/2024), '
        '3=Concessão serviço público ordinária (Lei 8.987/1995), '
        '4=PPP Patrocinada (Lei 11.079/2004), '
        '5=PPP Administrativa (Lei 11.079/2004), '
        '6=Permissão serviço público (Lei 8.987/1995), '
        '7=Credenciamento (Lei 14.133/2021), '
        '8=Registro de Preços (Lei 14.133/2021). '
        'Use 1 (Normal) a menos que o edital mencione explicitamente outro tipo.',
  ),
  GeminiField(
    key: 'exigenciaAmostra',
    label: 'Exigência de Amostra',
    hint: '1=Sim, para todos os licitantes, 2=Sim, somente do vencedor, 3=Não',
  ),
  GeminiField(
    key: 'exigenciaCurriculo',
    label: 'Exigência de Currículo',
    hint:
        '"true" ou "false" (inglês), conforme exige ou não comprovação de currículo',
  ),
  GeminiField(
    key: 'exigenciaVistoCREA',
    label: 'Exigência de Visto CREA',
    hint:
        '"true" ou "false" (inglês), conforme exige ou não visto CREA na habilitação',
  ),
  GeminiField(
    key: 'exigenciaVisitaTecnica',
    label: 'Exigência de Visita Técnica',
    hint: '1=Sim, 2=Não',
  ),
  GeminiField(
    key: 'exigenciaGarantiaLicitantes',
    label: 'Exigência de Garantia de Execução Contratual',
    hint:
        '1=Sim (exige garantia de execução contratual, caução, ou seguro-garantia dos licitantes), '
        '2=Não',
  ),
  GeminiField(
    key: 'percentualGarantia',
    label: 'Percentual de Garantia',
    hint:
        'Percentual exigido de garantia de execução contratual, caução ou seguro-garantia exigido. Ex.: "5" para 5%. Deixe vazio se não informado.',
  ),
  GeminiField(
    key: 'quitacaoTributosFederais',
    label: 'Quitação Tributos Federais',
    hint:
        '"true" se o edital exige certidão negativa federal na habilitação, "false" caso contrário',
  ),
  GeminiField(
    key: 'quitacaoTributosEstaduais',
    label: 'Quitação Tributos Estaduais',
    hint:
        '"true" se o edital exige certidão negativa estadual na habilitação, "false" caso contrário',
  ),
  GeminiField(
    key: 'quitacaoTributosMunicipais',
    label: 'Quitação Tributos Municipais',
    hint:
        '"true" se o edital exige certidão negativa municipal na habilitação, "false" caso contrário',
  ),
  GeminiField(
    key: 'fonteRecursosContratacao',
    label: 'Fontes de Recurso',
    hint:
        'Lista separada por vírgulas dos códigos numéricos. Ex.: "1, 5, 8". '
        '1=Tesouro, 2=Transferências e Convênios Estaduais - Vinculados, '
        '3=Recursos Próprios de Fundos Especiais, 4=Recursos Próprios da Adm. Indireta, '
        '5=Transferências e Convênios Federais - Vinculados, 6=Outras Fontes, '
        '7=Operações de Crédito, 8=Emendas Parlamentares Individuais',
  ),
  GeminiField(
    key: 'exigenciaIndicesEconomicos',
    label: 'Exigência de Índices Econômicos',
    hint: '1=Sim (exige índices econômicos na habilitação), 2=Não',
  ),
  GeminiField(
    key: 'indicesEconomicos',
    label: 'Índices Econômicos (detalhes)',
    hint:
        'JSON array com os índices exigidos, SOMENTE se exigenciaIndicesEconomicos for 1. '
        'Formato: [{"tipoIndice": N, "valorIndice": V.0, "nomeIndice": "..."}]. '
        'tipoIndice: 1=Capital Social Mínimo, 2=Endividamento Curto Prazo, '
        '3=Endividamento Total, 4=Liquidez Corrente, 5=Liquidez Geral, '
        '6=Liquidez Imediata, 7=Liquidez Seca, 8=Outro. '
        'Se for tipo 8, inclua "nomeIndice" com o nome personalizado. '
        'Ex.: [{"tipoIndice": 1, "valorIndice": 150000.0}, {"tipoIndice": 4, "valorIndice": 1.5}]',
  ),
  GeminiField(key: 'recursoBID', label: 'Recurso BID', hint: '1=Sim, 2=Não'),
  GeminiField(
    key: 'audienciaPublica',
    label: 'Audiência Pública',
    hint: '1=Sim (haverá sessão de lances), 2=Não',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de exibição
// ─────────────────────────────────────────────────────────────────────────────

/// Remove o prefixo numérico de labels como "1 – Normal" → "Normal".
String _stripIdPrefix(String value) {
  final match = RegExp(r'^\d+\s*[–-]\s*').firstMatch(value);
  return match != null ? value.substring(match.end) : value;
}

/// Ajusta o ID pra 2 dígitos: "1 – Tesouro" → "01 – Tesouro".
String _padFonteLabel(int id, String label) {
  final padded = id.toString().padLeft(2, '0');
  final match = RegExp(r'^\d+\s*[–-]\s*').firstMatch(label);
  return match != null ? '$padded – ${label.substring(match.end)}' : label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper — converte valor bruto em descrição legível para a tabela de revisão
// ─────────────────────────────────────────────────────────────────────────────

String _displayValue(String key, String raw) {
  if (raw.isEmpty) return raw;
  switch (key) {
    case 'exigenciaCurriculo':
    case 'exigenciaVistoCREA':
    case 'quitacaoTributosFederais':
    case 'quitacaoTributosEstaduais':
    case 'quitacaoTributosMunicipais':
      if (['true', 'sim'].contains(raw.toLowerCase())) return 'Sim';
      if (['false', 'não', 'nao'].contains(raw.toLowerCase())) return 'Não';
      return raw;
    case 'tipoNatureza':
      {
        final id = int.tryParse(raw);
        return id != null ? (_stripIdPrefix(kTipoNatureza[id] ?? raw)) : raw;
      }
    case 'exigenciaAmostra':
      {
        final id = int.tryParse(raw);
        return id != null
            ? (_stripIdPrefix(kExigenciaAmostra[id] ?? raw))
            : raw;
      }
    case 'exigenciaVisitaTecnica':
      {
        final id = int.tryParse(raw);
        return id != null
            ? (_stripIdPrefix(kExigenciaVisitaTecnica[id] ?? raw))
            : raw;
      }
    case 'exigenciaGarantiaLicitantes':
    case 'exigenciaIndicesEconomicos':
    case 'audienciaPublica':
      {
        final id = int.tryParse(raw);
        return id != null ? (_stripIdPrefix(kTriState[id] ?? raw)) : raw;
      }
    case 'recursoBID':
      {
        final id = int.tryParse(raw);
        return id != null ? (_stripIdPrefix(kRecursoBID[id] ?? raw)) : raw;
      }
    case 'percentualGarantia':
      {
        final v = double.tryParse(raw);
        return v != null ? '${v.toStringAsFixed(4)}%' : raw;
      }
    case 'fonteRecursosContratacao':
      {
        final parts = raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        final labels = parts.map((s) {
          final id = int.tryParse(s);
          return id != null ? _padFonteLabel(id, kFonteRecurso[id] ?? s) : s;
        });
        return labels.join(', ');
      }
    case 'indicesEconomicos':
      try {
        final list = jsonDecode(raw) as List;
        final lines = list
            .map((e) {
              final idx = e as Map;
              final tipo = idx['tipoIndice'];
              final nomeTipo = tipo != null
                  ? (_stripIdPrefix(kTipoIndice[tipo] ?? 'Tipo $tipo'))
                  : '';
              final valor = idx['valorIndice'];
              final nomeExtra = idx['nomeIndice'] as String?;
              final partes = <String>[];
              if (nomeTipo.isNotEmpty) partes.add(nomeTipo);
              if (nomeExtra != null && nomeExtra.isNotEmpty) {
                partes.add('($nomeExtra)');
              }
              if (valor != null) partes.add(': $valor');
              return partes.join(' ').replaceAll(' :', ':');
            })
            .join('\n');
        return lines;
      } catch (_) {
        return raw;
      }
    default:
      return raw;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Função pública de entrada
// ─────────────────────────────────────────────────────────────────────────────

/// Exibe o fluxo completo de importação Gemini para a Licitação:
/// 1. Chama o serviço com [pdfPath].
/// 2. Exibe o dialog de revisão com os valores sugeridos × atuais.
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
  final result = await showAudespDialog<GeminiExtractionResult?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.medium,
    builder: (_) => _GeminiLoadingDialog(ref: ref, pdfPath: pdfPath),
  );

  if (result == null || !context.mounted) return null;

  return showGeminiReviewDialog(
    context: context,
    currentValues: currentValues,
    suggestedValues: result,
  );
}

/// Exibe apenas o dialog de revisão, útil para a importação manual (BYO-AI).
Future<Map<String, String>?> showGeminiReviewDialog({
  required BuildContext context,
  required Map<String, String> currentValues,
  required GeminiExtractionResult suggestedValues,
}) {
  return showAudespDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.large,
    builder: (_) => _GeminiReviewDialog(
      fields: kLicitacaoGeminiFields,
      currentValues: currentValues,
      suggestedValues: suggestedValues,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 1 — Progresso (chamada à API Gemini)
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiLoadingDialog extends StatefulWidget {
  final WidgetRef ref;
  final String pdfPath;

  const _GeminiLoadingDialog({required this.ref, required this.pdfPath});

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
        fields: kLicitacaoGeminiFields,
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
                  'O Gemini está lendo o documento e extraindo os campos da licitação. Aguarde…',
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
    _accepted = {
      for (final f in widget.fields)
        f.key:
            widget.suggestedValues[f.key] != null &&
            (widget.currentValues[f.key] ?? '').isEmpty,
    };
    _syncDependentFields();
  }

  void _syncDependentFields() {
    if (_accepted['exigenciaGarantiaLicitantes'] == true &&
        widget.suggestedValues['percentualGarantia'] != null) {
      _accepted['percentualGarantia'] = true;
    }
    if (_accepted['exigenciaIndicesEconomicos'] == true &&
        widget.suggestedValues['indicesEconomicos'] != null) {
      _accepted['indicesEconomicos'] = true;
    }
  }

  void _acceptAll() => setState(
    () => _accepted.updateAll((k, _) => widget.suggestedValues[k] != null),
  );

  void _rejectAll() => setState(() => _accepted.updateAll((_, _) => false));

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

  int get _acceptedCount => _accepted.values.where((v) => v).length;

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
        color: isAccepted ? colorScheme.primaryContainer.withAlpha(80) : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(field.label, style: const TextStyle(fontSize: 12)),
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
