import 'package:fluent_ui/fluent_ui.dart';

/// Tipo de status de um documento AUDESP.
enum AppStatus { rascunho, enviado, retificacao }

/// Badge visual para exibir o status de um registro (Rascunho / Enviado / Retificação).
///
/// Uso:
/// ```dart
/// StatusBadge(status: AppStatus.retificacao)
/// StatusBadge.fromFlags(isSent: record.sent, isRetificacao: record.retificacao)
/// ```
class StatusBadge extends StatelessWidget {
  final AppStatus status;

  const StatusBadge({super.key, required this.status});

  factory StatusBadge.fromFlags({
    required bool isSent,
    required bool isRetificacao,
  }) {
    final effective =
        isRetificacao ? AppStatus.retificacao : (isSent ? AppStatus.enviado : AppStatus.rascunho);
    return StatusBadge(status: effective);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final (label, bg, fg) = switch (status) {
      AppStatus.rascunho => (
          'Rascunho',
          const Color(0xFFF5F5F5),
          const Color(0xFF616161),
        ),
      AppStatus.enviado => (
          'Enviado',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
      AppStatus.retificacao => (
          'Retificação',
          theme.accentColor.lightest,
          theme.accentColor.dark,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.typography.caption?.copyWith(color: fg),
      ),
    );
  }
}
