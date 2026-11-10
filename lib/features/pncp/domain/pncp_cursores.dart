import '../../../core/database/daos/app_settings_dao.dart';

/// Pontos de partida das varreduras do PNCP ajustados pelo admin.
abstract class PncpCursores {
  /// A varredura de atas nunca passa do cursor das compras.
  static String? validar({int? compra, int? ata}) {
    if (ata == null) return null;
    if (compra == null || ata > compra) {
      return 'A compra verificada para atas não pode passar da última '
          'sequência de compra consultada.';
    }
    return null;
  }

  /// Chaves a gravar em `app_settings` (valor nulo = apagar). Só o que mudou
  /// é gravado, para não desfazer o avanço de uma consulta feita enquanto a
  /// tela estava aberta.
  ///
  /// Ao mudar o cursor das atas, a consulta por data de atualização passa a
  /// partir de [hoje]; senão ela recomeçaria em 1º de janeiro e traria de
  /// volta as atas das compras puladas. Em branco, as duas recomeçam do zero.
  static Map<String, String?> alteracoes({
    required String cnpj,
    required int ano,
    required DateTime hoje,
    int? compra,
    bool compraAlterada = false,
    int? contrato,
    bool contratoAlterado = false,
    int? ata,
    bool ataAlterada = false,
  }) => {
    if (compraAlterada)
      SettingsKeys.pncpSequencia(cnpj, ano): compra?.toString(),
    if (contratoAlterado)
      SettingsKeys.pncpContratoSequencia(cnpj, ano): contrato?.toString(),
    if (ataAlterada) ...{
      SettingsKeys.pncpAtaCompraSequencia(cnpj, ano): ata?.toString(),
      SettingsKeys.pncpAtaCompraPagina(cnpj, ano): null,
      SettingsKeys.pncpAtasAtualizadasAte: ata == null
          ? null
          : '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-'
                '${hoje.day.toString().padLeft(2, '0')}',
      SettingsKeys.pncpAtasAtualizadasCnpj: ata == null ? null : cnpj,
    },
  };
}
