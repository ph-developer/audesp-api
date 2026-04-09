import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_dialog.dart';

/// Abre o diálogo de ajuste em lote do enquadramento ME/EPP.
///
/// Recebe [licitantesUnicos]: mapa de [niPessoa] → dados do licitante
/// (obrigatoriamente com as chaves `niPessoa`, `nomeRazaoSocial` e
/// `declaracaoMEouEPP`).
///
/// Retorna um `Map<String, int>` com [niPessoa] → novo valor de
/// [declaracaoMEouEPP] (1 = ME, 2 = EPP, 3 = Não), ou null se cancelado.
Future<Map<String, int>?> showAjusteMeEppDialog(
  BuildContext context,
  Map<String, Map<String, dynamic>> licitantesUnicos,
) {
  return showAudespDialog<Map<String, int>>(
    context: context,
    size: DialogSize.large,
    builder: (_) => _AjusteMeEppDialog(licitantesUnicos: licitantesUnicos),
  );
}

class _AjusteMeEppDialog extends StatefulWidget {
  final Map<String, Map<String, dynamic>> licitantesUnicos;
  const _AjusteMeEppDialog({required this.licitantesUnicos});

  @override
  State<_AjusteMeEppDialog> createState() => _AjusteMeEppDialogState();
}

class _AjusteMeEppDialogState extends State<_AjusteMeEppDialog> {
  late final Map<String, int> _status;

  @override
  void initState() {
    super.initState();
    _status = {
      for (final entry in widget.licitantesUnicos.entries)
        entry.key: (entry.value['declaracaoMEouEPP'] as num? ?? 3).toInt(),
    };
  }

  void _submit() => Navigator.of(context).pop(Map<String, int>.from(_status));

  @override
  Widget build(BuildContext context) {
    final licitantes = widget.licitantesUnicos.entries.toList();
    return AlertDialog(
      title: const Text('Ajustar ME/EPP'),
      content: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Corrija o enquadramento de cada licitante. '
              'A alteração será aplicada em todos os itens onde ele aparecer.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: licitantes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final entry = licitantes[i];
                  final ni = entry.key;
                  final data = entry.value;
                  final nome = data['nomeRazaoSocial'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (nome.isNotEmpty)
                                Text(
                                  nome,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                ni,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('ME')),
                            ButtonSegment(value: 2, label: Text('EPP')),
                            ButtonSegment(value: 3, label: Text('NÃO')),
                          ],
                          selected: {_status[ni] ?? 3},
                          onSelectionChanged: (s) =>
                              setState(() => _status[ni] = s.first),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
