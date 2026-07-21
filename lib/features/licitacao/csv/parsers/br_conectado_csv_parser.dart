import '../../../../core/utils/csv_utils.dart';
import '../../../../core/utils/sheet_utils.dart';
import '../mappers/br_conectado_mapper.dart';
import '../mappers/csv_mappers.dart';
import '../models/licitacao_item_csv_model.dart';
import 'portal_csv_parser.dart';

/// Parser para os arquivos CSV exportados pelo portal **BRConectado**.
///
/// Arquivos necessários (informar via [CsvFileKeys]):
/// - [CsvFileKeys.brRelatClassificacao] → `relatclassificacao.csv`
///
/// ### Colunas esperadas
///
/// **relatclassificacao.csv** (separador `;`)
/// ```
/// Lote/Item;Classificação;Razão Social;Valor Uni.;Valor Total;Situação;CNPJ;...
/// ```
/// Os arquivos costumam ser exportados em **Latin-1/ISO-8859-1**; a decodificação
/// é tratada automaticamente por [CsvUtils.decodeBytes].
class BrConectadoCsvParser implements PortalCsvParser {
  const BrConectadoCsvParser();

  @override
  List<LicitacaoItemCsvModel> parse(Map<String, List<int>> csvFiles) {
    final relatBytes = csvFiles[CsvFileKeys.brRelatClassificacao];

    if (relatBytes == null) {
      throw const CsvParseException(
        'Arquivo "relatclassificacao.csv" não fornecido '
        '(chave: "${CsvFileKeys.brRelatClassificacao}").',
      );
    }
    return _parseRelatClassificacao(relatBytes);
  }

  // ---------------------------------------------------------------------------
  // Parseia relatclassificacao.csv e agrega licitantes por item.
  // ---------------------------------------------------------------------------

  List<LicitacaoItemCsvModel> _parseRelatClassificacao(List<int> bytes) {
    final rows = SheetUtils.parseRows(bytes, csvDelimiter: ';');
    if (rows.isEmpty) {
      throw const CsvParseException('"relatclassificacao.csv" está vazio.');
    }

    final header = CsvUtils.buildHeaderIndex(rows.first);
    // Mapa: numeroItem → (situacaoCompraItemId, lista de licitantes)
    final itensMapa = <int, _ItemAccumulator>{};

    for (final row in rows.skip(1)) {
      if (row.length <= 1) continue;
      try {
        final itemStr = CsvUtils.getField(row, header, 'lote/item');

        if (itemStr.trim().isEmpty) {
          continue; // Ignora linhas sem número de item
        }

        final razaoSocial = CsvUtils.getField(row, header, 'razão social');
        final cnpjStr = CsvUtils.getField(row, header, 'cnpj');
        final valorStr = CsvUtils.getField(row, header, 'valor uni.');
        final situacaoStr = CsvUtils.getField(row, header, 'situação');

        final itemNum = BrConectadoMapper.parseNumeroItem(itemStr);
        final cleanCnpj = CsvMappers.cleanNiPessoa(cnpjStr);

        final licitante = LicitanteCsvModel(
          niPessoa: cleanCnpj,
          tipoPessoaId: CsvMappers.tipoPessoaFromCleanNi(cleanCnpj),
          nomeRazaoSocial: razaoSocial,
          declaracaoMEouEPP: 3,
          valorProposta: CsvMappers.parseBrCurrency(valorStr),
          resultadoHabilitacao: BrConectadoMapper.resultadoHabilitacao(
            situacaoStr,
          ),
        );

        final acc = itensMapa.putIfAbsent(itemNum, () => _ItemAccumulator());
        acc.licitantes.add(licitante);
      } catch (e) {
        throw CsvParseException(
          'Erro ao ler linha de "relatclassificacao.csv": $e',
        );
      }
    }

    return itensMapa.entries
        .map(
          (e) => LicitacaoItemCsvModel(
            numeroItem: e.key,
            licitantes: e.value.licitantes,
          ),
        )
        .toList()
      ..sort((a, b) => a.numeroItem.compareTo(b.numeroItem));
  }
}

// ---------------------------------------------------------------------------
// Helpers internos
// ---------------------------------------------------------------------------

class _ItemAccumulator {
  final List<LicitanteCsvModel> licitantes = [];

  _ItemAccumulator();
}
