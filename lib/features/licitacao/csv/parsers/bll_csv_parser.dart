import '../mappers/bll_mapper.dart';
import '../mappers/csv_mappers.dart';
import '../models/licitacao_item_csv_model.dart';
import '../../../../core/utils/csv_utils.dart';
import 'portal_csv_parser.dart';

/// Parser para os arquivos CSV exportados pelo portal **BLL**.
///
/// Arquivos necessários (informar via [CsvFileKeys]):
/// - [CsvFileKeys.bllClassificacao] → `Classificacao com itens.csv`
///
/// ### Colunas esperadas
///
/// **Classificacao com itens.csv**
/// ```
/// "Lote","Item","Posição","Razão Social","Documento","Lance","Marca","Modelo","ME","Classificado","Habilitado"
/// ```
class BllCsvParser implements PortalCsvParser {
  const BllCsvParser();

  @override
  List<LicitacaoItemCsvModel> parse(Map<String, List<int>> csvFiles) {
    final classificacaoBytes = csvFiles[CsvFileKeys.bllClassificacao];

    if (classificacaoBytes == null) {
      throw const CsvParseException(
        'Arquivo "Classificacao com itens.csv" não fornecido '
        '(chave: "${CsvFileKeys.bllClassificacao}").',
      );
    }

    return _parseClassificacao(classificacaoBytes);
  }

  // ---------------------------------------------------------------------------
  // Parseia Classificacao com itens.csv, agrupa por item e monta o modelo final.
  // ---------------------------------------------------------------------------

  List<LicitacaoItemCsvModel> _parseClassificacao(List<int> bytes) {
    final rows = CsvUtils.parseCsv(
      CsvUtils.decodeBytes(bytes),
      delimiter: ',',
    );
    if (rows.isEmpty) {
      throw const CsvParseException(
        '"Classificacao com itens.csv" está vazio.',
      );
    }

    final header = CsvUtils.buildHeaderIndex(rows.first);
    // Mapa: numeroItem → lista de licitantes
    final itensMapa = <int, List<LicitanteCsvModel>>{};

    for (final row in rows.skip(1)) {
      if (row.length <= 1) continue;
      try {
        final itemStr = CsvUtils.getField(row, header, 'item');
        final posicaoStr = CsvUtils.getField(row, header, 'posição');
        final razaoSocial = CsvUtils.getField(row, header, 'razão social');
        final documento = CsvUtils.getField(row, header, 'documento');
        final lanceStr = CsvUtils.getField(row, header, 'lance');
        final meStr = CsvUtils.getField(row, header, 'me');
        final classificadoStr = CsvUtils.getField(row, header, 'classificado');

        final itemNum = int.parse(itemStr);
        final posicao = int.parse(posicaoStr);
        final niLimpo = CsvMappers.cleanNiPessoa(documento);

        final licitante = LicitanteCsvModel(
          niPessoa: niLimpo,
          tipoPessoaId: CsvMappers.tipoPessoaFromCleanNi(niLimpo),
          nomeRazaoSocial: razaoSocial,
          declaracaoMEouEPP: CsvMappers.declaracaoMEouEPP(meStr),
          valorProposta: CsvMappers.parseBrCurrency(lanceStr),
          resultadoHabilitacao: BllMapper.resultadoHabilitacao(
            posicao: posicao,
            classificado: classificadoStr,
          ),
        );

        itensMapa.putIfAbsent(itemNum, () => []).add(licitante);
      } catch (e) {
        throw CsvParseException(
          'Erro ao ler linha de "Classificacao com itens.csv": $e',
        );
      }
    }

    // Monta a lista final ordenada por numeroItem.
    return itensMapa.entries
        .map((e) => LicitacaoItemCsvModel(
              numeroItem: e.key,
              licitantes: e.value,
            ))
        .toList()
      ..sort((a, b) => a.numeroItem.compareTo(b.numeroItem));
  }
}
