import '../../../core/database/app_database.dart';
import '../../processo/domain/processo.dart';
import '../../processo/domain/processo_rules.dart';
import 'pncp_vigencia.dart';

class PendenciaAtaPncp {
  final PncpAta ata;
  final Edital? edital;
  final String? motivoBloqueio;

  const PendenciaAtaPncp({required this.ata, this.edital, this.motivoBloqueio});

  bool get liberada => motivoBloqueio == null && !ata.cancelada;
}

abstract final class PncpAtasPendencias {
  /// Inclui dispensadas para permitir restauração, inclusive após cancelamento.
  /// O SRP da compra no PNCP não é confiável; vale sempre o edital local.
  static List<PendenciaAtaPncp> classificar({
    required Iterable<PncpAta> atasPncp,
    required Iterable<Processo> processos,
    required Iterable<Ata> atas,
    Iterable<PncpCompra> compras = const [],
  }) {
    final usadas = atas.map((a) => _digitos(a.codigoAta)).toSet();
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
    final pendencias = <PendenciaAtaPncp>[];
    for (final ata in atasPncp) {
      if (usadas.contains(_digitos(ata.numeroControle))) continue;
      if (!PncpVigencia.derivado(
        numeroControleCompra: ata.numeroControleCompra,
        publicacoes: publicacoes,
        assinatura: ata.dataAssinatura,
      )) {
        continue;
      }
      final vinculados =
          porCompra[_digitos(ata.numeroControleCompra)] ?? const <Processo>[];
      if (vinculados.any((p) => p.edital.oculto)) continue;
      if (ata.cancelada && !ata.dispensada) continue;
      final processo = vinculados.firstOrNull;
      final motivo = ata.cancelada
          ? 'A ata foi cancelada no PNCP.'
          : processo == null
          ? 'O edital desta compra ainda não está no sistema.'
          : ProcessoRules.motivoBloqueioAta(processo);
      pendencias.add(
        PendenciaAtaPncp(
          ata: ata,
          edital: processo?.edital,
          motivoBloqueio: motivo,
        ),
      );
    }
    return pendencias;
  }

  static String _digitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');
}
