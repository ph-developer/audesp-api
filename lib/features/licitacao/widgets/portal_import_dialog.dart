import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../csv/csv.dart';

enum PortalType { bll, brConectado }

/// Abre o diálogo de importação de CSV e retorna a lista de itens parseados,
/// ou null se o usuário cancelou.
Future<List<LicitacaoItemCsvModel>?> showPortalImportDialog(
    BuildContext context) {
  return showDialog<List<LicitacaoItemCsvModel>>(
    context: context,
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

  PlatformFile? _bllClassificacao;

  PlatformFile? _brRelatClassificacao;
  PlatformFile? _brPropostas;

  PlatformFile? _complemento;

  bool _loading = false;
  String? _errorMessage;

  Future<void> _pickFile(String fileKey) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
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
    const content =
        'NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;'
        'ValorUnitarioMenor;CriterioJulgamento;TipoBeneficio;'
        'TipoOrcamento;ValorEstimadoMedia;DataOrcamento;'
        'SituacaoCompraItem;DataSituacao;TipoValor;TipoProposta\r\n'
        '# Colunas do EDITAL: Descricao, MaterialOuServico, Quantidade, UnidadeMedida, ValorUnitarioMenor (Menor Valor Orc.), CriterioJulgamento, TipoBeneficio;;;;;;;;;;;\r\n'
        '# Colunas da LICITACAO: TipoOrcamento, ValorEstimadoMedia (Media dos Orc.), DataOrcamento, SituacaoCompraItem, DataSituacao, TipoValor, TipoProposta;;;;;;;;;;;\r\n'
        '# TipoOrcamento: NAO, GLOBAL, UNITARIO, DESCONTO;;;;;;;;;;;\r\n'
        '# SituacaoCompraItem: ANDAMENTO, HOMOLOGADO, DESERTO, FRACASSADO, ANULADO, REVOGADO, CANCELADO;;;;;;;;;;;\r\n'
        '# DataOrcamento e DataSituacao: formato DD/MM/AAAA;;;;;;;;;;;\r\n'
        '# TipoValor: MOEDA, PERCENTUAL  |  TipoProposta: GLOBAL, UNITARIO, DESCONTO;;;;;;;;;;;\r\n'
        '# Exemplo:;;;;;;;;;;;\r\n'
        '1;Cadeira ergonômica;M;10;UN;800,00;MENOR_PRECO;SEM_BENEFICIO;GLOBAL;850,00;01/01/2025;HOMOLOGADO;15/01/2025;MOEDA;GLOBAL\r\n';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar Template de Itens',
      fileName: 'template_itens.csv',
      allowedExtensions: ['csv'],
      type: FileType.custom,
    );
    if (path == null) return;

    try {
      await File(path).writeAsBytes(content.codeUnits);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao salvar template: $e');
      }
    }
  }

  Future<void> _importar() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, List<int>> csvFiles;
      final PortalCsvParser parser;

      if (_portal == PortalType.bll) {
        if (_bllClassificacao?.bytes == null) {
          setState(() {
            _errorMessage =
                'Selecione o arquivo do portal BLL para importar.';
            _loading = false;
          });
          return;
        }
        csvFiles = {
          CsvFileKeys.bllClassificacao: _bllClassificacao!.bytes!,
        };
        parser = const BllCsvParser();
      } else {
        if (_brRelatClassificacao?.bytes == null ||
            _brPropostas?.bytes == null) {
          setState(() {
            _errorMessage =
                'Selecione os dois arquivos do portal BRConectado para importar.';
            _loading = false;
          });
          return;
        }
        csvFiles = {
          CsvFileKeys.brRelatClassificacao: _brRelatClassificacao!.bytes!,
          CsvFileKeys.brPropostas: _brPropostas!.bytes!,
        };
        parser = const BrConectadoCsvParser();
      }

      if (_complemento?.bytes == null) {
        setState(() {
          _errorMessage =
              'Selecione a planilha de itens complementar para importar.';
          _loading = false;
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300)); // Para mostrar o indicador de loading
      List<LicitacaoItemCsvModel> itens = parser.parse(csvFiles);

      // Merge com planilha complementar.
      final complementoMap =
          const ComplementoCsvParser().parse(_complemento!.bytes!);
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
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado ao processar o arquivo: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar do Portal'),
      content: SizedBox(
        width: 520,
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
                onPick:
                    _loading ? null : () => _pickFile(CsvFileKeys.bllClassificacao),
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
                onPick:
                    _loading ? null : () => _pickFile(CsvFileKeys.brPropostas),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FilePickerRow(
                    label: 'Planilha de Itens',
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13),
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
        FilledButton.icon(
          onPressed: _loading ? null : _importar,
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined, size: 18),
          label: const Text('Importar'),
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
          icon: Icon(
            hasFile ? Icons.swap_horiz : Icons.attach_file,
            size: 16,
          ),
          label: Text(hasFile ? 'Trocar' : 'Selecionar'),
          onPressed: onPick,
        ),
      ],
    );
  }
}
