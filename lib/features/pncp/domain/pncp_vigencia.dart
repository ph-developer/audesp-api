import '../../../core/database/app_database.dart';

/// O sistema vale para editais publicados a partir de 02/02/2026 e para as
/// atas e contratos que vêm deles. O que é anterior foi enviado pelo sistema
/// antigo e nunca gera pendência, nem entre as dispensadas.
abstract final class PncpVigencia {
  static final inicio = DateTime(2026, 2, 2);

  /// Compra sem data de publicação fica dentro, para não sumir por falta de
  /// informação do PNCP.
  static bool compra(PncpCompra compra) =>
      compra.dataPublicacao == null || !compra.dataPublicacao!.isBefore(inicio);

  /// Publicação das compras conhecidas, pelo número de controle (só dígitos).
  static Map<String, DateTime> publicacoes(Iterable<PncpCompra> compras) => {
    for (final c in compras)
      if (c.dataPublicacao != null)
        _digitos(c.numeroControle): c.dataPublicacao!,
  };

  /// Ata ou contrato derivado de [numeroControleCompra]. Usa a publicação da
  /// compra quando ela está em `pncp_compras`; senão, o ano do número de
  /// controle e a assinatura do próprio documento (não há ata ou contrato
  /// assinado antes do edital).
  static bool derivado({
    required String? numeroControleCompra,
    required Map<String, DateTime> publicacoes,
    DateTime? assinatura,
  }) {
    final compra = _digitos(numeroControleCompra ?? '');
    final publicacao = publicacoes[compra];
    if (publicacao != null) return !publicacao.isBefore(inicio);
    // 14 (CNPJ) + 1 (esfera) + 6 (sequencial) + 4 (ano).
    if (compra.length == 25 && int.parse(compra.substring(21)) < inicio.year) {
      return false;
    }
    return assinatura == null || !assinatura.isBefore(inicio);
  }

  static String _digitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');
}
