import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/environments.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../shared/widgets/audesp_async_button.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../auth_providers.dart';

/// Exibido antes do envio de qualquer módulo ao AUDESP.
/// Autentica via API (Bearer token) e chama [onConfirm] mediante sucesso.
///
/// Uso:
/// ```dart
/// final ok = await showAudespAuthDialog(context, ref, onConfirm: () async {
///   await enviarDocumento();
/// });
/// ```
Future<bool> showAudespAuthDialog(
  BuildContext context,
  WidgetRef ref, {
  required Future<void> Function(String token) onConfirm,
}) async {
  final result = await showAudespDialog<bool>(
    context: context,
    barrierDismissible: false,
    size: DialogSize.small,
    builder: (_) => _AudespAuthDialog(onConfirm: onConfirm),
  );
  return result == true;
}

class _AudespAuthDialog extends ConsumerStatefulWidget {
  final Future<void> Function(String token) onConfirm;

  const _AudespAuthDialog({required this.onConfirm});

  @override
  ConsumerState<_AudespAuthDialog> createState() => _AudespAuthDialogState();
}

class _AudespAuthDialogState extends ConsumerState<_AudespAuthDialog> {
  String? _error;

  Future<void> _authenticate() async {
    final user = ref.read(localSessionProvider);
    final env = ref.read(environmentProvider);
    final authService = ref.read(authServiceProvider);
    final storage = ref.read(secureStorageServiceProvider);

    if (user == null) return;

    setState(() => _error = null);

    try {
      final password = await storage.getPassword(user.email);
      if (password == null) {
        if (mounted) setState(() => _error = 'Senha não encontrada. Recadastre o perfil.');
        return;
      }

      final token = await authService.loginAudesp(
        email: user.email,
        password: password,
        baseUrl: env.baseUrl,
      );

      await widget.onConfirm(token);

      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = _parseError(e));
    }
  }

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Credenciais inválidas no AUDESP.';
    if (msg.contains('403')) return 'Acesso negado pelo AUDESP.';
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'Sem conexão com o servidor.';
    }
    return 'Erro: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(localSessionProvider);
    final env = ref.watch(environmentProvider);

    return AlertDialog(
      title: const Text('Autenticar no AUDESP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.nome ?? '—'),
            subtitle: Text(user?.email ?? ''),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Ambiente'),
            trailing: Chip(
              label: Text(env.label),
              backgroundColor: env == Environment.piloto
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        AudespAsyncButton.icon(
          onPressed: _authenticate,
          icon: Icons.send_outlined,
          label: 'Autenticar e enviar',
        ),
      ],
    );
  }
}
