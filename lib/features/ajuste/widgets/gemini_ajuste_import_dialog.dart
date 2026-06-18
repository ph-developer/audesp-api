import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/audesp_dialog.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/database/database_providers.dart';
import '../domain/ajuste_domain.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Campos extraídos pelo Gemini para o Ajuste (Contrato)
// ─────────────────────────────────────────────────────────────────────────────

final _kAjusteFields = <GeminiField>[
  GeminiField(
    key: 'tipoContratoId',
    label: 'Tipo de Contrato',
    hint: 'Código numérico: 1=Contrato, 2=Comodato, 3=Arrendamento, 4=Concessão, 5=Termo Adesão, 7=Empenho, 8=Outros, 12=Carta Contrato',
  ),
  GeminiField(
    key: 'numeroContratoEmpenho',
    label: 'Número do Contrato/Empenho',
    hint: 'Apenas o número SEQUENCIAL do contrato, SEM o ano. Exemplo: se no texto estiver "184/2026", retorne apenas "184".',
  ),
  GeminiField(
    key: 'anoContrato',
    label: 'Ano do Contrato',
    hint: 'formato YYYY',
  ),
  GeminiField(
    key: 'processo',
    label: 'Número do Processo',
  ),
  GeminiField(
    key: 'categoriaProcessoId',
    label: 'Categoria do Processo',
    hint: 'Retorne o código numérico: 1=Cessão, 2=Compras, 3=TIC, 4=Internacional, 5=Locação Imóveis, 6=Mão de Obra, 7=Obras, 8=Serviços, 9=Serviços Engenharia, 10=Saúde, 11=Alienação.',
  ),
  GeminiField(
    key: 'niFornecedor',
    label: 'CNPJ/CPF do Fornecedor',
    hint: 'Apenas números',
  ),
  GeminiField(
    key: 'nomeRazaoSocialFornecedor',
    label: 'Nome/Razão Social do Fornecedor',
  ),
  GeminiField(
    key: 'tipoObjetoContrato',
    label: 'Tipo de Objeto do Contrato',
    hint: 'Retorne o código numérico: 1=Permissão, 2=Concessão, 3=Equipamentos, 4=Mat Expediente, 5=Medicamentos, 6=Mat Hospitalar, 7=Mat Escolar, 8=Uniforme, 9=Alimentos, 10=Combustíveis, 11=Outros Materiais, 12=Compras TIC, 13=Serviços TIC, 14=SIAFIC, 15=Internacional, 16=Locação imóveis, 17=Locação mão de obra, 18=Aterro, 19=Obras/Engenharia, 20=Coleta Lixo, 21=Limpeza urbana, 22=Transporte escolar, 23=Publicidade, 24=Passagens, 25=Consultoria, 26=Op Crédito, 27=Outros serviços, 28=Serv Saúde, 29=Alienação.',
  ),
  GeminiField(
    key: 'objetoContrato',
    label: 'Objeto do Contrato',
    hint: 'Descrição detalhada do objeto',
  ),
  GeminiField(
    key: 'itens',
    label: 'Itens Contratados',
    hint: 'Lista de números sequenciais dos itens contratados separados por vírgula (Ex: 1, 2, 3)',
  ),
  GeminiField(
    key: 'valorInicial',
    label: 'Valor Inicial (R\$)',
    hint: 'Apenas os números formatados no padrão brasileiro. Exemplo: 15.000,00',
  ),
  GeminiField(
    key: 'dataAssinatura',
    label: 'Data de Assinatura',
    hint: 'formato dd/MM/yyyy',
  ),
  GeminiField(
    key: 'dataVigenciaInicio',
    label: 'Início da Vigência',
    hint: 'formato dd/MM/yyyy',
  ),
  GeminiField(
    key: 'dataVigenciaFim',
    label: 'Fim da Vigência',
    hint: 'formato dd/MM/yyyy',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helper — converte valor bruto em descrição legível para a tabela de revisão
// ─────────────────────────────────────────────────────────────────────────────

String _displayValue(String key, String raw) {
  if (raw.isEmpty) return raw;
  switch (key) {
    case 'tipoContratoId':
      final id = int.tryParse(raw);
      return id != null ? (kTipoContrato[id] ?? raw) : raw;
    case 'categoriaProcessoId':
      final id = int.tryParse(raw);
      return id != null ? (kCategoriaProcesso[id] ?? raw) : raw;
    case 'tipoObjetoContrato':
      final id = int.tryParse(raw);
      return id != null ? (kTipoObjetoContrato[id] ?? raw) : raw;
    default:
      return raw;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Função pública de entrada
// ─────────────────────────────────────────────────────────────────────────────

Future<Map<String, String>?> showGeminiAjusteImportDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String filePath,
  required Map<String, String> currentValues,
}) async {
  final result = await showAudespDialog<GeminiExtractionResult?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.medium,
    builder: (_) => _GeminiLoadingDialog(
      ref: ref,
      filePath: filePath,
    ),
  );

  if (result == null || !context.mounted) return null;

  return showAudespDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.large,
    builder: (_) => _GeminiReviewDialog(
      fields: _kAjusteFields,
      currentValues: currentValues,
      suggestedValues: result,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog 1 — Progresso
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiLoadingDialog extends StatefulWidget {
  final WidgetRef ref;
  final String filePath;

  const _GeminiLoadingDialog({
    required this.ref,
    required this.filePath,
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
      final result = await service.extractFromFile(
        filePath: widget.filePath,
        fields: _kAjusteFields,
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
          const Text('Analisando Documento...'),
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
                Text('O Gemini está lendo o documento e extraindo os campos do ajuste. Aguarde…'),
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
