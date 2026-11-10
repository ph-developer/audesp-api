import '../../../core/database/app_database.dart';
import '../../processo/domain/processo.dart';
import '../../processo/domain/processo_rules.dart';
import 'pncp_vigencia.dart';

class PendenciaContratoPncp {
  final PncpContrato contrato;
  final Edital? edital;
  final bool adesaoParticipacao;
  final String? motivoBloqueio;

  const PendenciaContratoPncp({
    required this.contrato,
    this.edital,
    this.adesaoParticipacao = false,
    this.motivoBloqueio,
  });

  bool get liberado => motivoBloqueio == null;
}

/// Contratos que ainda não foram lançados como Ajuste, inclusive dispensados.
abstract final class PncpContratosPendencias {
  static List<PendenciaContratoPncp> classificar({
    required Iterable<PncpContrato> contratos,
    required Iterable<Processo> processos,
    required Iterable<Ajuste> ajustes,
    required String cnpj,
    Iterable<PncpCompra> compras = const [],
  }) {
    final usados = ajustes.map((a) => _digitos(a.codigoContrato)).toSet();
    final publicacoes = PncpVigencia.publicacoes(compras);
    final porCompra = <String, List<Processo>>{};
    for (final processo in processos) {
      for (final codigo in {
        _digitos(processo.edital.codigoEdital),
        _digitos(processo.edital.idContratacaoPNCP),
      }) {
        if (codigo.isNotEmpty) (porCompra[codigo] ??= []).add(processo);
      }
    }
    final cnpjConfigurado = _digitos(cnpj);
    final pendencias = <PendenciaContratoPncp>[];
    for (final contrato in contratos) {
      if (usados.contains(_digitos(contrato.numeroControle))) continue;
      if (!PncpVigencia.derivado(
        numeroControleCompra: contrato.numeroControleCompra,
        publicacoes: publicacoes,
        assinatura: contrato.dataAssinatura,
      )) {
        continue;
      }
      final compra = _digitos(contrato.numeroControleCompra ?? '');
      final vinculados = porCompra[compra] ?? const <Processo>[];
      // Mesmo nas dispensas e adesões, a prefeitura não lança Ajuste de Ata.
      // Ocultos também nunca voltam a aparecer nas pendências.
      if ((contrato.numeroControleAta?.isNotEmpty ?? false) ||
          vinculados.any((p) => p.edital.isSrp || p.edital.oculto)) {
        continue;
      }
      final processo = vinculados.firstOrNull;
      final adesao =
          contrato.frutoAdesao ||
          (compra.length >= 14 && compra.substring(0, 14) != cnpjConfigurado);
      final motivo = compra.isEmpty
          ? 'O contrato não informa a compra no PNCP.'
          : adesao
          ? null
          : processo == null
          ? 'O edital desta compra ainda não está no sistema.'
          : ProcessoRules.motivoBloqueioAjuste(processo);
      pendencias.add(
        PendenciaContratoPncp(
          contrato: contrato,
          edital: processo?.edital,
          adesaoParticipacao: adesao,
          motivoBloqueio: motivo,
        ),
      );
    }
    return pendencias;
  }

  static String _digitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');
}
