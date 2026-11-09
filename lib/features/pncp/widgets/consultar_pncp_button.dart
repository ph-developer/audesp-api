import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/app_modules.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../auth/auth_providers.dart';
import '../pncp_providers.dart';

class ConsultarPncpButton extends ConsumerWidget {
  final String modulo;

  const ConsultarPncpButton({super.key, this.modulo = '/edital'});

  Future<void> _consultar(BuildContext context, WidgetRef ref) async {
    try {
      final novas = await ref.read(pncpConsultaProvider.notifier).consultar();
      if (!context.mounted || novas == null) return;
      AudespSnackBar.success(
        context,
        'Consulta ao PNCP concluída. ${novas.compras} compra(s) nova(s), '
        '${novas.contratos} contrato(s) novo(s) e ${novas.atas} ata(s) nova(s).',
      );
    } catch (e) {
      if (context.mounted) AudespSnackBar.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(localSessionProvider);
    if (user == null || !canAccessLocation(user, '$modulo/new')) {
      return const SizedBox.shrink();
    }
    final config = ref.watch(pncpConfigProvider).value;
    if (config?.configurado != true) return const SizedBox.shrink();
    final consulta = ref.watch(pncpConsultaProvider);
    if (consulta.executando) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return AudespIconButton(
      icon: consulta.erro != null ? Icons.sync_problem : Icons.travel_explore,
      color: consulta.erro != null ? Theme.of(context).colorScheme.error : null,
      tooltip: consulta.erro != null
          ? 'A última consulta ao PNCP falhou: ${consulta.erro}\n'
                'Clique para tentar de novo.'
          : config!.ultimaConsultaEm == null
          ? 'Consultar PNCP'
          : 'Consultar PNCP (última consulta: '
                '${DateFormat('dd/MM/yyyy HH:mm').format(config.ultimaConsultaEm!)})',
      onPressed: () => _consultar(context, ref),
    );
  }
}
