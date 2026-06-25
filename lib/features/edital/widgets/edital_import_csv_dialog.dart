import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/template_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/template_generator.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_segmented_button.dart';
import '../../estimativa/models/estimativa_model.dart';
import '../../estimativa/widgets/estimativa_import_dialog.dart';
import '../csv/edital_csv.dart';
import '../domain/edital_domain.dart';

enum ImportSource { planilha, estimativa }

/// Abre o diálogo de importação de itens do Edital via planilha CSV.
///
/// [existingCount] número de itens já presentes no formulário.
/// Retorna a lista de [Map<String,dynamic>] pronta para uso no estado
/// de [EditalFormPage], ou null se o usuário cancelou.
Future<List<Map<String, dynamic>>?> showEditalImportCsvDialog(
  BuildContext context, {
  int existingCount = 0,
}) {
  return showAudespDialog<List<Map<String, dynamic>>>(
    context: context,
    size: DialogSize.large,
    builder: (_) => _EditalImportCsvDialog(existingCount: existingCount),
  );
}

class _EditalImportCsvDialog extends StatefulWidget {
  final int existingCount;
  const _EditalImportCsvDialog({required this.existingCount});

  @override
  State<_EditalImportCsvDialog> createState() => _EditalImportCsvDialogState();
}

class _EditalImportCsvDialogState extends State<_EditalImportCsvDialog> {
  ImportSource _source = ImportSource.planilha;
  PlatformFile? _csvFile;
  EstimativaModel? _estimativaSelecionada;
  bool _loading = false;
  String? _errorMessage;

  /// Itens parseados prontos para exibição.
  List<EditalItemCsvModel>? _preview;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _csvFile = result.files.first;
      _errorMessage = null;
      _preview = null;
    });
    await _parse();
  }

  Future<void> _parse() async {
    if (_csvFile?.bytes == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final items = const EditalComplementoCsvParser().parse(_csvFile!.bytes!);
      setState(() => _preview = items);
    } on EditalCsvParseException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage = 'Erro inesperado ao processar o arquivo: $e',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadTemplate() async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Salvar Template de Itens',
      fileName: 'template_itens.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );
    if (path == null) return;
    try {
      final bytes = TemplateGenerator.generate(templateItens);
      await File(path).writeAsBytes(bytes);

      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '""', path]);
      } else if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [path]);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao salvar template: $e');
      }
    }
  }

  void _confirmar() {
    final items = _preview;
    if (items == null || items.isEmpty) return;

    final maps = items
        .map(
          (item) => <String, dynamic>{
            'numeroItem': item.numeroItem,
            'materialOuServico': item.materialOuServico,
            'descricao': item.descricao,
            'quantidade': item.quantidade,
            'unidadeMedida': item.unidadeMedida,
            'valorUnitarioEstimado': item.valorUnitarioEstimado ?? 0.0,
            'valorTotal': item.valorTotal ?? 0.0,
            if (item.tipoBeneficioId != null)
              'tipoBeneficioId': item.tipoBeneficioId,
            if (item.itemCategoriaId != null)
              'itemCategoriaId': item.itemCategoriaId,
            'incentivoProdutivoBasico': false,
            'orcamentoSigiloso': false,
          },
        )
        .toList();

    Navigator.of(context).pop(maps);
  }

  Future<void> _pickEstimativa() async {
    final est = await showEstimativaImportDialog(context);
    if (est == null || !mounted) return;

    setState(() {
      _estimativaSelecionada = est;
      _errorMessage = null;
      _loading = true;
    });

    int deriveTipoBeneficio(bool exclusivoItem, String exclusividadeGlobal) {
      if (exclusividadeGlobal == 'exclusiva') return 1; // Cota exclusiva
      if (exclusividadeGlobal == 'reservada' && exclusivoItem) {
        return 3; // Cota reservada
      }
      return 4; // Sem benefício
    }

    final List<EditalItemCsvModel> novosItens = [];

    if (est.tipoEstimativa == 'lote') {
      for (final lote in est.lotes) {
        novosItens.add(
          EditalItemCsvModel(
            numeroItem: lote.numero,
            materialOuServico: lote.materialOuServico,
            descricao: lote.descricao,
            quantidade: lote.quantidade,
            unidadeMedida: lote.unidade,
            // Unitário do lote = soma do valor total dos itens do lote
            valorUnitarioEstimado: lote.itens.fold<double>(
              0.0,
              (sum, i) => sum + i.getValorTotal(est.calculoGlobal),
            ),
            // Total é unitário * quantidade
            valorTotal:
                lote.itens.fold<double>(
                  0.0,
                  (sum, i) => sum + i.getValorTotal(est.calculoGlobal),
                ) *
                lote.quantidade,
            criterioJulgamentoId: null,
            tipoBeneficioId: deriveTipoBeneficio(
              lote.exclusivoMeEpp,
              est.exclusividadeMeEpp,
            ),
            itemCategoriaId: lote.itemCategoriaId,
          ),
        );
      }
    } else {
      for (final item in est.itens) {
        novosItens.add(
          EditalItemCsvModel(
            numeroItem: item.numero,
            materialOuServico: item.materialOuServico,
            descricao: item.descricao,
            quantidade: item.quantidade,
            unidadeMedida: item.unidade,
            valorUnitarioEstimado: item.getValorReferenciaUnitario(
              est.calculoGlobal,
            ),
            valorTotal: item.getValorTotal(est.calculoGlobal),
            criterioJulgamentoId: null,
            tipoBeneficioId: deriveTipoBeneficio(
              item.exclusivoMeEpp,
              est.exclusividadeMeEpp,
            ),
            itemCategoriaId: item.itemCategoriaId,
          ),
        );
      }
    }

    if (novosItens.isEmpty) {
      setState(() {
        _errorMessage = 'A estimativa selecionada não possui itens.';
        _loading = false;
        _preview = null;
      });
      return;
    }

    setState(() {
      _preview = novosItens;
      _loading = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final withValue =
        preview?.where((i) => i.valorUnitarioEstimado != null).length ?? 0;
    final withoutValue = (preview?.length ?? 0) - withValue;

    return AlertDialog(
      title: const Text('Importar Itens'),
      content: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AudespSegmentedButton<ImportSource>(
                segments: const {
                  ImportSource.planilha: 'Planilha',
                  ImportSource.estimativa: 'Estimativa',
                },
                icons: const {
                  ImportSource.planilha: Icons.upload_file_outlined,
                  ImportSource.estimativa: Icons.calculate_outlined,
                },
                selected: {_source},
                onSelectionChanged: _loading
                    ? null
                    : (s) => setState(() {
                        _source = s.first;
                        _errorMessage = null;
                        _preview = null;
                      }),
              ),
            ),
            const SizedBox(height: 24),
            // ── Seletor ───────────────────────────────────────
            if (_source == ImportSource.planilha) ...[
              Row(
                children: [
                  Expanded(
                    child: _FilePickerRow(
                      label: 'Planilha de Itens do Edital',
                      fileName: _csvFile?.name,
                      onPick: _loading ? null : _pickFile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Baixar Template',
                    child: IconButton.outlined(
                      icon: const Icon(Icons.download_outlined, size: 18),
                      onPressed: _loading ? null : _downloadTemplate,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _EstimativaPickerRow(
                estimativa: _estimativaSelecionada,
                onPick: _loading ? null : _pickEstimativa,
              ),
            ],

            // ── Mensagem de erro ─────────────────────────────────────────
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Loading ──────────────────────────────────────────────────
            if (_loading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],

            // ── Resumo + Tabela de pré-visualização ──────────────────────
            if (preview != null && !_loading) ...[
              const SizedBox(height: 16),
              _SummaryRow(
                total: preview.length,
                withValue: withValue,
                withoutValue: withoutValue,
              ),
              if (withoutValue > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$withoutValue item(s) sem valor unitário – '
                        'serão importados com valor zerado para '
                        'preenchimento manual posterior.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.existingCount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Os ${widget.existingCount} item(s) já '
                        'cadastrado(s) serão substituídos.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: _PreviewTable(items: preview),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: (_preview != null && _preview!.isNotEmpty && !_loading)
              ? _confirmar
              : null,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar Importação'),
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _FilePickerRow extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback? onPick;

  const _FilePickerRow({
    required this.label,
    required this.fileName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              if (hasFile)
                Text(
                  fileName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Nenhum arquivo selecionado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          icon: Icon(hasFile ? Icons.swap_horiz : Icons.attach_file, size: 16),
          label: Text(hasFile ? 'Trocar' : 'Selecionar'),
          onPressed: onPick,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total;
  final int withValue;
  final int withoutValue;

  const _SummaryRow({
    required this.total,
    required this.withValue,
    required this.withoutValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: '$total itens encontrados',
          icon: Icons.list_alt,
          color: Theme.of(context).colorScheme.primaryContainer,
          textColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(width: 8),
        _Chip(
          label: '$withValue com valor',
          icon: Icons.attach_money,
          color: Theme.of(context).colorScheme.secondaryContainer,
          textColor: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        if (withoutValue > 0) ...[
          const SizedBox(width: 8),
          _Chip(
            label: '$withoutValue sem valor',
            icon: Icons.money_off,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            textColor: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }
}

class _PreviewTable extends StatelessWidget {
  final List<EditalItemCsvModel> items;
  const _PreviewTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columnSpacing: 16,
      headingRowHeight: 36,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 48,
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Descrição')),
        DataColumn(label: Text('T')),
        DataColumn(label: Text('Cat.')),
        DataColumn(label: Text('Qtd')),
        DataColumn(label: Text('UN')),
        DataColumn(label: Text('Valor Unit. (Menor)')),
      ],
      rows: items.map((item) {
        final semValor = item.valorUnitarioEstimado == null;
        final rowColor = semValor
            ? WidgetStatePropertyAll(
                Theme.of(context).colorScheme.tertiaryContainer.withAlpha(80),
              )
            : null;
        return DataRow(
          color: rowColor,
          cells: [
            DataCell(Text('${item.numeroItem}')),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  item.descricao,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
            DataCell(Text(item.materialOuServico)),
            DataCell(
              Text(
                item.itemCategoriaId != null
                    ? (kItemCategoria[item.itemCategoriaId] ?? '?')
                    : '—',
              ),
            ),
            DataCell(Text(formatNumberBR(item.quantidade))),
            DataCell(Text(item.unidadeMedida)),
            DataCell(
              semValor
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        const Text('—'),
                      ],
                    )
                  : Text(formatBRL(item.valorUnitarioEstimado)),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _EstimativaPickerRow extends StatelessWidget {
  final EstimativaModel? estimativa;
  final VoidCallback? onPick;

  const _EstimativaPickerRow({required this.estimativa, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasEst = estimativa != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimativa Base',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 2),
              if (hasEst)
                Text(
                  'Estimativa ${estimativa!.numero}/${estimativa!.ano} - ${estimativa!.tipoEstimativa}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Nenhuma estimativa selecionada',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          icon: Icon(
            hasEst ? Icons.swap_horiz : Icons.calculate_outlined,
            size: 16,
          ),
          label: Text(hasEst ? 'Trocar' : 'Selecionar'),
          onPressed: onPick,
        ),
      ],
    );
  }
}
