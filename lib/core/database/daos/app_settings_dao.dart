import '../database_service.dart';

abstract class SettingsKeys {
  static const geminiApiKey = 'gemini_api_key';
  static const geminiModel = 'gemini_model';
  static const codigoMunicipio = 'codigo_municipio';
  static const codigoEntidade = 'codigo_entidade';
  static const codigoTipoOrgao = 'codigo_tipo_orgao';
  static const environment = 'environment';
  static const pncpCnpj = 'pncp_cnpj';
  static const pncpConsultaAutomatica = 'pncp_consulta_automatica';
  static const pncpIntervaloMinutos = 'pncp_intervalo_minutos';
  static const pncpUltimaConsultaEm = 'pncp_ultima_consulta_em';
  static const ufespValor = 'ufesp_valor';
  static const ufespQuantidadeMinima = 'ufesp_quantidade_minima';

  /// Monitor da documentação do AUDESP: último período verificado
  /// (`periodoVerificacao`), snapshot conferido pelo TI, último snapshot
  /// lido e quando a diferença entre os dois apareceu.
  static const documentacaoPeriodo = 'documentacao_periodo_verificado';
  static const documentacaoReferencia = 'documentacao_referencia';
  static const documentacaoAtual = 'documentacao_atual';
  static const documentacaoAlteradaEm = 'documentacao_alterada_em';

  /// Última sequência encontrada no PNCP para o CNPJ e o ano.
  static String pncpSequencia(String cnpj, int ano) =>
      'pncp_sequencia_${cnpj}_$ano';

  /// Cursor dos contratos, independente da numeração das compras.
  static String pncpContratoSequencia(String cnpj, int ano) =>
      'pncp_contrato_sequencia_${cnpj}_$ano';
}

class AppSettingsDao {
  final DatabaseService _db;
  AppSettingsDao(this._db);

  Future<String?> get(String key) async {
    final result = await _db.executePrepared(
      'SELECT value FROM app_settings WHERE `key` = (?)',
      [key],
    );
    final rows = result.rows;
    return rows.isEmpty ? null : rows.first.typedAssoc()['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    await _db.executePrepared(
      'INSERT INTO app_settings (`key`, `value`) VALUES (?, ?) '
      'ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)',
      [key, value],
    );
  }

  Future<void> delete(String key) async {
    await _db.executePrepared('DELETE FROM app_settings WHERE `key` = (?)', [
      key,
    ]);
  }
}
