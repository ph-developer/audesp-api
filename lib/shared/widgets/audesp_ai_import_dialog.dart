import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audesp_dialog.dart';
import 'audesp_segmented_button.dart';

enum AiImportMode { auto, manual }

class AiGenericImportResult<T> {
  final AiImportMode mode;
  final String? jsonResponse;
  final String? filePath;
  final T? extraState;

  AiGenericImportResult({
    required this.mode,
    this.jsonResponse,
    this.filePath,
    this.extraState,
  });
}

Future<AiGenericImportResult<T>?> showAudespAiImportDialog<T>(
  BuildContext context, {
  required String title,
  required String promptText,
  T? initialExtraState,
  Widget Function(T? state, ValueChanged<T?> onChanged)? extraOptionsBuilder,
}) {
  return showAudespDialog<AiGenericImportResult<T>?>(
    context: context,
    size: DialogSize.medium,
    barrierDismissible: false,
    builder: (_) => _AudespAiImportDialog<T>(
      title: title,
      promptText: promptText,
      initialExtraState: initialExtraState,
      extraOptionsBuilder: extraOptionsBuilder,
    ),
  );
}

class _AudespAiImportDialog<T> extends StatefulWidget {
  final String title;
  final String promptText;
  final T? initialExtraState;
  final Widget Function(T? state, ValueChanged<T?> onChanged)? extraOptionsBuilder;

  const _AudespAiImportDialog({
    required this.title,
    required this.promptText,
    this.initialExtraState,
    this.extraOptionsBuilder,
  });

  @override
  State<_AudespAiImportDialog<T>> createState() => _AudespAiImportDialogState<T>();
}

class _AudespAiImportDialogState<T> extends State<_AudespAiImportDialog<T>> {
  AiImportMode _mode = AiImportMode.auto;
  final _jsonController = TextEditingController();
  String? _filePath;
  String? _fileName;
  T? _extraState;

  @override
  void initState() {
    super.initState();
    _extraState = widget.initialExtraState;
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: widget.promptText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prompt copiado para a área de transferência!'),
        ),
      );
    }
  }

  void _processar() {
    if (_mode == AiImportMode.manual) {
      final text = _jsonController.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, cole o JSON de resposta da sua IA.'),
          ),
        );
        return;
      }
      Navigator.pop(
        context,
        AiGenericImportResult<T>(
          mode: _mode,
          jsonResponse: text,
          extraState: _extraState,
        ),
      );
    } else {
      if (_filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione um arquivo (PDF/Word).'),
          ),
        );
        return;
      }
      Navigator.pop(
        context,
        AiGenericImportResult<T>(
          mode: _mode,
          filePath: _filePath,
          extraState: _extraState,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AudespSegmentedButton<AiImportMode>(
                segments: const {
                  AiImportMode.auto: 'Gemini Integrado',
                  AiImportMode.manual: 'Usar outra IA (Manual)',
                },
                selected: {_mode},
                onSelectionChanged: (v) => setState(() => _mode = v.first),
                width: double.infinity,
              ),
              const SizedBox(height: 24),

              if (_mode == AiImportMode.auto) ...[
                const Text(
                  'O Gemini extrairá automaticamente as informações do documento selecionado.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Selecionar Arquivo (PDF/Word)'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _fileName ?? 'Nenhum arquivo selecionado.',
                        style: TextStyle(
                          color: _fileName == null ? Colors.grey : null,
                          fontStyle: _fileName == null
                              ? FontStyle.italic
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  '1. Copie o prompt gerado abaixo.\n'
                  '2. Acesse sua IA de preferência (ex: Gemini, ChatGPT, Claude).\n'
                  '3. Envie o documento desejado (PDF/Word) juntamente com o prompt copiado.\n'
                  '4. Cole a resposta (JSON) gerada pela IA na área de texto inferior.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Prompt:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.promptText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _copyPrompt,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar Prompt'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Resposta JSON da IA:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _jsonController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Cole aqui o JSON gerado pela sua IA...',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ],
              if (widget.extraOptionsBuilder != null) ...[
                const SizedBox(height: 24),
                widget.extraOptionsBuilder!(_extraState, (v) {
                  setState(() => _extraState = v);
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_mode == AiImportMode.auto && _filePath == null)
              ? null
              : _processar,
          child: const Text('Avançar'),
        ),
      ],
    );
  }
}
