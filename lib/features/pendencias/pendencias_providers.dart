import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/user.dart';
import '../../core/database/models/pncp_compra.dart';
import '../../core/database/models/pncp_contrato.dart';
import '../../core/database/models/pncp_ata.dart';
import '../../core/database/database_providers.dart';
import '../auth/auth_providers.dart';
import '../pncp/pncp_providers.dart';
import '../processo/processo_providers.dart';
import 'domain/pendencias_modulos.dart';
import 'domain/prazo_envio.dart';

final pendenciasModulosProvider = FutureProvider.autoDispose<PendenciasModulos>(
  (ref) async {
    final user = ref.watch(localSessionProvider);
    if (user == null ||
        !user.hasAnyPermission(
          AppPermissions.edital |
              AppPermissions.licitacao |
              AppPermissions.ata |
              AppPermissions.ajuste,
        )) {
      return const PendenciasModulos();
    }
    final podeAjuste = user.hasPermission(AppPermissions.ajuste);
    final podeAta = user.hasPermission(AppPermissions.ata);
    final (documentos, envios, compras, contratos, atas, config) = await (
      ref.watch(documentosProcessoProvider.future),
      ref.watch(enviosProcessoProvider.future),
      // As compras também dão a data de publicação de atas e contratos.
      user.hasAnyPermission(
            AppPermissions.edital | AppPermissions.ata | AppPermissions.ajuste,
          )
          ? ref.watch(pncpComprasProvider.future)
          : Future.value(const <PncpCompra>[]),
      podeAjuste
          ? ref.watch(pncpContratosProvider.future)
          : Future.value(const <PncpContrato>[]),
      podeAta
          ? ref.watch(pncpAtasProvider.future)
          : Future.value(const <PncpAta>[]),
      podeAjuste
          ? ref.watch(pncpConfigProvider.future)
          : Future.value(const PncpConfig()),
    ).wait;
    return PendenciasRules.paraUsuario(
      user: user,
      documentos: documentos,
      envios: envios,
      compras: compras,
      contratos: contratos,
      atasPncp: atas,
      cnpj: config.cnpj,
    );
  },
);

/// Contagens sem busca, filtros, dispensas ou atas/contratos bloqueados.
final pendenciasContagemProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) async => (await ref.watch(pendenciasModulosProvider.future)).contagens,
);

final prazoEnvioConfigProvider = FutureProvider.autoDispose<PrazoEnvioConfig>((
  ref,
) async {
  final dao = ref.watch(appSettingsDaoProvider);
  final chaves = PrazoEnvioConfig.chaves;
  final valores = await Future.wait(chaves.map(dao.get));
  return PrazoEnvioConfig.fromSettings({
    for (final (i, chave) in chaves.indexed) chave: valores[i],
  });
});

/// Prazos de envio ao AUDESP dos itens das pendências; só informativos, não
/// alteram pendências nem badges.
final prazosEnvioProvider = FutureProvider.autoDispose<PrazosEnvio>((
  ref,
) async {
  final user = ref.watch(localSessionProvider);
  final config = await ref.watch(prazoEnvioConfigProvider.future);
  if (user == null) return PrazosEnvio(config: config);
  final podeAjuste = user.hasPermission(AppPermissions.ajuste);
  final podeAta = user.hasPermission(AppPermissions.ata);
  final (compras, contratos, atas) = await (
    user.hasAnyPermission(
          AppPermissions.edital | AppPermissions.ata | AppPermissions.ajuste,
        )
        ? ref.watch(pncpComprasProvider.future)
        : Future.value(const <PncpCompra>[]),
    podeAjuste
        ? ref.watch(pncpContratosProvider.future)
        : Future.value(const <PncpContrato>[]),
    podeAta
        ? ref.watch(pncpAtasProvider.future)
        : Future.value(const <PncpAta>[]),
  ).wait;
  return PrazosEnvio(
    config: config,
    compras: compras,
    atas: atas,
    contratos: contratos,
  );
});
