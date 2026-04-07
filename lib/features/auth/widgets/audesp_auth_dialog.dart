import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/environments.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/secure_storage_service.dart';
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
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
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
  bool _loading = false;
  String? _error;

  Future<void> _authenticate() async {
    final user = ref.read(localSessionProvider);
    final env = ref.read(environmentProvider);
    final authService = ref.read(authServiceProvider);
    final storage = ref.read(secureStorageServiceProvider);

    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final password = await storage.getPassword(user.email);
      if (password == null) {
        setState(() {
          _loading = false;
          _error = 'Senha não encontrada. Recadastre o perfil.';
        });
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
      setState(() {
        _loading = false;
        _error = _parseError(e);
      });
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
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _authenticate,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('Autenticar e enviar'),
        ),
      ],
    );
  }
}
