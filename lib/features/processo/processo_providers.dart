import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/environments.dart';
import '../../core/database/database_providers.dart';
import '../logs/domain/ultimo_envio.dart';
import '../logs/envios_providers.dart';
import 'domain/processo.dart';

/// Base compartilhada pelas pendências e pelas dependências dos formulários.
/// Invalidar após criar, alterar ou excluir qualquer documento local.
final documentosProcessoProvider =
    FutureProvider.autoDispose<DocumentosProcesso>((ref) async {
      final (editais, licitacoes, atas, ajustes) = await (
        ref.watch(editaisDaoProvider).watchAll(),
        ref.watch(licitacoesDaoProvider).watchAll(),
        ref.watch(atasDaoProvider).watchAll(),
        ref.watch(ajustesDaoProvider).watchAll(),
      ).wait;
      return DocumentosProcesso(
        editais: editais,
        licitacoes: licitacoes,
        atas: atas,
        ajustes: ajustes,
      );
    });

/// Também atende documentos sem processo. Invalidar [enviosProvider]
/// recalcula as conclusões no ambiente ativo.
final enviosProcessoProvider = FutureProvider.autoDispose<EnviosProcesso>((
  ref,
) async {
  final baseUrl = ref.watch(environmentProvider).baseUrl;
  final (editais, licitacoes, atas, ajustes) = await (
    ref.watch(enviosProvider(EnviosEndpoint.edital).future),
    ref.watch(enviosProvider(EnviosEndpoint.licitacao).future),
    ref.watch(enviosProvider(EnviosEndpoint.ata).future),
    ref.watch(enviosProvider(EnviosEndpoint.ajuste).future),
  ).wait;
  return EnviosProcesso(
    editais: editais,
    licitacoes: licitacoes,
    atas: atas,
    ajustes: ajustes,
    baseUrl: baseUrl,
  );
});

/// Vínculos e conclusões usados pelas regras de dependência dos formulários.
final processosProvider = FutureProvider.autoDispose<List<Processo>>((
  ref,
) async {
  final (documentos, envios, estimativas) = await (
    ref.watch(documentosProcessoProvider.future),
    ref.watch(enviosProcessoProvider.future),
    ref.watch(estimativasDaoProvider).listResumo(),
  ).wait;
  return Processo.agrupar(
    editais: documentos.editais,
    licitacoes: documentos.licitacoes,
    atas: documentos.atas,
    ajustes: documentos.ajustes,
    estimativas: estimativas,
    envios: envios,
  );
});
