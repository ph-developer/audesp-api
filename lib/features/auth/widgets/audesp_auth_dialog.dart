import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/environments.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../auth_providers.dart';

/// Exibido antes do envio de qualquer mÃ³dulo ao AUDESP.
/// Autentica via API (Bearer token) e chama [onConfirm] mediante sucesso.
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
          _error = 'Senha nÃ£o encontrada. Recadastre o perfil.';
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
    if (msg.contains('401')) return 'Credenciais invÃ¡lidas no AUDESP.';
    if (msg.contains('403')) return 'Acesso negado pelo AUDESP.';
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'Sem conexÃ£o com o servidor.';
    }
    return 'Erro: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(localSessionProvider);
    final env = ref.watch(environmentProvider);

    return ContentDialog(
      title: const Text('Autenticar no AUDESP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nome ?? 'â€”',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.cloud_outlined, size: 20),
              const SizedBox(width: 8),
              const Text('Ambiente: '),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: env == Environment.piloto
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: env == Environment.piloto
                        ? const Color(0xFFFF9800)
                        : const Color(0xFF4CAF50),
                  ),
                ),
                child: Text(
                  env.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: env == Environment.piloto
                        ? const Color(0xFFE65100)
                        : const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: Text(_error!),
              severity: InfoBarSeverity.error,
            ),
          ],
        ],
      ),
      actions: [
        Button(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _authenticate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.send_outlined, size: 16),
                ),
              const Text('Autenticar e enviar'),
            ],
          ),
        ),
      ],
    );
  }
}
