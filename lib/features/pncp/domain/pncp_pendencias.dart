import '../../../core/database/app_database.dart';

/// Compras do PNCP comparadas aos editais cadastrados.
abstract final class PncpPendencias {
  /// Compras não dispensadas que nenhum edital (rascunho ou enviado) usa.
  static List<PncpCompra> semEdital(
    Iterable<PncpCompra> compras,
    Iterable<Edital> editais,
  ) {
    final usados = _codigosPncp(editais);
    return [
      for (final compra in compras)
        if (!compra.dispensada && !usados.contains(compra.numeroControle))
          compra,
    ];
  }

  /// Dispensadas que continuam sem edital, para poder restaurar.
  static List<PncpCompra> dispensadas(
    Iterable<PncpCompra> compras,
    Iterable<Edital> editais,
  ) {
    final usados = _codigosPncp(editais);
    return [
      for (final compra in compras)
        if (compra.dispensada && !usados.contains(compra.numeroControle))
          compra,
    ];
  }

  // O código do edital e a publicação no PNCP podem trazer o id com máscara.
  static Set<String> _codigosPncp(Iterable<Edital> editais) => {
    for (final edital in editais)
      for (final codigo in [edital.codigoEdital, edital.idContratacaoPNCP])
        codigo.replaceAll(RegExp(r'\D'), ''),
  };
}
