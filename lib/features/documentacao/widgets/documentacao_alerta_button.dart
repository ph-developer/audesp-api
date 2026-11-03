import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../auth/auth_providers.dart';
import '../documentacao_providers.dart';
import '../domain/documentacao_monitor.dart';

/// Ícone vermelho no menu lateral quando a documentação do AUDESP mudou.
/// Some enquanto não houver alteração pendente de conferência.
class DocumentacaoAlertaButton extends ConsumerWidget {
  const DocumentacaoAlertaButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerta = ref.watch(documentacaoAlertaProvider).value;
    if (alerta == null) return const SizedBox.shrink();
    final cor = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IconButton(
        icon: Icon(Icons.report, color: cor),
        tooltip:
            'A documentação do AUDESP foi alterada.\n'
            'Informe o TI.',
        style: IconButton.styleFrom(
          backgroundColor: cor.withValues(alpha: 0.12),
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _DocumentacaoAlertaDialog(alerta: alerta),
        ),
      ),
    );
  }
}

class _DocumentacaoAlertaDialog extends ConsumerStatefulWidget {
  final DocumentacaoAlerta alerta;

  const _DocumentacaoAlertaDialog({required this.alerta});

  @override
  ConsumerState<_DocumentacaoAlertaDialog> createState() =>
      _DocumentacaoAlertaDialogState();
}

class _DocumentacaoAlertaDialogState
    extends ConsumerState<_DocumentacaoAlertaDialog> {
  bool _salvando = false;

  Future<void> _marcarVerificada() async {
    setState(() => _salvando = true);
    try {
      await marcarDocumentacaoVerificada(ref.read(appSettingsDaoProvider));
      ref.invalidate(documentacaoAlertaProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        AudespSnackBar.show(context, message: 'Erro ao marcar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(localSessionProvider)?.isAdmin == true;
    final detectadaEm = widget.alerta.detectadaEm;
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          Icon(Icons.report, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          const Flexible(child: Text('Documentação do AUDESP alterada')),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A documentação oficial do AUDESP mudou desde a última '
              'conferência. Informe o TI para que o sistema seja revisado.',
              style: theme.textTheme.bodyMedium,
            ),
            if (detectadaEm != null) ...[
              const SizedBox(height: 8),
              Text(
                'Detectada em '
                '${DateFormat('dd/MM/yyyy HH:mm').format(detectadaEm)}.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Alterações',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            for (final alteracao in widget.alerta.alteracoes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $alteracao'),
              ),
            const SizedBox(height: 16),
            const Text(
              'Páginas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(
              '${DocumentacaoFontes.paginaTce}\n${DocumentacaoFontes.paginaApi}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        if (isAdmin)
          TextButton.icon(
            onPressed: _salvando ? null : _marcarVerificada,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Marcar como verificada'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
