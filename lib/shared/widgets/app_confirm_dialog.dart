import 'package:fluent_ui/fluent_ui.dart';

/// Diálogo de confirmação reutilizável baseado em [ContentDialog].
///
/// Uso:
/// ```dart
/// final confirmed = await showAppConfirmDialog(
///   context,
///   title: 'Excluir registro?',
///   body: 'Esta ação não pode ser desfeita.',
///   confirmLabel: 'Excluir',
///   isDestructive: true,
/// );
/// if (confirmed == true) { ... }
/// ```
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AppConfirmDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
}

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: isDestructive
              ? ButtonStyle(
                  backgroundColor:
                      const WidgetStatePropertyAll(Color(0xFFD32F2F)),
                  foregroundColor:
                      const WidgetStatePropertyAll(Color(0xFFFFFFFF)),
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
