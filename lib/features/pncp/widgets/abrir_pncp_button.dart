import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';

/// Abre a página pública do PNCP no navegador padrão.
class AbrirPncpButton extends StatelessWidget {
  final String url;

  const AbrirPncpButton({super.key, required this.url});

  Future<void> _abrir(BuildContext context) async {
    try {
      final resultado = Platform.isWindows
          ? await Process.run('rundll32.exe', [
              'url.dll,FileProtocolHandler',
              url,
            ])
          : await Process.run(Platform.isMacOS ? 'open' : 'xdg-open', [url]);
      if (resultado.exitCode != 0) {
        throw const ProcessException('', [], 'Falha ao abrir o navegador.');
      }
    } catch (e) {
      if (context.mounted) {
        AudespSnackBar.error(context, 'Erro ao abrir o PNCP: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AudespIconButton(
    icon: Icons.open_in_new,
    tooltip: 'Abrir no PNCP\n$url',
    onPressed: () => _abrir(context),
  );
}
