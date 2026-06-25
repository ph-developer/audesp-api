import 'package:flutter/material.dart';

import 'audesp_icon_button.dart';

/// Shared card for document-like list rows.
class DocumentCard extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final String title;
  final Widget? subtitle;
  final List<Widget> chips;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onNavigate;
  final VoidCallback? onTap;

  const DocumentCard({
    super.key,
    this.icon,
    this.leading,
    this.iconBackgroundColor,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.chips = const [],
    this.onDelete,
    this.onEdit,
    this.onNavigate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveLeading =
        leading ??
        (icon != null
            ? CircleAvatar(
                backgroundColor: iconBackgroundColor,
                child: Icon(icon, color: iconColor),
              )
            : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: effectiveLeading,
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: subtitle,
        trailing: _hasTrailing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...chips,
                  if (chips.isNotEmpty) const SizedBox(width: 4),
                  if (onDelete != null)
                    AudespIconButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Excluir',
                      color: colorScheme.error,
                      onPressed: onDelete,
                    ),
                  if (onEdit != null)
                    AudespIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Editar',
                      onPressed: onEdit,
                    ),
                  if (onNavigate != null)
                    AudespIconButton(
                      icon: Icons.arrow_forward_ios,
                      tooltip: 'Abrir',
                      onPressed: onNavigate,
                    ),
                ],
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  bool get _hasTrailing =>
      chips.isNotEmpty ||
      onDelete != null ||
      onEdit != null ||
      onNavigate != null;
}
