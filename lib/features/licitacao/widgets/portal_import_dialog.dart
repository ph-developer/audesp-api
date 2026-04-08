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
  PlatformFile? _bllVencedores;

  PlatformFile? _brRelatClassificacao;
  PlatformFile? _brPropostas;

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
        case CsvFileKeys.bllVencedores:
          _bllVencedores = file;
        case CsvFileKeys.brRelatClassificacao:
          _brRelatClassificacao = file;
        case CsvFileKeys.brPropostas:
          _brPropostas = file;
      }
    });
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
        if (_bllClassificacao?.bytes == null || _bllVencedores?.bytes == null) {
          setState(() {
            _errorMessage =
                'Selecione os dois arquivos do portal BLL para importar.';
            _loading = false;
          });
          return;
        }
        csvFiles = {
          CsvFileKeys.bllClassificacao: _bllClassificacao!.bytes!,
          CsvFileKeys.bllVencedores: _bllVencedores!.bytes!,
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

      await Future.delayed(const Duration(milliseconds: 300)); // Para mostrar o indicador de loading
      final itens = parser.parse(csvFiles);

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
                label: '1. Classificação com itens',
                fileName: _bllClassificacao?.name,
                onPick:
                    _loading ? null : () => _pickFile(CsvFileKeys.bllClassificacao),
              ),
              const SizedBox(height: 12),
              _FilePickerRow(
                label: '2. Relatório de vencedores',
                fileName: _bllVencedores?.name,
                onPick:
                    _loading ? null : () => _pickFile(CsvFileKeys.bllVencedores),
              ),
            ] else ...[
              _FilePickerRow(
                label: '1. Relatório de classificação',
                fileName: _brRelatClassificacao?.name,
                onPick: _loading
                    ? null
                    : () => _pickFile(CsvFileKeys.brRelatClassificacao),
              ),
              const SizedBox(height: 12),
              _FilePickerRow(
                label: '2. Propostas',
                fileName: _brPropostas?.name,
                onPick:
                    _loading ? null : () => _pickFile(CsvFileKeys.brPropostas),
              ),
            ],
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
