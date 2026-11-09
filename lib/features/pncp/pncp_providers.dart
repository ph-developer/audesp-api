import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/app_settings_dao.dart';
import '../../core/database/database_providers.dart';
import '../processo/domain/ufesp_rules.dart';
import 'domain/pncp_varredura.dart';
import 'domain/pncp_atas_varredura.dart';
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

/// Contratos do CNPJ configurado, sem misturar configurações anteriores.
final pncpContratosProvider = FutureProvider.autoDispose<List<PncpContrato>>((
  ref,
) async {
  final config = await ref.watch(pncpConfigProvider.future);
  if (!ref.mounted || !config.configurado) return const [];
  final contratos = await ref.watch(pncpContratosDaoProvider).listAll();
  return contratos.where((c) => c.cnpj == config.cnpj).toList();
});

final pncpAtasProvider = FutureProvider.autoDispose<List<PncpAta>>((ref) async {
  final config = await ref.watch(pncpConfigProvider.future);
  if (!ref.mounted || !config.configurado) return const [];
  final atas = await ref.watch(pncpAtasDaoProvider).listAll();
  return atas.where((a) => a.cnpj == config.cnpj).toList();
});

typedef PncpConsultaResultado = ({int compras, int contratos, int atas});

class PncpConsultaState {
  final bool executando;
  final String? erro;

  const PncpConsultaState({this.executando = false, this.erro});
}

/// Executa a varredura do PNCP, manual ou automática.
class PncpConsultaNotifier extends Notifier<PncpConsultaState> {
  @override
  PncpConsultaState build() => const PncpConsultaState();

  /// Retorna quantas compras, contratos e atas novos foram registrados, ou null quando a
  /// consulta automática foi pulada (desligada ou feita há pouco, inclusive
  /// por outra máquina).
  Future<PncpConsultaResultado?> consultar({bool automatica = false}) async {
    if (state.executando) return null;
    final settings = ref.read(appSettingsDaoProvider);
    final config = await lerPncpConfig(settings);
    if (state.executando) return null;
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
      Future<Map<int, int>> lerSequencias(
        String Function(String, int) chave,
      ) async {
        final sequencias = <int, int>{};
        for (final ano in [anoAtual - 1, anoAtual]) {
          final valor = await settings.get(chave(config.cnpj, ano));
          final sequencia = int.tryParse(valor ?? '');
          if (sequencia != null) sequencias[ano] = sequencia;
        }
        return sequencias;
      }

      final dao = ref.read(pncpComprasDaoProvider);
      final resultado = await PncpVarredura.executar(
        cnpj: config.cnpj,
        anoAtual: anoAtual,
        ultimaSequencia: await lerSequencias(SettingsKeys.pncpSequencia),
        consultar: ref.read(pncpServiceProvider).consultarCompra,
        salvar: dao.upsert,
        registrarSequencia: (ano, sequencial) => settings.set(
          SettingsKeys.pncpSequencia(config.cnpj, ano),
          '$sequencial',
        ),
      );
      // Cada upsert e cursor já foi persistido. Falha nos contratos não
      // desfaz as compras nem o progresso desta varredura.
      final contratos = await PncpVarredura.executarContratos(
        cnpj: config.cnpj,
        anoAtual: anoAtual,
        ultimaSequencia: await lerSequencias(
          SettingsKeys.pncpContratoSequencia,
        ),
        consultar: ref.read(pncpServiceProvider).consultarContrato,
        salvar: ref.read(pncpContratosDaoProvider).upsert,
        registrarSequencia: (ano, sequencial) => settings.set(
          SettingsKeys.pncpContratoSequencia(config.cnpj, ano),
          '$sequencial',
        ),
      );
      // O limite das atas é o cursor das compras já persistido nesta rodada.
      // Uma falha daqui em diante preserva compras, contratos e seus cursores.
      final atasDao = ref.read(pncpAtasDaoProvider);
      final service = ref.read(pncpServiceProvider);
      final paginas = <int, ProgressoPaginaAta>{};
      for (final ano in [anoAtual - 1, anoAtual]) {
        final valor = await settings.get(
          SettingsKeys.pncpAtaCompraPagina(config.cnpj, ano),
        );
        final partes = valor?.split(':') ?? const <String>[];
        if (partes.length == 2) {
          final sequencia = int.tryParse(partes[0]);
          final pagina = int.tryParse(partes[1]);
          if (sequencia != null && pagina != null && pagina > 0) {
            paginas[ano] = (sequencialCompra: sequencia, pagina: pagina);
          }
        }
      }
      final atas = await PncpAtasVarredura.executar(
        cnpj: config.cnpj,
        anoAtual: anoAtual,
        ultimaSequenciaCompra: await lerSequencias(SettingsKeys.pncpSequencia),
        ultimaCompraConsultada: await lerSequencias(
          SettingsKeys.pncpAtaCompraSequencia,
        ),
        paginas: paginas,
        consultar: service.consultarAtasCompra,
        salvar: atasDao.upsert,
        registrarSequencia: (ano, sequencia) => settings.set(
          SettingsKeys.pncpAtaCompraSequencia(config.cnpj, ano),
          '$sequencia',
        ),
        registrarPagina: (ano, progresso) => settings.set(
          SettingsKeys.pncpAtaCompraPagina(config.cnpj, ano),
          '${progresso.sequencialCompra}:${progresso.pagina}',
        ),
      );
      final donoMarcador = await settings.get(
        SettingsKeys.pncpAtasAtualizadasCnpj,
      );
      final marcador = await settings.get(SettingsKeys.pncpAtasAtualizadasAte);
      final atualizadas = await PncpAtasVarredura.atualizar(
        cnpj: config.cnpj,
        hoje: agora,
        atualizadasAte: donoMarcador == null || donoMarcador == config.cnpj
            ? DateTime.tryParse(marcador ?? '')
            : null,
        consultar: service.consultarAtasAtualizadas,
        salvar: atasDao.upsert,
        registrarData: (data) async {
          await settings.set(
            SettingsKeys.pncpAtasAtualizadasAte,
            '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
          );
          await settings.set(SettingsKeys.pncpAtasAtualizadasCnpj, config.cnpj);
        },
      );
      state = const PncpConsultaState();
      return (
        compras: resultado.novas,
        contratos: contratos.novas,
        atas: atas.novas + atualizadas,
      );
    } catch (e) {
      state = PncpConsultaState(erro: e.toString());
      rethrow;
    } finally {
      ref.invalidate(pncpConfigProvider);
      ref.invalidate(pncpComprasProvider);
      ref.invalidate(pncpContratosProvider);
      ref.invalidate(pncpAtasProvider);
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
