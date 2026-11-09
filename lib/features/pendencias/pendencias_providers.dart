import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/user.dart';
import '../../core/database/models/pncp_compra.dart';
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
    final (documentos, envios, compras) = await (
      ref.watch(documentosProcessoProvider.future),
      ref.watch(enviosProcessoProvider.future),
      user.hasPermission(AppPermissions.edital)
          ? ref.watch(pncpComprasProvider.future)
          : Future.value(const <PncpCompra>[]),
    ).wait;
    return PendenciasRules.paraUsuario(
      user: user,
      documentos: documentos,
      envios: envios,
      compras: compras,
    );
  },
);

/// Contagens sem busca, filtros de listagem ou compras dispensadas.
final pendenciasContagemProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) async => (await ref.watch(pendenciasModulosProvider.future)).contagens,
);
