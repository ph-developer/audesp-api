import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/app_settings_dao.dart';
import '../../core/database/database_providers.dart';
import '../processo/domain/ufesp_rules.dart';
import 'domain/pncp_varredura.dart';
import 'services/pncp_service.dart';

/// Configuração da consulta ao PNCP, mantida pelo admin.
class PncpConfig {
  static const intervaloPadrao = 30;

  final String cnpj;
  final bool automatica;
  final int intervaloMinutos;
  final DateTime? ultimaConsultaEm;

  const PncpConfig({
    this.cnpj = '',
    this.automatica = false,
    this.intervaloMinutos = intervaloPadrao,
    this.ultimaConsultaEm,
  });

  bool get configurado => cnpj.length == 14;
}

Future<PncpConfig> lerPncpConfig(AppSettingsDao dao) async {
  final (cnpj, automatica, intervalo, ultima) = await (
    dao.get(SettingsKeys.pncpCnpj),
    dao.get(SettingsKeys.pncpConsultaAutomatica),
    dao.get(SettingsKeys.pncpIntervaloMinutos),
    dao.get(SettingsKeys.pncpUltimaConsultaEm),
  ).wait;
  final ultimaEpoch = int.tryParse(ultima ?? '');
  return PncpConfig(
    cnpj: (cnpj ?? '').replaceAll(RegExp(r'\D'), ''),
    automatica: automatica == '1',
    intervaloMinutos:
        int.tryParse(intervalo ?? '') ?? PncpConfig.intervaloPadrao,
    ultimaConsultaEm: ultimaEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ultimaEpoch * 1000),
  );
}

final pncpConfigProvider = FutureProvider.autoDispose<PncpConfig>(
  (ref) => lerPncpConfig(ref.watch(appSettingsDaoProvider)),
);

final ufespConfigProvider = FutureProvider.autoDispose<UfespConfig>((
  ref,
) async {
  final dao = ref.watch(appSettingsDaoProvider);
  final (valor, quantidade) = await (
    dao.get(SettingsKeys.ufespValor),
    dao.get(SettingsKeys.ufespQuantidadeMinima),
  ).wait;
  return UfespConfig.fromSettings(valor: valor, quantidade: quantidade);
});

/// Compras do CNPJ configurado registradas pelas consultas.
final pncpComprasProvider = FutureProvider.autoDispose<List<PncpCompra>>((
  ref,
) async {
  final config = await ref.watch(pncpConfigProvider.future);
  if (!config.configurado) return const [];
  final compras = await ref.watch(pncpComprasDaoProvider).listAll();
  return compras.where((c) => c.cnpj == config.cnpj).toList();
});

/// Seção "No PNCP, sem edital no sistema" recolhida em Processos. Começa
/// recolhida; a escolha vale enquanto o sistema estiver aberto.
class PncpSecaoOcultaNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void alternar() => state = !state;
}

final pncpSecaoOcultaProvider = NotifierProvider<PncpSecaoOcultaNotifier, bool>(
  PncpSecaoOcultaNotifier.new,
);

class PncpConsultaState {
  final bool executando;
  final String? erro;

  const PncpConsultaState({this.executando = false, this.erro});
}

/// Executa a varredura do PNCP, manual ou automática.
class PncpConsultaNotifier extends Notifier<PncpConsultaState> {
  @override
  PncpConsultaState build() => const PncpConsultaState();

  /// Retorna quantas compras novas foram registradas, ou null quando a
  /// consulta automática foi pulada (desligada ou feita há pouco, inclusive
  /// por outra máquina).
  Future<int?> consultar({bool automatica = false}) async {
    if (state.executando) return null;
    final settings = ref.read(appSettingsDaoProvider);
    final config = await lerPncpConfig(settings);
    if (!config.configurado) {
      if (automatica) return null;
      throw const PncpException(
        'Configure o CNPJ do PNCP na Administração antes de consultar.',
      );
    }
    final agora = DateTime.now();
    if (automatica) {
      final ultima = config.ultimaConsultaEm;
      if (!config.automatica ||
          (ultima != null &&
              agora.difference(ultima).inMinutes < config.intervaloMinutos)) {
        return null;
      }
    }

    state = const PncpConsultaState(executando: true);
    try {
      // Marca antes de consultar para as outras máquinas pularem esta rodada.
      await settings.set(
        SettingsKeys.pncpUltimaConsultaEm,
        '${agora.millisecondsSinceEpoch ~/ 1000}',
      );
      final anoAtual = agora.year;
      final ultimaSequencia = <int, int>{};
      for (final ano in [anoAtual - 1, anoAtual]) {
        final valor = await settings.get(
          SettingsKeys.pncpSequencia(config.cnpj, ano),
        );
        final sequencia = int.tryParse(valor ?? '');
        if (sequencia != null) ultimaSequencia[ano] = sequencia;
      }

      final dao = ref.read(pncpComprasDaoProvider);
      final resultado = await PncpVarredura.executar(
        cnpj: config.cnpj,
        anoAtual: anoAtual,
        ultimaSequencia: ultimaSequencia,
        consultar: ref.read(pncpServiceProvider).consultarCompra,
        salvar: dao.upsert,
        registrarSequencia: (ano, sequencial) => settings.set(
          SettingsKeys.pncpSequencia(config.cnpj, ano),
          '$sequencial',
        ),
      );
      state = const PncpConsultaState();
      return resultado.novas;
    } catch (e) {
      state = PncpConsultaState(erro: e.toString());
      rethrow;
    } finally {
      ref.invalidate(pncpConfigProvider);
      ref.invalidate(pncpComprasProvider);
    }
  }
}

final pncpConsultaProvider =
    NotifierProvider<PncpConsultaNotifier, PncpConsultaState>(
      PncpConsultaNotifier.new,
    );

/// Confere a cada minuto se a consulta automática está devida. O intervalo
/// real fica no banco, compartilhado entre as máquinas.
final pncpMonitorProvider = Provider.autoDispose<void>((ref) {
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    unawaited(
      ref
          .read(pncpConsultaProvider.notifier)
          .consultar(automatica: true)
          .then<void>((_) {}, onError: (_) {}),
    );
  });
  ref.onDispose(timer.cancel);
});
