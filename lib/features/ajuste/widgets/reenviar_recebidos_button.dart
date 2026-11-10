import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../auth/auth_providers.dart';
import '../../auth/widgets/audesp_auth_dialog.dart';
import '../../logs/envios_providers.dart';
import '../../processo/processo_providers.dart';
import '../ajuste_providers.dart';
import '../domain/ajustes_recebidos.dart';
import '../services/ajuste_service.dart';

final ajustesRecebidosProvider =
    FutureProvider.autoDispose<List<AjusteRecebido>>((ref) async {
      final (documentos, envios) = await (
        ref.watch(documentosProcessoProvider.future),
        ref.watch(enviosProcessoProvider.future),
      ).wait;
      return AjusteRecebido.listar(documentos, envios);
    });

/// Reenvia de uma vez os ajustes listados por [AjusteRecebido.listar]
/// (Recebido parado ou RN012 pelo nome do campo). Só aparece quando há algum.
class ReenviarRecebidosButton extends ConsumerStatefulWidget {
  const ReenviarRecebidosButton({super.key});

  @override
  ConsumerState<ReenviarRecebidosButton> createState() =>
      _ReenviarRecebidosButtonState();
}

class _ReenviarRecebidosButtonState
    extends ConsumerState<ReenviarRecebidosButton> {
  bool _enviando = false;

  Future<void> _reenviar(List<AjusteRecebido> recebidos) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Reenviar ${recebidos.length} ajuste(s)?'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estes ajustes ficaram parados em Recebido ou foram rejeitados '
                'só pela RN012_AJUSTE, porque o AUDESP espera o campo '
                '"datavigenciaInicio" e não o nome da documentação. O '
                'documento de cada um será enviado de novo, já com o nome '
                'correto, e receberá um novo protocolo. Os protocolos '
                'anteriores continuam nos logs.',
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in recebidos)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(tituloAjuste(r.ajuste)),
                        subtitle: Text(
                          'Protocolo ${r.envio.protocolo} — '
                          '${switch (r.motivo) {
                            MotivoReenvio.recebido => 'parado em Recebido',
                            MotivoReenvio.vigenciaRejeitada => 'rejeitado pela RN012 (vigência)',
                          }}',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.send),
            label: const Text('Reenviar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final service = ref.read(ajusteServiceProvider);
    final userId = ref.read(localSessionProvider)?.id;
    final container = ProviderScope.containerOf(context, listen: false);
    var enviados = 0;
    final falhas = <String>[];
    setState(() => _enviando = true);
    try {
      await showAudespAuthDialog(
        context,
        ref,
        actionLabel: 'Autenticar e Reenviar',
        onConfirm: (token) async {
          // Um erro não interrompe os demais; o resumo aparece no final.
          for (final r in recebidos) {
            try {
              await service.enviarAjuste(
                ajusteId: r.ajuste.id,
                documentoJson: r.ajuste.documentoJson,
                userId: userId,
              );
              enviados++;
            } catch (e) {
              falhas.add('${tituloAjuste(r.ajuste)}: $e');
            }
          }
        },
      );
    } finally {
      if (enviados > 0 || falhas.isNotEmpty) {
        container.invalidate(documentosProcessoProvider);
        container.invalidate(enviosProvider);
        container.invalidate(ajustesEnviadosProvider);
      }
      if (mounted) setState(() => _enviando = false);
    }
    if (!mounted) return;
    if (falhas.isEmpty) {
      if (enviados > 0) {
        AudespSnackBar.success(context, '$enviados ajuste(s) reenviado(s).');
      }
    } else {
      AudespSnackBar.error(
        context,
        '$enviados ajuste(s) reenviado(s), ${falhas.length} com erro:\n'
        '${falhas.join('\n')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enviando) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final recebidos = ref.watch(ajustesRecebidosProvider).value ?? const [];
    if (recebidos.isEmpty) return const SizedBox.shrink();
    return Badge(
      label: Text('${recebidos.length}'),
      child: AudespIconButton(
        icon: Icons.send_and_archive_outlined,
        tooltip:
            'Reenviar ${recebidos.length} ajuste(s) parados em Recebido ou '
            'rejeitados pelo campo de vigência (RN012)',
        onPressed: () => _reenviar(recebidos),
      ),
    );
  }
}
