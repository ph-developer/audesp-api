import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/environments.dart';
import '../../core/database/database_providers.dart';
import '../../core/services/auth_service.dart';
import '../auth/auth_providers.dart';
import 'domain/atualizacao_protocolos.dart';
import 'domain/ultimo_envio.dart';
import 'services/consulta_service.dart';

/// Envios registrados para um endpoint ([EnviosEndpoint]). AutoDispose para
/// recarregar ao voltar do formulário, onde o documento pode ter sido enviado
/// ou ter o status do protocolo atualizado.
final enviosProvider = FutureProvider.autoDispose.family<EnviosIndex, String>(
  (ref, endpoint) => ref.watch(apiLogsDaoProvider).listEnvios(endpoint),
);

/// Intervalo entre as consultas automáticas dos protocolos em andamento.
const intervaloAtualizacaoProtocolos = Duration(minutes: 2);

/// Enquanto houver token AUDESP válido em memória (usuário e ambiente
/// ativos), consulta os protocolos em andamento desse ambiente e grava a
/// nova situação. Sem token não faz nada: o envio continua pedindo senha e
/// os logs mantêm a atualização manual.
final protocolosMonitorProvider = Provider.autoDispose<void>((ref) {
  var executando = false;

  Future<void> verificar() async {
    if (executando) return;
    final user = ref.read(localSessionProvider);
    final baseUrl = ref.read(environmentProvider).baseUrl;
    final auth = ref.read(authServiceProvider);
    bool tokenValido() =>
        user != null &&
        auth.tokenValido(userId: user.id, baseUrl: baseUrl) != null;
    if (!tokenValido()) return;

    executando = true;
    try {
      final dao = ref.read(apiLogsDaoProvider);
      final pendentes = await dao.listProtocolosEmAndamento(
        baseUrl,
        limite: AtualizacaoProtocolos.maxPorExecucao,
      );
      if (pendentes.isEmpty || !ref.mounted) return;
      final consulta = ref.read(consultaServiceProvider);
      final mudaram = await AtualizacaoProtocolos.executar(
        pendentes: pendentes,
        consultar: consulta.consultarStatus,
        salvar: dao.updateProtocoloInfo,
        podeContinuar: () => ref.mounted && tokenValido(),
      );
      if (mudaram > 0 && ref.mounted) ref.invalidate(enviosProvider);
    } catch (_) {
      // Silencioso: a próxima rodada tenta de novo.
    } finally {
      executando = false;
    }
  }

  final timer = Timer.periodic(
    intervaloAtualizacaoProtocolos,
    (_) => unawaited(verificar()),
  );
  ref.onDispose(timer.cancel);
});
