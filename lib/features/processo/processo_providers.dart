import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/environments.dart';
import '../../core/database/database_providers.dart';
import '../logs/domain/ultimo_envio.dart';
import '../logs/envios_providers.dart';
import 'domain/processo.dart';

/// Os envios entram para saber quais fases estão concluídas (protocolo
/// armazenado no ambiente ativo); invalidar [enviosProvider] recalcula.
final processosProvider = FutureProvider.autoDispose<List<Processo>>((
  ref,
) async {
  final baseUrl = ref.watch(environmentProvider).baseUrl;
  final (
    editais,
    licitacoes,
    atas,
    ajustes,
    estimativas,
    enviosEdital,
    enviosLicitacao,
    enviosAta,
    enviosAjuste,
  ) = await (
    ref.watch(editaisDaoProvider).watchAll(),
    ref.watch(licitacoesDaoProvider).watchAll(),
    ref.watch(atasDaoProvider).watchAll(),
    ref.watch(ajustesDaoProvider).watchAll(),
    ref.watch(estimativasDaoProvider).listResumo(),
    ref.watch(enviosProvider(EnviosEndpoint.edital).future),
    ref.watch(enviosProvider(EnviosEndpoint.licitacao).future),
    ref.watch(enviosProvider(EnviosEndpoint.ata).future),
    ref.watch(enviosProvider(EnviosEndpoint.ajuste).future),
  ).wait;

  return Processo.agrupar(
    editais: editais,
    licitacoes: licitacoes,
    atas: atas,
    ajustes: ajustes,
    estimativas: estimativas,
    envios: EnviosProcesso(
      editais: enviosEdital,
      licitacoes: enviosLicitacao,
      atas: enviosAta,
      ajustes: enviosAjuste,
      baseUrl: baseUrl,
    ),
  );
});
