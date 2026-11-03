import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/app_settings_dao.dart';
import '../../core/database/database_providers.dart';
import 'domain/documentacao_monitor.dart';
import 'services/documentacao_service.dart';

/// Diferença entre a documentação conferida pelo TI e a última lida.
class DocumentacaoAlerta {
  final List<String> alteracoes;
  final DateTime? detectadaEm;

  const DocumentacaoAlerta({required this.alteracoes, this.detectadaEm});
}

Future<DocumentacaoAlerta?> lerAlertaDocumentacao(AppSettingsDao dao) async {
  final (referencia, atual, alteradaEm) = await (
    dao.get(SettingsKeys.documentacaoReferencia),
    dao.get(SettingsKeys.documentacaoAtual),
    dao.get(SettingsKeys.documentacaoAlteradaEm),
  ).wait;
  final snapshotReferencia = lerSnapshot(referencia);
  final snapshotAtual = lerSnapshot(atual);
  if (snapshotReferencia == null || snapshotAtual == null) return null;
  final alteracoes = compararDocumentacao(snapshotReferencia, snapshotAtual);
  if (alteracoes.isEmpty) return null;
  final epoch = int.tryParse(alteradaEm ?? '');
  return DocumentacaoAlerta(
    alteracoes: alteracoes,
    detectadaEm: epoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(epoch * 1000),
  );
}

final documentacaoAlertaProvider =
    FutureProvider.autoDispose<DocumentacaoAlerta?>(
      (ref) => lerAlertaDocumentacao(ref.watch(appSettingsDaoProvider)),
    );

enum VerificacaoDocumentacao {
  jaVerificada,
  referenciaCriada,
  semAlteracao,
  alterada,
}

/// Verifica a documentação uma vez por período ([periodoVerificacao]),
/// compartilhado entre as máquinas pelo `app_settings`.
///
/// A primeira leitura vira a referência sem alertar. Depois, a referência só
/// muda quando o admin marca a alteração como verificada.
Future<VerificacaoDocumentacao> verificarDocumentacao({
  required DateTime agora,
  required Future<String?> Function(String chave) ler,
  required Future<void> Function(String chave, String valor) gravar,
  required Future<void> Function(String chave) apagar,
  required Future<DocumentacaoSnapshot> Function() lerDocumentacao,
}) async {
  final periodo = periodoVerificacao(agora);
  final periodoAnterior = await ler(SettingsKeys.documentacaoPeriodo);
  if (periodoAnterior == periodo) return VerificacaoDocumentacao.jaVerificada;

  // Marca antes de consultar para as outras máquinas pularem este período.
  await gravar(SettingsKeys.documentacaoPeriodo, periodo);
  final DocumentacaoSnapshot atual;
  try {
    atual = await lerDocumentacao();
  } catch (_) {
    // Devolve o período para a próxima tentativa (desta ou de outra máquina).
    if (periodoAnterior == null) {
      await apagar(SettingsKeys.documentacaoPeriodo);
    } else {
      await gravar(SettingsKeys.documentacaoPeriodo, periodoAnterior);
    }
    rethrow;
  }

  final json = atual.toJson();
  await gravar(SettingsKeys.documentacaoAtual, json);
  final referencia = lerSnapshot(
    await ler(SettingsKeys.documentacaoReferencia),
  );
  if (referencia == null) {
    await gravar(SettingsKeys.documentacaoReferencia, json);
    return VerificacaoDocumentacao.referenciaCriada;
  }
  if (compararDocumentacao(referencia, atual).isEmpty) {
    await apagar(SettingsKeys.documentacaoAlteradaEm);
    return VerificacaoDocumentacao.semAlteracao;
  }
  if (await ler(SettingsKeys.documentacaoAlteradaEm) == null) {
    await gravar(
      SettingsKeys.documentacaoAlteradaEm,
      '${agora.millisecondsSinceEpoch ~/ 1000}',
    );
  }
  return VerificacaoDocumentacao.alterada;
}

/// O admin conferiu a alteração: a última leitura vira a referência.
Future<void> marcarDocumentacaoVerificada(AppSettingsDao dao) async {
  final atual = await dao.get(SettingsKeys.documentacaoAtual);
  if (atual != null) await dao.set(SettingsKeys.documentacaoReferencia, atual);
  await dao.delete(SettingsKeys.documentacaoAlteradaEm);
}

/// Após uma falha (sem rede, site fora do ar), espera antes de tentar de novo.
const _esperaAposFalha = Duration(minutes: 15);

/// Verifica a documentação ao abrir o sistema e confere a cada minuto se o
/// período mudou. Falhas são silenciosas.
final documentacaoMonitorProvider = Provider.autoDispose<void>((ref) {
  var ativo = true;
  var executando = false;
  DateTime? proximaTentativa;
  String? periodoVisto;

  Future<void> verificar() async {
    final agora = DateTime.now();
    if (!ativo ||
        executando ||
        (proximaTentativa != null && agora.isBefore(proximaTentativa!))) {
      return;
    }
    executando = true;
    try {
      final settings = ref.read(appSettingsDaoProvider);
      final resultado = await verificarDocumentacao(
        agora: agora,
        ler: settings.get,
        gravar: settings.set,
        apagar: settings.delete,
        lerDocumentacao: ref.read(documentacaoServiceProvider).lerDocumentacao,
      );
      final periodo = periodoVerificacao(agora);
      // Outra máquina pode ter verificado: recarrega o alerta a cada período.
      if (ativo &&
          (resultado != VerificacaoDocumentacao.jaVerificada ||
              periodoVisto != periodo)) {
        ref.invalidate(documentacaoAlertaProvider);
      }
      periodoVisto = periodo;
      proximaTentativa = null;
    } catch (_) {
      proximaTentativa = agora.add(_esperaAposFalha);
    } finally {
      executando = false;
    }
  }

  unawaited(verificar());
  final timer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => unawaited(verificar()),
  );
  ref.onDispose(() {
    ativo = false;
    timer.cancel();
  });
});
