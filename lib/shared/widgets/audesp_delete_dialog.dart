import 'package:flutter/material.dart';

/// Exibe um diálogo de confirmação de exclusão padronizado para a AUDESP.
///
/// Retorna `true` quando o usuário confirma a exclusão, `false` caso cancele.
/// Opcionalmente, executa [onConfirm] ao confirmar antes de retornar.
///
/// Exemplo:
/// ```dart
/// final confirmed = await showAudespDeleteDialog(
///   context: context,
///   title: 'Excluir Edital',
///   entityName: 'ED-001/2026',
///   entityLabel: 'o edital',
///   onConfirm: () => _deleteEdital(edital),
/// );
/// if (confirmed) {
///   // ação pós-exclusão
/// }
/// ```
Future<bool> showAudespDeleteDialog({
  required BuildContext context,
  required String title,
  required String entityName,
  String? entityLabel,
  VoidCallback? onConfirm,
}) async {
  final content = entityLabel != null
      ? 'Deseja excluir $entityLabel "$entityName"? Esta acao nao pode ser desfeita.'
      : 'Deseja excluir "$entityName"? Esta acao nao pode ser desfeita.';

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );

  final confirmed = result ?? false;
  if (confirmed && onConfirm != null) {
    onConfirm();
  }
  return confirmed;
}
