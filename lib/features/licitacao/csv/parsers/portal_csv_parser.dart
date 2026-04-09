import '../models/licitacao_item_csv_model.dart';

/// Chaves utilizadas no mapa de arquivos CSV passado a cada parser.
abstract class CsvFileKeys {
  /// BLL: arquivo `Classificacao com itens.csv`.
  static const bllClassificacao = 'bll_classificacao';

  /// BRConectado: arquivo `relatclassificacao.csv`.
  static const brRelatClassificacao = 'br_relat_classificacao';

  /// BRConectado: arquivo `propostas.csv`.
  static const brPropostas = 'br_propostas';
}

/// Interface que todo parser de portal de compras deve implementar.
///
/// Cada implementação recebe um mapa de bytes crus (`List<int>`) indexado
/// pelas chaves definidas em [CsvFileKeys] e retorna a lista de itens
/// já convertidos para o domínio interno.
abstract class PortalCsvParser {
  /// Converte os bytes dos CSVs fornecidos em [csvFiles] para uma lista
  /// de [LicitacaoItemCsvModel].
  ///
  /// Lança [CsvParseException] em caso de erro de formato ou coluna ausente.
  List<LicitacaoItemCsvModel> parse(Map<String, List<int>> csvFiles);
}

/// Exceção amigável para erros de parse de CSV.
class CsvParseException implements Exception {
  final String message;
  const CsvParseException(this.message);

  @override
  String toString() => 'CsvParseException: $message';
}
