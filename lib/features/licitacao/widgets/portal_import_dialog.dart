import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/template_constants.dart';
import '../../../core/utils/template_generator.dart';
import '../../../shared/widgets/audesp_async_button.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../estimativa/models/estimativa_model.dart';
import '../../estimativa/widgets/estimativa_import_dialog.dart';
import '../csv/csv.dart';

enum PortalType { bll, brConectado }

enum ComplementoType { planilha, estimativa }

/// Abre o diálogo de importação de CSV e retorna a lista de itens parseados,
/// ou null se o usuário cancelou.
Future<List<LicitacaoItemCsvModel>?> showPortalImportDialog(
  BuildContext context,
) {
  return showAudespDialog<List<LicitacaoItemCsvModel>>(
    context: context,
    size: DialogSize.large,
    builder: (_) => const _PortalImportDialog(),
  );
}

class _PortalImportDialog extends StatefulWidget {
  const _PortalImportDialog();

  @override
  State<_PortalImportDialog> createState() => _PortalImportDialogState();
}

class _PortalImportDialogState extends State<_PortalImportDialog> {
  PortalType _portal = PortalType.bll;
  ComplementoType _complementoType = ComplementoType.planilha;

  PlatformFile? _bllClassificacao;

  PlatformFile? _brRelatClassificacao;
  PlatformFile? _brPropostas;

  PlatformFile? _complemento;
  EstimativaModel? _estimativaSelecionada;

  bool _loading = false;
  String? _errorMessage;

  Future<void> _pickEstimativa() async {
    final est = await showEstimativaImportDialog(context);
    if (est == null) return;
    setState(() {
      _estimativaSelecionada = est;
      _errorMessage = null;
    });
  }

  Future<void> _pickFile(String fileKey) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _errorMessage = null;
      switch (fileKey) {
        case CsvFileKeys.bllClassificacao:
          _bllClassificacao = file;
        case CsvFileKeys.brRelatClassificacao:
          _brRelatClassificacao = file;
        case CsvFileKeys.brPropostas:
          _brPropostas = file;
        case _complementoKey:
          _complemento = file;
      }
    });
  }

  static const _complementoKey = 'complemento';

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

  Future<void> _importar() async {
    setState(() => _errorMessage = null);

    // Validação antes de iniciar o trabalho pesado
    if (_portal == PortalType.bll) {
      if (_bllClassificacao?.bytes == null) {
        setState(
          () => _errorMessage =
              'Selecione o arquivo do portal BLL para importar.',
        );
        return;
      }
    } else {
      if (_brRelatClassificacao?.bytes == null || _brPropostas?.bytes == null) {
        setState(
          () => _errorMessage =
              'Selecione os dois arquivos do portal BRConectado para importar.',
        );
        return;
      }
    }
    if (_complementoType == ComplementoType.planilha) {
      if (_complemento?.bytes == null) {
        setState(
          () => _errorMessage =
              'Selecione a planilha complementar para importar.',
        );
        return;
      }
    } else {
      if (_estimativaSelecionada == null) {
        setState(() => _errorMessage = 'Selecione a estimativa para importar.');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final Map<String, List<int>> csvFiles;
      final PortalCsvParser parser;

      if (_portal == PortalType.bll) {
        csvFiles = {CsvFileKeys.bllClassificacao: _bllClassificacao!.bytes!};
        parser = const BllCsvParser();
      } else {
        csvFiles = {
          CsvFileKeys.brRelatClassificacao: _brRelatClassificacao!.bytes!,
          CsvFileKeys.brPropostas: _brPropostas!.bytes!,
        };
        parser = const BrConectadoCsvParser();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      List<LicitacaoItemCsvModel> itens = parser.parse(csvFiles);

      final Map<int, LicitacaoItemCsvModel> complementoMap;

      if (_complementoType == ComplementoType.planilha) {
        complementoMap = const ComplementoCsvParser().parse(
          _complemento!.bytes!,
        );
      } else {
        complementoMap = {};

        int tipoOrcamentoBase = 2; // item
        if (_estimativaSelecionada!.calculoGlobal == 'desc') {
          tipoOrcamentoBase = 3; // maior desconto
        } else if (_estimativaSelecionada!.tipoEstimativa == 'lote') {
          tipoOrcamentoBase = 1; // lote
        }

        final tipoValorBase = tipoOrcamentoBase == 3 ? 'P' : 'M';
        final tipoPropostaBase = tipoOrcamentoBase;
        final calculoGlobal = _estimativaSelecionada!.calculoGlobal;

        if (_estimativaSelecionada!.tipoEstimativa == 'lote') {
          for (final lote in _estimativaSelecionada!.lotes) {
            String dataOrcamento = DateTime.now().toIso8601String().substring(
              0,
              10,
            );
            final datas = lote.itens
                .expand((i) => i.orcamentos)
                .map((o) => o.data)
                .toList();
            if (datas.isNotEmpty) {
              datas.sort();
              dataOrcamento = datas.first;
            }

            complementoMap[lote.numero] = LicitacaoItemCsvModel(
              numeroItem: lote.numero,
              licitantes: const [],
              tipoOrcamento: tipoOrcamentoBase,
              valorEstimado: lote.itens.fold<double>(
                0.0,
                (sum, i) => sum + i.getValorTotal(calculoGlobal),
              ),
              dataOrcamento: dataOrcamento,
              situacaoCompraItemId:
                  1, // Em andamento / Classificado Padrão // TODO
              dataSituacao: DateTime.now().toIso8601String().substring(
                0,
                10,
              ), // TODO
              tipoValor: tipoValorBase,
              tipoProposta: tipoPropostaBase,
            );
          }
        } else {
          for (final item in _estimativaSelecionada!.itens) {
            String dataOrcamento = DateTime.now().toIso8601String().substring(
              0,
              10,
            );
            final datas = item.orcamentos.map((o) => o.data).toList();
            if (datas.isNotEmpty) {
              datas.sort();
              dataOrcamento = datas.first;
            }

            complementoMap[item.numero] = LicitacaoItemCsvModel(
              numeroItem: item.numero,
              licitantes: const [],
              tipoOrcamento: tipoOrcamentoBase,
              valorEstimado: item.getValorReferenciaUnitario(calculoGlobal),
              dataOrcamento: dataOrcamento,
              situacaoCompraItemId:
                  1, // Em andamento / Classificado Padrão // TODO
              dataSituacao: DateTime.now().toIso8601String().substring(
                0,
                10,
              ), // TODO
              tipoValor: tipoValorBase,
              tipoProposta: tipoPropostaBase,
            );
          }
        }
      }

      itens = itens.map((item) {
        final extra = complementoMap[item.numeroItem];
        if (extra == null) return item;
        return item.copyWith(
          tipoOrcamento: extra.tipoOrcamento,
          valorEstimado: extra.valorEstimado,
          dataOrcamento: extra.dataOrcamento,
          situacaoCompraItemId: extra.situacaoCompraItemId,
          dataSituacao: extra.dataSituacao,
          tipoValor: extra.tipoValor,
          tipoProposta: extra.tipoProposta,
        );
      }).toList();

      if (mounted) Navigator.of(context).pop(itens);
    } on CsvParseException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage = 'Erro inesperado ao processar o arquivo: $e',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar Itens'),
      content: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SegmentedButton<PortalType>(
                segments: const [
                  ButtonSegment(
                    value: PortalType.bll,
                    label: Text('BLL'),
                    icon: Icon(Icons.source_outlined),
                  ),
                  ButtonSegment(
                    value: PortalType.brConectado,
                    label: Text('BRConectado'),
                    icon: Icon(Icons.source_outlined),
                  ),
                ],
                selected: {_portal},
                onSelectionChanged: _loading
                    ? null
                    : (s) => setState(() {
                        _portal = s.first;
                        _errorMessage = null;
                      }),
              ),
            ),
            const SizedBox(height: 24),
            if (_portal == PortalType.bll) ...[
              _FilePickerRow(
                label: 'Classificação com itens',
                fileName: _bllClassificacao?.name,
                onPick: _loading
                    ? null
                    : () => _pickFile(CsvFileKeys.bllClassificacao),
              ),
            ] else ...[
              _FilePickerRow(
                label: 'Relatório de classificação',
                fileName: _brRelatClassificacao?.name,
                onPick: _loading
                    ? null
                    : () => _pickFile(CsvFileKeys.brRelatClassificacao),
              ),
              const SizedBox(height: 12),
              _FilePickerRow(
                label: 'Propostas',
                fileName: _brPropostas?.name,
                onPick: _loading
                    ? null
                    : () => _pickFile(CsvFileKeys.brPropostas),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: SegmentedButton<ComplementoType>(
                segments: const [
                  ButtonSegment(
                    value: ComplementoType.planilha,
                    label: Text('Planilha'),
                    icon: Icon(Icons.upload_file_outlined),
                  ),
                  ButtonSegment(
                    value: ComplementoType.estimativa,
                    label: Text('Estimativa'),
                    icon: Icon(Icons.calculate_outlined),
                  ),
                ],
                selected: {_complementoType},
                onSelectionChanged: _loading
                    ? null
                    : (s) => setState(() {
                        _complementoType = s.first;
                        _errorMessage = null;
                      }),
              ),
            ),
            const SizedBox(height: 24),
            if (_complementoType == ComplementoType.planilha) ...[
              Row(
                children: [
                  Expanded(
                    child: _FilePickerRow(
                      label: 'Planilha Complementar',
                      fileName: _complemento?.name,
                      onPick: _loading
                          ? null
                          : () => _pickFile(_complementoKey),
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AudespAsyncButton.icon(
          onPressed: _importar,
          icon: Icons.download_outlined,
          label: 'Importar',
        ),
      ],
    );
  }
}

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
