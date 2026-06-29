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
    hint:
        'Código numérico: 1=Contrato, 2=Comodato, 3=Arrendamento, 4=Concessão, 5=Termo Adesão, 7=Empenho, 8=Outros, 12=Carta Contrato',
  ),
  GeminiField(
    key: 'numeroContratoEmpenho',
    label: 'Número do Contrato/Empenho',
    hint:
        'Apenas o número SEQUENCIAL do contrato, SEM o ano. Exemplo: se no texto estiver "184/2026", retorne apenas "184".',
  ),
  GeminiField(
    key: 'anoContrato',
    label: 'Ano do Contrato',
    hint: 'formato YYYY',
  ),
  GeminiField(key: 'processo', label: 'Número do Processo'),
  GeminiField(
    key: 'categoriaProcessoId',
    label: 'Categoria do Processo',
    hint:
        'Retorne o código numérico: 1=Cessão, 2=Compras, 3=TIC, 4=Internacional, 5=Locação Imóveis, 6=Mão de Obra, 7=Obras, 8=Serviços, 9=Serviços Engenharia, 10=Saúde, 11=Alienação.',
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
    hint:
        'Retorne o código numérico: 1=Permissão, 2=Concessão, 3=Equipamentos, 4=Mat Expediente, 5=Medicamentos, 6=Mat Hospitalar, 7=Mat Escolar, 8=Uniforme, 9=Alimentos, 10=Combustíveis, 11=Outros Materiais, 12=Compras TIC, 13=Serviços TIC, 14=SIAFIC, 15=Internacional, 16=Locação imóveis, 17=Locação mão de obra, 18=Aterro, 19=Obras/Engenharia, 20=Coleta Lixo, 21=Limpeza urbana, 22=Transporte escolar, 23=Publicidade, 24=Passagens, 25=Consultoria, 26=Op Crédito, 27=Outros serviços, 28=Serv Saúde, 29=Alienação.',
  ),
  GeminiField(
    key: 'objetoContrato',
    label: 'Objeto do Contrato',
    hint: 'Descrição detalhada do objeto',
  ),
  GeminiField(
    key: 'itens',
    label: 'Itens Contratados',
    hint:
        'Lista de números sequenciais dos itens contratados separados por vírgula (Ex: 1, 2, 3)',
  ),
  GeminiField(
    key: 'fonteRecursosContratacao',
    label: 'Fontes de Recurso',
    hint:
        'Lista de códigos da fonte de recurso separados por vírgula. Em "Fonte de Recurso e Aplicação: 01/11000", a fonte seria 01, retorne "1". Use apenas códigos do domínio AUDESP: 1, 2, 3, 4, 5, 6, 7, 8, 91, 92, 93, 94, 95, 96, 97, 98.',
  ),
  GeminiField(
    key: 'despesas',
    label: 'Classificações de Despesa',
    hint:
        'Lista de classificações de despesa separadas por vírgula, sempre com 8 dígitos e sem pontos. Exemplo: "4.4.90.52.99" deve retornar "44905299". Ignore unidade orçamentária anterior, como "02.11.02", trazendo sempre os ultimos 8 dígitos.',
  ),
  GeminiField(
    key: 'valorInicial',
    label: 'Valor Inicial (R\$)',
    hint:
        'Apenas os números formatados no padrão brasileiro. Exemplo: 15.000,00',
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
    key: 'prazoVigenciaMeses',
    label: 'Prazo de Vigência',
    hint:
        'Prazo em meses ou dias. Se o contrato disser "12 meses", retorne o número de meses (ex.: "12"). '
        'Se disser "90 dias", retorne o número de dias seguido de "d" (ex.: "90d"). '
        'Se disser "1 ano", retorne o numero de meses. '
        'Prefira sempre meses quando ambas informações estiverem disponíveis.',
  ),
  GeminiField(
    key: 'dataVigenciaFim',
    label: 'Fim da Vigência',
    hint: 'Campo calculado com base na data de início e no prazo de vigência.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helper — remove prefixo numérico de labels como "1 – Contrato" → "Contrato"
// ─────────────────────────────────────────────────────────────────────────────

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

/// Calcula o fim da vigência a partir de data de início (dd/MM/yyyy) + prazo.
/// [prazoRaw] pode ser "12" (meses) ou "90d" (dias). Retorna dd/MM/yyyy ou vazio.
String _calcularDataVigenciaFim(String startRaw, String prazoRaw) {
  if (startRaw.isEmpty || prazoRaw.isEmpty) return '';
  try {
    final parts = startRaw.split('/');
    if (parts.length != 3) return '';
    final dia = int.tryParse(parts[0]);
    final mes = int.tryParse(parts[1]);
    final ano = int.tryParse(parts[2]);
    if (dia == null || mes == null || ano == null) return '';
    var start = DateTime(ano, mes, dia);

    if (prazoRaw.endsWith('d')) {
      final dias = int.tryParse(prazoRaw.replaceAll(RegExp(r'\D'), ''));
      if (dias == null || dias <= 0) return '';
      start = DateTime(start.year, start.month, start.day + dias);
    } else {
      final meses = int.tryParse(prazoRaw.replaceAll(RegExp(r'\D'), ''));
      if (meses == null || meses <= 0) return '';
      start = DateTime(start.year, start.month + meses, start.day);
    }

    return '${start.day.toString().padLeft(2, '0')}/'
        '${start.month.toString().padLeft(2, '0')}/'
        '${start.year}';
  } catch (_) {
    return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper — converte valor bruto em descrição legível para a tabela de revisão
// ─────────────────────────────────────────────────────────────────────────────

String _displayValue(String key, String raw) {
  if (raw.isEmpty) return raw;
  switch (key) {
    case 'tipoContratoId':
      {
        final id = int.tryParse(raw);
        return id != null ? (_stripIdPrefix(kTipoContrato[id] ?? raw)) : raw;
      }
    case 'categoriaProcessoId':
      {
        final id = int.tryParse(raw);
        return id != null
            ? (_stripIdPrefix(kCategoriaProcesso[id] ?? raw))
            : raw;
      }
    case 'tipoObjetoContrato':
      {
        final id = int.tryParse(raw);
        return id != null
            ? (_stripIdPrefix(kTipoObjetoContrato[id] ?? raw))
            : raw;
      }
    case 'prazoVigenciaMeses':
      if (raw.endsWith('d')) {
        final dias = raw.replaceAll(RegExp(r'\D'), '');
        return '$dias dias';
      }
      return '$raw meses';
    case 'fonteRecursosContratacao':
      return RegExp(r'\d+')
          .allMatches(raw)
          .map((m) => int.tryParse(m.group(0)!))
          .whereType<int>()
          .where(kFonteRecursoAjuste.containsKey)
          .map((id) => _padFonteLabel(id, kFonteRecursoAjuste[id]!))
          .join(', ');
    case 'niFornecedor':
      {
        final digits = raw.replaceAll(RegExp(r'\D'), '');
        if (digits.length == 11) {
          return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
              '${digits.substring(6, 9)}-${digits.substring(9)}';
        } else if (digits.length == 14) {
          return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
              '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
              '${digits.substring(12)}';
        }
        return digits;
      }
    case 'despesas':
      return raw
          .split(RegExp(r'[,\s]+'))
          .where((s) => s.isNotEmpty)
          .map((s) {
            final digits = s.replaceAll(RegExp(r'\D'), '');
            return digits.length > 8
                ? digits.substring(digits.length - 8)
                : digits;
          })
          .join(', ');
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
    builder: (_) => _GeminiLoadingDialog(ref: ref, filePath: filePath),
  );

  if (result == null || !context.mounted) return null;

  // Calcula fim da vigência com base na data de início + prazo encontrado
  if (result['prazoVigenciaMeses'] != null) {
    final calc = _calcularDataVigenciaFim(
      currentValues['dataVigenciaInicio'] ?? '',
      result['prazoVigenciaMeses']!,
    );
    if (calc.isNotEmpty) result['dataVigenciaFim'] = calc;
  }

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

  const _GeminiLoadingDialog({required this.ref, required this.filePath});

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
                  'O Gemini está lendo o documento e extraindo os campos do ajuste. Aguarde…',
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
