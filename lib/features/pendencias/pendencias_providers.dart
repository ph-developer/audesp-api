import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/user.dart';
import '../../core/database/models/pncp_compra.dart';
import '../../core/database/models/pncp_contrato.dart';
import '../auth/auth_providers.dart';
import '../pncp/pncp_providers.dart';
import '../processo/processo_providers.dart';
import 'domain/pendencias_modulos.dart';

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
    final (documentos, envios, compras, contratos, config) = await (
      ref.watch(documentosProcessoProvider.future),
      ref.watch(enviosProcessoProvider.future),
      user.hasPermission(AppPermissions.edital)
          ? ref.watch(pncpComprasProvider.future)
          : Future.value(const <PncpCompra>[]),
      podeAjuste
          ? ref.watch(pncpContratosProvider.future)
          : Future.value(const <PncpContrato>[]),
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
      cnpj: config.cnpj,
    );
  },
);

/// Contagens sem busca, filtros, dispensas ou contratos bloqueados.
final pendenciasContagemProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) async => (await ref.watch(pendenciasModulosProvider.future)).contagens,
);
