import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../auth/auth_providers.dart';
import '../../processo/processo_providers.dart';
import '../edital_providers.dart';

/// Oculta o edital (e o processo dele) após pedir um motivo opcional.
Future<void> ocultarEdital(
  BuildContext context,
  WidgetRef ref,
  Edital edital,
) async {
  final motivo = await showAudespDialog<String>(
    context: context,
    builder: (_) => const _OcultarDialog(),
  );
  if (motivo == null) return;
  try {
    await ref
        .read(editaisDaoProvider)
        .ocultar(
          edital.id,
          userId: ref.read(localSessionProvider)?.id,
          motivo: motivo,
        );
    _atualizar(ref);
    if (context.mounted) {
      AudespSnackBar.success(context, 'Edital oculto em Processos.');
    }
  } catch (e) {
    if (context.mounted) AudespSnackBar.error(context, 'Erro ao ocultar: $e');
  }
}

Future<void> reexibirEdital(
  BuildContext context,
  WidgetRef ref,
  Edital edital,
) async {
  try {
    await ref.read(editaisDaoProvider).reexibir(edital.id);
    _atualizar(ref);
    if (context.mounted) {
      AudespSnackBar.success(context, 'Edital voltou a ser exibido.');
    }
  } catch (e) {
    if (context.mounted) AudespSnackBar.error(context, 'Erro ao reexibir: $e');
  }
}

void _atualizar(WidgetRef ref) {
  ref.invalidate(processosProvider);
  ref.invalidate(editaisDraftProvider);
  ref.invalidate(editaisEnviadosProvider);
  ref.invalidate(editaisOcultosProvider);
}

class _OcultarDialog extends StatefulWidget {
  const _OcultarDialog();

  @override
  State<_OcultarDialog> createState() => _OcultarDialogState();
}

class _OcultarDialogState extends State<_OcultarDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ocultar edital'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O processo sai das pendências e das listas, e o edital deixa de '
            'ser oferecido para licitação, ata e ajuste. Nada é apagado: ele '
            'pode ser reexibido em Processos (visão "Todos") ou em Editais '
            '(aba "Ocultos").',
          ),
          const SizedBox(height: 12),
          AudespTextField(
            label: 'Motivo (opcional)',
            controller: _motivoCtrl,
            maxLength: 500,
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_motivoCtrl.text.trim()),
          child: const Text('Ocultar'),
        ),
      ],
    );
  }
}
